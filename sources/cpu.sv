`timescale 1ns / 1ps

package registers;
    // Define our data registers.
    typedef enum {
        // General purpose    
        A, B, C, D, E, F, G, H, I, J,                                
        
        // Flags (read-only)
        FL,    
        
        // Interrupts (semi-hidden)
        IE, // Enabled interrupts
        IF, // Firing interrupts
        
        // Stack (hidden)
        S,
        
        // ALU (hidden)
        ALU_OUT,
        ALU_IN_1, ALU_IN_2,                                 
        
        // Control registers (hidden)
        PC, CMD, TMP, TMP2, TMP3,        
        
        // Dummy for when no register is referenced
        NONE
    } register_e;   
endpackage

module cpu(    
    input wire clock_100mhz,
    input wire reset,
    output logic[31:0] pc_out,
    output logic [31:0] reg_out[9:0],
    output logic[31:0] cmd_out,
    output logic [2:0] mem_state_out
    );   
    
    import registers::*;   
        
    wire clock;
    assign clock = clock_100mhz;
    
    register_e register_to_update;
    logic should_update_register;    
    logic [31:0] value_to_write;
    logic [31:0] registers [register_to_update.last():register_to_update.first()];  // Skip none        
    assign pc_out = registers[PC];
    assign reg_out = registers[9:0];
    initial registers[PC] = 32'h50;
    
    // Initialise memory.
    logic [31:0] mem_addr;
    logic [31:0] mem_data_in;
    logic [31:0] mem_data_out;
    logic memory_mode;
    mmu mmu (
        .clock(clock),
        .address_in(mem_addr),
        .mode(memory_mode),
        .data_in(mem_data_in),
        .data_out(mem_data_out)        
    );    
    
    // Initialise ALU.
    logic [31:0] alu_out_wire;
    alu alu (
        .a(registers[ALU_IN_1]),
        .b(registers[ALU_IN_2]),
        .cmd(registers[CMD]),
        .out(alu_out_wire)
    );            
    
    // Set up top-level action state machine.
    typedef enum {
        INIT,
        READ_CMD,
        READ_ALU_ARG_1, READ_ALU_ARG_2, STORE_ALU_RESULT,
        READ_LOAD_ARG, READ_LOAD_DEST, STORE_LOAD_ARG,
        READ_JUMP_DEST, READ_JUMP_ARG_1, READ_JUMP_ARG_2,      
        UPDATE_PC,
        ERROR
    } action_state_e;
    
    action_state_e state;
    initial state = INIT;    
    action_state_e next_state;    
    always @(posedge clock) begin   
        state <= next_state;
    end
    
    // Set up memory access state machine.
    typedef enum {
        QUIESCE,
        READ_MEM_VALUE__SET_MEM_ADDR,
        READ_MEM_VALUE__READ_MEM,
        WRITE_MEM_VALUE,
        RESOLVE_PTR__SET_MEM_ADDR,
        RESOLVE_PTR__READ_MEM
    } memory_task_state_e;
    
    memory_task_state_e memory_state;  
    initial memory_state = QUIESCE;      
    memory_task_state_e next_memory_state;
    always @(posedge clock) begin
        memory_state <= next_memory_state;
    end
    assign mem_state_out = memory_state;
    
    logic [31:0] cmd;    
    // Hack to front-run storing of the command into the CMD register.
    // We save a clock cycle by looking directly at the output of the memory module if we know that it is equal to the
    // command to be stored.
    assign cmd = registers[CMD];            
    assign cmd_out = cmd;
    
    // Force memory into read-only mode except when we're actually writing.    
    assign memory_mode = (memory_state == WRITE_MEM_VALUE); 
    
    // Shared convenience logic.
    // These get updated conditionally further down.
    register_e source_register_from_cmd;
    register_e target_register_from_cmd;
    
    // Convenience logic for ALU operations.
    logic is_alu_op;
    logic alu_arg_1_needs_literal;
    logic alu_arg_2_needs_literal;
    logic alu_arg_needs_literal;
    logic alu_dest_needs_literal;
    logic alu_arg_1_is_pointer;
    logic alu_arg_2_is_pointer;
    logic alu_dest_is_pointer;
    logic alu_arg_is_pointer;
    logic alu_op_is_binary;
    assign is_alu_op = (cmd[31:20] == 0);    
    assign alu_arg_1_needs_literal = (cmd[18:15] == 4'hf);
    assign alu_arg_2_needs_literal = (cmd[13:10] == 4'hf);    
    assign alu_dest_needs_literal = (cmd[8:5] == 4'hf);
    assign alu_arg_needs_literal = (state == READ_ALU_ARG_1 && alu_arg_1_needs_literal) || (state == READ_ALU_ARG_2 && alu_arg_2_needs_literal);
    assign alu_arg_1_is_pointer = cmd[19];
    assign alu_arg_2_is_pointer = cmd[14];
    assign alu_dest_is_pointer = cmd[9];    
    assign alu_arg_is_pointer = (state == READ_ALU_ARG_1 && alu_arg_1_is_pointer) || (state == READ_ALU_ARG_2 && alu_arg_2_is_pointer);
    assign alu_op_is_binary = ~(cmd[4:0] == 5'hb || cmd[4:0] == 5'h16);
    
    // Convenience logic for LOAD operations.
    logic is_load_op;
    logic load_arg_needs_literal;
    logic load_arg_is_pointer;
    logic load_dest_needs_literal;
    logic load_dest_is_pointer;
    logic [31:0] load_arg;
    logic [3:0] load_mask_bits;
    logic [31:0] load_mask;
    logic [2:0] load_shift;
    logic [31:0] load_arg_adjusted;
    logic [31:0] load_mask_shifted;
    logic load_preserves_dest_bits;
    logic [31:0] load_dest_old_value;
    logic [31:0] load_final_value;
    assign is_load_op = (cmd[31:18] == 14'b00010000000000);    
    assign load_arg_needs_literal = (cmd[8:5] == 4'hf);
    assign load_arg_is_pointer = cmd[9];
    assign load_dest_needs_literal = (cmd[3:0] == 4'hf);
    assign load_dest_is_pointer = cmd[4];
    assign load_arg = (load_arg_needs_literal || load_arg_is_pointer) ? 
            (state == READ_LOAD_ARG ? mem_data_out : registers[TMP])  // Hack to front-run register storage. 
            : registers[source_register_from_cmd];
    assign load_mask_bits = cmd[17:14];
    assign load_mask = { {8{load_mask_bits[3]}}, {8{load_mask_bits[2]}}, {8{load_mask_bits[1]}}, {8{load_mask_bits[0]}} };
    assign load_shift = cmd[13:11];
    assign load_arg_adjusted = (load_arg & load_mask) << (8 * $signed(load_shift));
    assign load_mask_shifted = load_mask << (8 * $signed(load_shift));
    assign load_preserves_dest_bits = cmd[10];
    assign load_dest_old_value = (load_dest_is_pointer) ? registers[TMP3] : registers[target_register_from_cmd];
    assign load_final_value = load_preserves_dest_bits 
        ? ((load_arg_adjusted) | ((~load_mask_shifted) & load_dest_old_value))
        : load_arg_adjusted;
        
    // Set up jump controller.
    register_e jump_dest_origin_register;
    register_e jump_arg_1_origin_register; 
    register_e jump_arg_2_origin_register;
    register_e jump_dest_storage_register;  
    register_e jump_arg_1_storage_register; 
    register_e jump_arg_2_storage_register;     
    logic should_jump;              
    logic [31:0] jump_dest;
    logic [31:0] jump_arg_1;        
    logic [31:0] jump_arg_2;        
    assign jump_arg_1 = registers[jump_arg_1_storage_register];
    assign jump_arg_2 = registers[jump_arg_2_storage_register];
    assign jump_dest = registers[jump_dest_storage_register];
    jump_controller jump_controller (
        .cmd(cmd),
        .jump_arg_1(jump_arg_1),
        .jump_arg_2(jump_arg_2),
        .jump_dest_origin_register(jump_dest_origin_register),
        .jump_arg_1_origin_register(jump_arg_1_origin_register),
        .jump_arg_2_origin_register(jump_arg_2_origin_register),
        .jump_dest_storage_register(jump_dest_storage_register),
        .jump_arg_1_storage_register(jump_arg_1_storage_register),
        .jump_arg_2_storage_register(jump_arg_2_storage_register),
        .should_jump(should_jump)
    );
        
    // Convenience logic for JUMP operations.
    logic is_jump_op;
    logic [2:0] jump_type_sig;
    logic [1:0] jump_num_args;
    logic jump_dest_needs_literal;
    logic jump_dest_is_pointer;
    logic jump_arg_1_needs_literal;
    logic jump_arg_1_is_pointer;
    logic jump_arg_2_needs_literal;
    logic jump_arg_2_is_pointer;
    logic jump_current_arg_needs_literal;
    logic jump_current_arg_is_pointer;            
    assign is_jump_op = (cmd[31:22] == 10'b0010000000);
    assign jump_type_sig = cmd[21:19];
    always_comb begin
        jump_dest_needs_literal = cmd[17:14] == 4'hf;
        jump_dest_is_pointer = cmd[18];
        jump_current_arg_needs_literal = 0;
        jump_current_arg_is_pointer = 0;
       
        if (jump_type_sig == 3'b000) begin
            jump_num_args = 1;            
            jump_arg_1_needs_literal = 0;
            jump_arg_1_is_pointer = 0;
            jump_arg_2_needs_literal = 0;
            jump_arg_2_is_pointer = 0;
        end else if (jump_type_sig == 3'b001) begin
            jump_num_args = 3;            
            jump_arg_1_needs_literal = cmd[10:7] == 4'hf;
            jump_arg_1_is_pointer = cmd[11];
            jump_arg_2_needs_literal = cmd[5:2] == 4'hf;
            jump_arg_2_is_pointer = cmd[6];
        end else if (jump_type_sig == 3'b010) begin
            jump_num_args = 3;
            jump_arg_1_needs_literal = cmd[12:9] == 4'hf;
            jump_arg_1_is_pointer = cmd[13];
            jump_arg_2_needs_literal = cmd[7:4] == 4'hf;
            jump_arg_2_is_pointer = cmd[8];
        end else if (jump_type_sig == 3'b011) begin
            jump_num_args = 2;
            jump_arg_1_needs_literal = cmd[6:3] == 4'hf;
            jump_arg_1_is_pointer = cmd[7];
            jump_arg_2_needs_literal = 0;
            jump_arg_2_is_pointer = 0;
        end else if (jump_type_sig == 3'b100) begin
            jump_num_args = 2;
            jump_arg_1_needs_literal = cmd[9:6] == 4'hf;
            jump_arg_1_is_pointer = cmd[10];
            jump_arg_2_needs_literal = 0;
            jump_arg_2_is_pointer = 0;
        end            
        if (state == READ_JUMP_DEST) begin
            jump_current_arg_needs_literal = jump_dest_needs_literal;
            jump_current_arg_is_pointer = jump_dest_is_pointer;
        end else if (state == READ_JUMP_ARG_1) begin
            jump_current_arg_needs_literal = jump_arg_1_needs_literal;
            jump_current_arg_is_pointer = jump_arg_1_is_pointer;
        end else if (state == READ_JUMP_ARG_1) begin
            jump_current_arg_needs_literal = jump_arg_2_needs_literal;
            jump_current_arg_is_pointer = jump_arg_2_is_pointer;
        end                        
    end      
            
    // Define state transitions.
    always_comb begin 
        if (state == INIT) begin
            next_state = READ_CMD;
            next_memory_state = READ_MEM_VALUE__SET_MEM_ADDR;            
        end else if (state == READ_CMD) begin
            if (memory_state == READ_MEM_VALUE__SET_MEM_ADDR) begin
                next_state = READ_CMD;
                next_memory_state = READ_MEM_VALUE__READ_MEM;
            end else if (memory_state == READ_MEM_VALUE__READ_MEM) begin
                // We need a cycle for the memory output to propagate to the CMD register.           
                next_state = READ_CMD;
                next_memory_state = QUIESCE;
            end else if (memory_state == QUIESCE) begin     
                if (is_alu_op) begin
                    next_state = READ_ALU_ARG_1;
                    if (alu_arg_1_needs_literal) next_memory_state = READ_MEM_VALUE__SET_MEM_ADDR;
                    else if (alu_arg_1_is_pointer) next_memory_state = RESOLVE_PTR__SET_MEM_ADDR;
                    else next_memory_state = QUIESCE;
                end else if (is_load_op) begin
                    if (load_arg_needs_literal) begin
                        next_state = READ_LOAD_ARG;
                        next_memory_state = READ_MEM_VALUE__SET_MEM_ADDR;
                    end else if (load_arg_is_pointer) begin
                        next_state = READ_LOAD_ARG;
                        next_memory_state = RESOLVE_PTR__SET_MEM_ADDR;
                    end else if (load_dest_needs_literal) begin
                        next_state = load_preserves_dest_bits ? READ_LOAD_DEST : STORE_LOAD_ARG;
                        next_memory_state = READ_MEM_VALUE__SET_MEM_ADDR;
                    end else if (load_dest_is_pointer && load_preserves_dest_bits) begin
                        next_state = READ_LOAD_DEST;
                        next_memory_state = RESOLVE_PTR__SET_MEM_ADDR;
                    end else if (load_dest_is_pointer) begin
                        next_state = STORE_LOAD_ARG;
                        next_memory_state = WRITE_MEM_VALUE;
                    end else begin
                        next_state = STORE_LOAD_ARG;
                        next_memory_state = QUIESCE;
                    end 
                end else if (is_jump_op) begin
                    if (jump_dest_needs_literal) begin
                        next_state = READ_JUMP_DEST;
                        next_memory_state = READ_MEM_VALUE__SET_MEM_ADDR;
                    end else if (jump_dest_is_pointer) begin
                        next_state = READ_JUMP_DEST;
                        next_memory_state = RESOLVE_PTR__SET_MEM_ADDR;
                    end else if (jump_arg_1_needs_literal) begin
                        next_state = READ_JUMP_ARG_1;
                        next_memory_state = READ_MEM_VALUE__SET_MEM_ADDR;                        
                    end else if (jump_arg_1_is_pointer) begin
                        next_state = READ_JUMP_ARG_1;
                        next_memory_state = RESOLVE_PTR__SET_MEM_ADDR;
                    end else if (jump_arg_2_needs_literal) begin
                        next_state = READ_JUMP_ARG_2;
                        next_memory_state = READ_MEM_VALUE__SET_MEM_ADDR;                        
                    end else if (jump_arg_2_is_pointer) begin
                        next_state = READ_JUMP_ARG_2;
                        next_memory_state = RESOLVE_PTR__SET_MEM_ADDR;
                    end else begin
                        next_state = UPDATE_PC;
                        next_memory_state = QUIESCE;
                    end
                end else begin
                    next_state = ERROR;
                    next_memory_state = QUIESCE;
                end
            end  
            
        end else if (state == READ_ALU_ARG_1 || state == READ_ALU_ARG_2) begin
            // Figure out if we're on our last step of this state, so we can handle the transition to the next state all in one 'if' case.
            // We're on the last step if:
            // - We're reading a direct value from a register (this is a one step process).
            // - We're resolving a pointer and are ready to read it out of memory.
            // - We're resolving a literal and are ready to read it out of memory.
            logic is_final_step;
            is_final_step = (
                (!alu_arg_is_pointer && !alu_arg_needs_literal) ||
                (alu_arg_is_pointer && memory_state == RESOLVE_PTR__READ_MEM) ||
                (!alu_arg_is_pointer && memory_state == READ_MEM_VALUE__READ_MEM)
            );
            
            if (is_final_step) begin                
                // Transition to the next state depends on whether we're invoking a one-arg or a two-arg operation.
                if (state == READ_ALU_ARG_1 && alu_op_is_binary) begin
                    // We've read one argument, and now need to read the other.
                    next_state = READ_ALU_ARG_2;
                    if (alu_arg_2_needs_literal) next_memory_state = READ_MEM_VALUE__SET_MEM_ADDR;
                    else if (alu_arg_2_is_pointer) next_memory_state = RESOLVE_PTR__SET_MEM_ADDR;
                    else next_memory_state = QUIESCE;     
                end else begin    
                    // We've read all our arguments and now need to store the result.                
                    next_state = STORE_ALU_RESULT;
                    if (alu_dest_needs_literal) next_memory_state = READ_MEM_VALUE__SET_MEM_ADDR;
                    else if (alu_dest_is_pointer) next_memory_state = WRITE_MEM_VALUE;
                    else next_memory_state = QUIESCE;
                end
            end else if (memory_state == READ_MEM_VALUE__SET_MEM_ADDR) begin
                next_state = state;
                next_memory_state = READ_MEM_VALUE__READ_MEM;
            end else if (memory_state == READ_MEM_VALUE__READ_MEM) begin
                if (alu_arg_is_pointer) begin
                    next_state = state;
                    next_memory_state = RESOLVE_PTR__SET_MEM_ADDR;
                end else begin
                    // Final step - covered above.
                end
            end else if (memory_state == RESOLVE_PTR__SET_MEM_ADDR) begin
                next_state = state;
                next_memory_state = RESOLVE_PTR__READ_MEM;
            end else begin 
                // Final step - covered above.
            end                        
        end else if (state == STORE_ALU_RESULT) begin
            if (memory_state == QUIESCE) begin
                // If we're in this state, it's because the destination is direct to a register.
                // Updating the register can be done in one cycle, so we're done storing the ALU result.
                next_state = UPDATE_PC;
                next_memory_state = QUIESCE;            
            end else if (memory_state == READ_MEM_VALUE__SET_MEM_ADDR) begin
                // The destination is stored in the following DWORD.
                // We have addressed it in memory and now need to read it.                
                next_state = STORE_ALU_RESULT;
                next_memory_state = READ_MEM_VALUE__READ_MEM;
            end else if (memory_state == READ_MEM_VALUE__READ_MEM) begin
                // We just read the destination out of a DWORD literal.
                if (alu_dest_is_pointer) begin
                    // However, it's a pointer, so we need to write to memory.
                    next_state = STORE_ALU_RESULT;
                    next_memory_state = WRITE_MEM_VALUE;
                end else begin
                    // It's not a pointer, but you can't write to a literal, so this
                    // is an error state.
                    next_state = ERROR;
                    next_memory_state = QUIESCE;
                end
            end else if (memory_state == WRITE_MEM_VALUE) begin
                // We just wrote the result to memory and are done.
                next_state = UPDATE_PC;
                next_memory_state = QUIESCE;
            end else begin
                // We should have covered all cases. Fail if you get here.
                next_state = ERROR;
                next_memory_state = QUIESCE;
            end
            
        end else if (state == READ_LOAD_ARG) begin
            // There are a few different states we might transition to afterreading the arg.            
            // To avoid duplicating the logic we factor this out.
            action_state_e first_state_after_load_arg;
            memory_task_state_e first_memory_state_after_load_arg;                        
            if (load_dest_needs_literal) begin
                // We need to read a pointer address out of memory.
                // If we want to preserve some destination bits, we will also need to read the pointer value after.
                first_state_after_load_arg = load_preserves_dest_bits ? READ_LOAD_DEST : STORE_LOAD_ARG;
                first_memory_state_after_load_arg = READ_MEM_VALUE__SET_MEM_ADDR;
            end else if (load_dest_is_pointer && load_preserves_dest_bits) begin
                // The destination is pointed to by a register.
                // However, we want to preserve some destination bits, so we have to actually read the pointer.
                first_state_after_load_arg = READ_LOAD_DEST;
                first_memory_state_after_load_arg = RESOLVE_PTR__SET_MEM_ADDR;
            end else if (load_dest_is_pointer) begin
                // The destination is pointed to by a register.
                // We don't want to preserve any destination bits, so we can simply write to that address without reading.
                first_state_after_load_arg = STORE_LOAD_ARG;
                first_memory_state_after_load_arg = WRITE_MEM_VALUE;
            end else begin
                // We're writing to a register; this can be done with no further memory access.
                first_state_after_load_arg = STORE_LOAD_ARG;
                first_memory_state_after_load_arg = QUIESCE;
            end
            
            if (memory_state == QUIESCE) begin
                // This state is invalid - we should only ever enter READ_LOAD_ARG if memory access is needed.
                // Otherwise we expect to jump straight to STORE_LOAD_ARG.
                next_state = ERROR;
                next_memory_state = QUIESCE;
            end else if (memory_state == READ_MEM_VALUE__SET_MEM_ADDR) begin
                // The value to be loaded is stored in the following word.
                // We have addressed it in memory and now need to read it.
                next_state = READ_LOAD_ARG;
                next_memory_state = READ_MEM_VALUE__READ_MEM;
            end else if (memory_state == READ_MEM_VALUE__READ_MEM) begin
                if (load_arg_is_pointer) begin
                    next_state = READ_LOAD_ARG;
                    next_memory_state = RESOLVE_PTR__SET_MEM_ADDR;
                end else begin
                    next_state = first_state_after_load_arg;
                    next_memory_state = first_memory_state_after_load_arg;
                end
            end else if (memory_state == RESOLVE_PTR__SET_MEM_ADDR) begin
                // We've just set the memory address to the pointer we loaded.
                // Next we need to actually read the pointed value.
                next_state = READ_LOAD_ARG;
                next_memory_state = RESOLVE_PTR__READ_MEM;
            end else if (memory_state == RESOLVE_PTR__READ_MEM) begin
                // We just read the load arg out of memory; now we need to store it.
                next_state = first_state_after_load_arg;
                next_memory_state = first_memory_state_after_load_arg;
            end else begin
                next_state = ERROR;
                next_memory_state = QUIESCE;
            end
            
        end else if (state == READ_LOAD_DEST) begin
            // We want to preserve some of the destination's bits, so we have to 
            // read it first in order to mask it. We only land here if the destination
            // is in memory, since otherwise reading it wouldn't take an extra cycle.
            if (memory_state == READ_MEM_VALUE__SET_MEM_ADDR) begin
                // Our destination pointer is a literal word following our instruction.
                // We've set its address, next we need to read it.
                next_state = READ_LOAD_DEST;
                next_memory_state = READ_MEM_VALUE__READ_MEM;
            end else if (memory_state == READ_MEM_VALUE__READ_MEM) begin
                // We just read a destination pointer from memory.
                // Now we need to resolve it.
                next_state = READ_LOAD_DEST;
                next_memory_state = RESOLVE_PTR__SET_MEM_ADDR;
            end else if (memory_state == RESOLVE_PTR__SET_MEM_ADDR) begin
                // We just pointed memory at the destination address. Now we need to read its value.
                next_state = READ_LOAD_DEST;
                next_memory_state = RESOLVE_PTR__READ_MEM;
            end else if (memory_state == RESOLVE_PTR__READ_MEM) begin
                // We just read the value of the destination from memory. On to the next state.
                next_state = STORE_LOAD_ARG;
                next_memory_state = load_dest_is_pointer ? WRITE_MEM_VALUE : QUIESCE;
            end 
            
        end else if (state == STORE_LOAD_ARG) begin
            if (memory_state == QUIESCE) begin
                // This state implies no memory access is needed for the store - because it's located in a register.
                // Thus after this cycle the load will be complete.
                next_state = UPDATE_PC;
                next_memory_state = QUIESCE; 
            end else if (memory_state == READ_MEM_VALUE__SET_MEM_ADDR) begin
                // We need to resolve a pointer literal to store the data, and we just set the
                // address of the pointer. Next we need to read the pointer value, so we know where
                // to write to.
                next_state = STORE_LOAD_ARG;
                next_memory_state = READ_MEM_VALUE__READ_MEM; 
            end else if (memory_state == READ_MEM_VALUE__READ_MEM) begin
                // We just read the destination address out of memory. Now we need to write to it.
                next_state = STORE_LOAD_ARG;
                next_memory_state = WRITE_MEM_VALUE;
            end else if (memory_state == WRITE_MEM_VALUE) begin
                // We just wrote to memory to complete our store. We're done with the load.
                next_state = UPDATE_PC;
                next_memory_state = QUIESCE;
            end else begin
                next_state = ERROR;
                next_memory_state = QUIESCE;
            end                   
            
        end else if (state == READ_JUMP_DEST || state == READ_JUMP_ARG_1 || state == READ_JUMP_ARG_2) begin            
            action_state_e first_state_after_this_arg;
            memory_task_state_e first_memory_state_after_this_arg;   
                        
            if (state == READ_JUMP_DEST && jump_arg_1_needs_literal) begin
                first_state_after_this_arg = READ_JUMP_ARG_1;
                first_memory_state_after_this_arg = READ_MEM_VALUE__SET_MEM_ADDR;
            end else if (state == READ_JUMP_DEST && jump_arg_1_is_pointer) begin
                first_state_after_this_arg = READ_JUMP_ARG_1;
                first_memory_state_after_this_arg = RESOLVE_PTR__SET_MEM_ADDR;
            end else if ((state == READ_JUMP_DEST || state == READ_JUMP_ARG_1) && jump_arg_2_needs_literal) begin
                first_state_after_this_arg = READ_JUMP_ARG_2;
                first_memory_state_after_this_arg = READ_MEM_VALUE__SET_MEM_ADDR;
            end else if ((state == READ_JUMP_DEST || state == READ_JUMP_ARG_1) && jump_arg_2_is_pointer) begin
                first_state_after_this_arg = READ_JUMP_ARG_2;
                first_memory_state_after_this_arg = RESOLVE_PTR__SET_MEM_ADDR;
            end else begin
                first_state_after_this_arg = UPDATE_PC;
                first_memory_state_after_this_arg = QUIESCE;
            end            
            
            next_state = state;            
            if (memory_state == QUIESCE) begin
                next_state = ERROR;
                next_memory_state = QUIESCE;
            end else if (memory_state == READ_MEM_VALUE__SET_MEM_ADDR) begin
                next_memory_state = READ_MEM_VALUE__READ_MEM;
            end else if (memory_state == READ_MEM_VALUE__READ_MEM) begin
                if (jump_current_arg_is_pointer) begin
                    next_memory_state = RESOLVE_PTR__SET_MEM_ADDR;
                end else begin
                    next_state = first_state_after_this_arg;
                    next_memory_state = first_memory_state_after_this_arg;
                end
            end else if (memory_state == RESOLVE_PTR__SET_MEM_ADDR) begin
                next_memory_state = RESOLVE_PTR__READ_MEM;
            end else if (memory_state == RESOLVE_PTR__READ_MEM) begin
                next_state = first_state_after_this_arg;
                next_memory_state = first_memory_state_after_this_arg;
            end else begin
                next_state = ERROR;
                next_memory_state = QUIESCE;
            end                                
            
        end else if (state == UPDATE_PC) begin
            // We've updated the PC; time to go round again :)
            next_state = READ_CMD;
            next_memory_state = READ_MEM_VALUE__SET_MEM_ADDR;
        
        end else begin
            // Unknown state.
            next_state = ERROR;
            next_memory_state = QUIESCE;
        end
        
        if (reset) begin
            next_state = INIT;
            next_memory_state = QUIESCE;
        end
    end
    
    // Helper value for calculating literal DWORD memory offsets from PC.
    logic [3:0] increment;
        
    // Orchestrate register/memory updates.
    register_e current_alu_input;
    register_e current_jump_arg_origin_register;
    register_e current_jump_arg_storage_register;
    always_comb begin
        // Default values to avoid implying a latch.
        should_update_register = 0;
        register_to_update = NONE;
        source_register_from_cmd = NONE;
        target_register_from_cmd = NONE;
        current_alu_input = NONE;
        current_jump_arg_origin_register = NONE;
        current_jump_arg_storage_register = NONE;
        value_to_write = 0;
        mem_addr = 'h0;
        mem_data_in = 'h0;           
        increment = 0;     
                            
        if (state == READ_CMD) begin
            if (memory_state == READ_MEM_VALUE__SET_MEM_ADDR) begin                
                mem_addr = registers[PC];                
            end else if (memory_state == READ_MEM_VALUE__READ_MEM) begin
                should_update_register = 1;
                register_to_update = CMD;
                value_to_write = mem_data_out;
            end
            
        end else if (state == READ_ALU_ARG_1 || state == READ_ALU_ARG_2) begin
            if (state == READ_ALU_ARG_1) begin
                source_register_from_cmd = register_e'(cmd[18:15]);
                current_alu_input = ALU_IN_1;
            end else begin
                source_register_from_cmd = register_e'(cmd[13:10]);
                current_alu_input = ALU_IN_2;
            end
            
            if (memory_state == QUIESCE) begin
                // Implies we're loading direct from a register.
                should_update_register = 1;
                register_to_update = current_alu_input;
                value_to_write = registers[source_register_from_cmd];
            end else if (memory_state == READ_MEM_VALUE__SET_MEM_ADDR) begin
                // Implies we're loading from the following DWORD (and first need to address it).                
                increment = (state == READ_ALU_ARG_1) ? 'b1 : ('b1 + alu_arg_1_needs_literal);
                mem_addr = registers[PC] + increment;                
                value_to_write = registers[PC] + increment; 
            end else if (memory_state == READ_MEM_VALUE__READ_MEM) begin
                // We're reading the arg from memory.
                should_update_register = 1;
                register_to_update = current_alu_input;
                value_to_write = mem_data_out;
            end else if (memory_state == RESOLVE_PTR__SET_MEM_ADDR) begin
                // We've been given a pointer to the argument.
                // Depending on how we got here, the pointer might be in ALU_IN_x or in a register.                
                if (alu_arg_needs_literal) begin
                    // We got here through loading a DWORD from memory.
                    // We put it into ALU_IN_x for safekeeping - now use it to resolve the actual operand.
                    mem_addr = registers[current_alu_input];
                end else begin
                    // The pointer is stored in a register.
                    mem_addr = registers[source_register_from_cmd];
                end
            end else if (memory_state == RESOLVE_PTR__READ_MEM) begin
                // We just resolved a pointer to the operand. Copy the operand to the ALU.
                should_update_register = 1;
                register_to_update = current_alu_input;
                value_to_write = mem_data_out;
            end
        
        end else if (state == STORE_ALU_RESULT) begin
            target_register_from_cmd = register_e'(cmd[8:5]);
            if (memory_state == QUIESCE) begin
                // Implies we're storing directly to a register.
                should_update_register = 1;
                register_to_update = target_register_from_cmd;
                value_to_write = alu_out_wire;
            end else if (memory_state == READ_MEM_VALUE__SET_MEM_ADDR) begin
                // Implies we're storing to a location pointed at by a following word.
                // We need to set the address register to load the word.                                ;                
                increment = alu_arg_1_needs_literal + alu_arg_2_needs_literal + 1;
                mem_addr = registers[PC] + increment;
            end else if (memory_state == READ_MEM_VALUE__READ_MEM) begin
                // TODO - optimise this and other similar cases. We could write directly to MEM_ADDR
                // and save a cycle.
                should_update_register = 1;
                register_to_update = TMP;
                value_to_write = mem_data_out;
            end else if (memory_state == WRITE_MEM_VALUE) begin                             
                mem_addr = alu_dest_needs_literal ? registers[TMP] : registers[target_register_from_cmd];
                mem_data_in = alu_out_wire;                                                            
            end
            
        end else if (state == READ_LOAD_ARG) begin
            source_register_from_cmd = register_e'(cmd[8:5]);            
            target_register_from_cmd = register_e'(cmd[3:0]);
            if (memory_state == READ_MEM_VALUE__SET_MEM_ADDR) begin
                // We need to read a value out of a following word.
                mem_addr = registers[PC] + 1;
            end else if (memory_state == READ_MEM_VALUE__READ_MEM) begin
                should_update_register = 1;
                register_to_update = TMP;
                value_to_write = mem_data_out;
            end else if (memory_state == RESOLVE_PTR__SET_MEM_ADDR) begin
                // We have a pointer to the actual load arg. 
                // Pass the pointer to mem_addr so we can load the actual arg.
                mem_addr = registers[load_arg_needs_literal ? TMP : source_register_from_cmd];
            end else if (memory_state == RESOLVE_PTR__READ_MEM) begin
                should_update_register = 1;
                register_to_update = TMP;
                value_to_write = mem_data_out;
            end
            
        end else if (state == READ_LOAD_DEST) begin
            // If we're in this state, we want to read the destination value so we
            // can keep some of its bits; and further, we know that the destination is in memory.
            source_register_from_cmd = register_e'(cmd[8:5]);    
            target_register_from_cmd = register_e'(cmd[3:0]);
            if (memory_state == READ_MEM_VALUE__SET_MEM_ADDR) begin   
                // The destination value is behind a pointer, whose address
                // is given as a literal in memory. First set the address where
                // we can find that literal.
                increment = load_arg_needs_literal ? 2 : 1;
                mem_addr = registers[PC] + increment;
            end else if (memory_state == READ_MEM_VALUE__READ_MEM) begin
                // The destination value is given by the pointer currently expressed
                // at mem_data_out. Save it off to TMP2 - we'll use it later.
                should_update_register = 1;
                register_to_update = TMP2;
                value_to_write = mem_data_out;
            end else if (memory_state == RESOLVE_PTR__SET_MEM_ADDR) begin
                // The destination value is located at a pointer.
                if (load_dest_needs_literal) begin
                    // ...and the pointer address was previously saved to TMP2.
                    mem_addr = registers[TMP2];
                end else begin
                    // ...and the pointer is held in a register.
                    mem_addr = registers[target_register_from_cmd];
                end
            end else if (memory_state == RESOLVE_PTR__READ_MEM) begin
                // We now know the destination value. Store it in TMP3.
                should_update_register = 1;
                register_to_update = TMP3;
                value_to_write = mem_data_out;
            end
            
        end else if (state == STORE_LOAD_ARG) begin
            source_register_from_cmd = register_e'(cmd[8:5]);    
            target_register_from_cmd = register_e'(cmd[3:0]);
            if (memory_state == QUIESCE) begin
                // The destination value is in a register.
                should_update_register = 1;
                register_to_update = target_register_from_cmd;
                value_to_write = load_final_value;
            end else if (memory_state == READ_MEM_VALUE__SET_MEM_ADDR) begin
                // The destination value is behind a pointer, whose address
                // is given as a literal in memory. First set the address where
                // we can find that literal.
                increment = load_arg_needs_literal ? 2 : 1;
                mem_addr = registers[PC] + increment;
            end else if (memory_state == READ_MEM_VALUE__READ_MEM) begin
                // The destination value is given by the pointer currently expressed
                // at mem_data_out. Save it off to TMP2 - we'll use it later.
                should_update_register = 1;
                register_to_update = TMP2;
                value_to_write = mem_data_out;
            end else if (memory_state == WRITE_MEM_VALUE) begin
                mem_addr = load_dest_needs_literal ? registers[TMP2] : registers[target_register_from_cmd];
                mem_data_in = load_final_value;
            end
            
        end else if (state == READ_JUMP_DEST || state == READ_JUMP_ARG_1 || state == READ_JUMP_ARG_2) begin
            current_jump_arg_origin_register = (state == READ_JUMP_DEST) 
                ? jump_dest_origin_register 
                : (state == READ_JUMP_ARG_1) ? jump_arg_1_origin_register : jump_arg_2_origin_register;
            current_jump_arg_storage_register = (state == READ_JUMP_DEST) 
                ? jump_dest_storage_register 
                : (state == READ_JUMP_ARG_1) ? jump_arg_1_storage_register : jump_arg_2_storage_register;
            if (memory_state == READ_MEM_VALUE__SET_MEM_ADDR) begin
                increment = (
                    (state > READ_JUMP_DEST && jump_dest_needs_literal ? 1 : 0) +
                    (state > READ_JUMP_ARG_1 && jump_arg_1_needs_literal ? 1 : 0) +
                    1
                );
                mem_addr = registers[PC] + increment;
            end else if (memory_state == READ_MEM_VALUE__READ_MEM) begin
                should_update_register = 1;
                register_to_update = current_jump_arg_storage_register;
                value_to_write = mem_data_out;
            end else if (memory_state == RESOLVE_PTR__SET_MEM_ADDR) begin
                mem_addr = jump_current_arg_needs_literal ? 
                    registers[current_jump_arg_storage_register] 
                    : registers[current_jump_arg_origin_register];
            end else if (memory_state == RESOLVE_PTR__READ_MEM) begin
                should_update_register = 1;
                register_to_update = current_jump_arg_storage_register;
                value_to_write = mem_data_out;
            end
        
        end else if (state == UPDATE_PC) begin
            should_update_register = 1;
            register_to_update = PC;
            
            if (should_jump) begin
                value_to_write = jump_dest;
            end else begin                     
                if (is_alu_op) begin
                    increment = alu_arg_1_needs_literal + alu_arg_2_needs_literal + alu_dest_needs_literal + 1;
                end else if (is_load_op) begin
                    increment = load_arg_needs_literal + load_dest_needs_literal + 1;
                end else if (is_jump_op) begin
                    increment = jump_dest_needs_literal + jump_arg_1_needs_literal + jump_arg_2_needs_literal + 1;
                end else begin
                    increment = 1;
                end
                
                value_to_write = registers[PC] + increment;
            end
        end            
        
        if (reset) begin
            should_update_register = 0;
            register_to_update = A;
            value_to_write = 0;
        end                      
    end
    
    // Finally, the sequential logic for updating registers.
    always @(posedge clock) begin
        if (reset) begin
            int i;
            for (i = 0; i < register_to_update.num(); i = i + 1) begin                
                registers[register_e'(i)] <= (i == PC) ? 32'h50 : 32'h0;
            end            
        end else if (should_update_register) begin
            registers[register_to_update] <= value_to_write;
            registers[ALU_OUT] = alu_out_wire;
        end
    end
                  
endmodule
