`timescale 1ns / 1ps

import registers::*;

// Given a command word, determines whether a jump should trigger
// and if so where to jump to. 
module jump_controller(
    input logic [31:0] cmd,    
    input logic [31:0] jump_arg_1,
    input logic [31:0] jump_arg_2,
    output register_e jump_dest_origin_register,
    output register_e jump_arg_1_origin_register,
    output register_e jump_arg_2_origin_register,
    output register_e jump_dest_storage_register,
    output register_e jump_arg_1_storage_register,
    output register_e jump_arg_2_storage_register,        
    output logic should_jump
    );        
    
    // Set up the variables that can be known purely from the command word.
    logic is_jump_op;
    logic [2:0] jump_type_sig;         
    assign is_jump_op = (cmd[31:22] == 10'b0010000000);
    assign jump_type_sig = cmd[21:19];
    always_comb begin
        jump_dest_origin_register = register_e'(cmd[17:14]);
        jump_dest_storage_register = (cmd[18] || jump_dest_origin_register == 4'hf) ? TMP : jump_dest_origin_register;                
       
        if (jump_type_sig == 3'b000) begin            
            jump_arg_1_origin_register = NONE;
            jump_arg_2_origin_register = NONE;
            jump_arg_1_storage_register = NONE;
            jump_arg_2_storage_register = NONE;
        end else if (jump_type_sig == 3'b001) begin            
            jump_arg_1_origin_register = register_e'(cmd[10:7]);
            jump_arg_2_origin_register = register_e'(cmd[5:2]);
            jump_arg_1_storage_register = (cmd[11] || jump_arg_1_origin_register == 4'hf) ? TMP2 : jump_arg_1_origin_register;
            jump_arg_2_storage_register = (cmd[6] || jump_arg_2_origin_register == 4'hf) ? TMP3 : jump_arg_2_origin_register;            
        end else if (jump_type_sig == 3'b010) begin
            jump_arg_1_origin_register = register_e'(cmd[12:9]);
            jump_arg_2_origin_register = register_e'(cmd[7:4]);
            jump_arg_1_storage_register = (cmd[13] || jump_arg_1_origin_register == 4'hf) ? TMP2 : jump_arg_1_origin_register;
            jump_arg_2_storage_register = (cmd[8] || jump_arg_2_origin_register == 4'hf) ? TMP3 : jump_arg_2_origin_register;            
        end else if (jump_type_sig == 3'b011) begin
            jump_arg_1_origin_register = register_e'(cmd[6:3]);
            jump_arg_2_origin_register = NONE;
            jump_arg_1_storage_register = (cmd[7] || jump_arg_1_origin_register == 4'hf) ? TMP2 : jump_arg_1_origin_register;
            jump_arg_2_storage_register = NONE;            
        end else if (jump_type_sig == 3'b100) begin
            jump_arg_1_origin_register = register_e'(cmd[9:6]);
            jump_arg_2_origin_register = NONE;
            jump_arg_1_storage_register = (cmd[10] || jump_arg_1_origin_register == 4'hf) ? TMP2 : jump_arg_1_origin_register;
            jump_arg_2_storage_register = NONE;            
        end                                
    end
    
    // Now actually calculate whether we should jump.
    always_comb begin
        if (is_jump_op) begin
            if (jump_type_sig == 3'b000) begin
                should_jump = 1;
            end else if (jump_type_sig == 3'b001) begin
                logic [31:0] mask, target, combined_value, matching_bits;
                mask = jump_arg_2;
                target = {32{cmd[0]}};
                combined_value = (~mask & target) | (mask & jump_arg_1);
                matching_bits = ~(combined_value ^ target);
                should_jump = cmd[1] ? |matching_bits : &matching_bits;                        
            end else if (jump_type_sig == 3'b010) begin                        
                logic lt_match, eq_match, gt_match;
                if (cmd[0]) begin
                    lt_match = cmd[3] && (signed'(jump_arg_1) < signed'(jump_arg_2));
                    eq_match = cmd[2] && (signed'(jump_arg_1) == signed'(jump_arg_2));
                    gt_match = cmd[1] && (signed'(jump_arg_1) > signed'(jump_arg_2));
                end else begin
                    lt_match = cmd[3] && (unsigned'(jump_arg_1) < unsigned'(jump_arg_2));
                    eq_match = cmd[2] && (unsigned'(jump_arg_1) == unsigned'(jump_arg_2));
                    gt_match = cmd[1] && (unsigned'(jump_arg_1) > unsigned'(jump_arg_2));
                end                  
                should_jump = lt_match || eq_match || gt_match;      
            end else if (jump_type_sig == 3'b011) begin
                logic lt_match, eq_match, gt_match;
                lt_match = cmd[2] && signed'(jump_arg_1) < 0;
                eq_match = cmd[1] && signed'(jump_arg_1) == 0;
                gt_match = cmd[0] && signed'(jump_arg_1) > 0;
                should_jump = lt_match || eq_match || gt_match;           
            end else if (jump_type_sig == 3'b100) begin            
                should_jump = jump_arg_1[cmd[5:1]] == cmd[0];                        
            end
        end else begin
            // Never jump if the operation isn't a jump!
            should_jump = 0;
        end                               
    end
  
endmodule
