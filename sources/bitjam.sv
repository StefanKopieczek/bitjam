`timescale 1ns / 1ps

module bitjam(
    input logic CLK_100MHZ,
    input logic [15:0] SW,
    input logic BTN_RES,
    input logic BTNC,
    input logic BTNU,
    input logic BTNR,
    input logic BTND,
    input logic BTNL,      
    output logic [7:0] AN,
    output logic [7:0] CN,
    output logic [15:0] LED,
    output logic LED16_R,
    output logic LED16_G,
    output logic LED16_B,
    output logic LED17_R,
    output logic LED17_G,
    output logic LED17_B    
    );
    
    logic [31:0] pc;
    logic [31:0] registers [9:0];
    logic [31:0] cmd;
    logic [2:0] memory_state;
    
    logic [150:0] clock_divider;
    always @(posedge CLK_100MHZ) begin
        clock_divider <= clock_divider + 15'b1;
    end
    
    cpu cpu (
        .clock_100mhz(clock_divider[1 + SW[6:0]]),           
        .reset(~BTN_RES),
        .pc_out(pc),
        .reg_out(registers),
        .cmd_out(cmd),
        .mem_state_out(memory_state)
    );
    
    logic [3:0] displayed_word_idx;
    initial displayed_word_idx = 0;
    always @(posedge CLK_100MHZ) begin
        if (BTNC) displayed_word_idx <= 0;      // Reg A
        else if (BTNU) displayed_word_idx <= 1; // Reg B
        else if (BTNR) displayed_word_idx <= 2; // Reg C
        else if (BTND) displayed_word_idx <= 3; // Reg D
        else if (BTNL) displayed_word_idx <= 4; // Reg E
    end
    logic [31:0] displayed_word;
    assign displayed_word = registers[displayed_word_idx];
    
    dword_display sevensegs (
        .clock_100mhz(CLK_100MHZ),
        .dword(displayed_word),
        .flash_upper_half(0),
        .flash_lower_half(0),
        .an(AN),
        .cn(CN)
    );
    
    assign LED = pc[15:0];
    
    colour_led cmd_led (
        .clock_100mhz(CLK_100MHZ),
        .red(cmd[31:28] == 4'd0),
        .green(cmd[31:28] == 4'd1),
        .blue(cmd[31:28] == 4'd2),
        .led_red(LED17_R),
        .led_green(LED17_G),
        .led_blue(LED17_B)
    );
    
    colour_led memory_led (
        .clock_100mhz(CLK_100MHZ),
        .red(memory_state == 4'd3),                         // Writing
        .green(memory_state == 4'd1 || memory_state == 4'd2),  // Reading argument
        .blue(memory_state == 4'd4 || memory_state == 4'd5),   // Reading pointer
        .led_red(LED16_R),
        .led_green(LED16_G),
        .led_blue(LED16_B)
    );
    
endmodule

