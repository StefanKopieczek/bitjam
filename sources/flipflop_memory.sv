`timescale 1ns / 1ps

module flipflop_memory #(SIZE=4016) (
    input wire clock,
    input logic [31:0] address_in,
    input logic mode,
    input logic [31:0] data_in,
    output logic [31:0] data_out 
    );
    
    localparam logic WRITE_MODE = 1;
    localparam logic READ_MODE = 0; 
    
    logic [31:0] flipflops [SIZE-1:0];
    
    initial begin
        int i;
        for (i = 0; i < SIZE; i = i + 1) begin
            flipflops[i] = 0;            
        end      

        flipflops[0] = 32'h1003c1e0;  // LOAD 0xdeadbeef -> A
        flipflops[1] = 32'hdeadbeef;
        flipflops[2] = 32'h1003c1ff;  // LOAD 0xffffffff -> *0x22
        flipflops[3] = 32'hffffffff;
        flipflops[4] = 32'h00000022;
        flipflops[5] = 32'h1003c1ff;  // LOAD 0x5555 -> *0x23
        flipflops[6] = 32'h00005555;
        flipflops[7] = 32'h00000023;
        flipflops[8] = 32'h1003c1e9;  // LOAD 0x0 -> J
        flipflops[9] = 32'h00000000;
        flipflops[10] = 32'h1003f3e1;  // loop: LOAD *0x26 >> 2 -> B
        flipflops[11] = 32'h00000026;
        flipflops[12] = 32'h2013c2f4;  // JUMP use_reg_a IF B == 0x10
        flipflops[13] = 32'h00000073;
        flipflops[14] = 32'h00000010;
        flipflops[15] = 32'h2013c2f4;  // JUMP use_custom_word IF B == 0x8
        flipflops[16] = 32'h0000007b;
        flipflops[17] = 32'h00000008;
        flipflops[18] = 32'h2013c2f4;  // JUMP use_custom_glyphs IF B == 0x4
        flipflops[19] = 32'h00000089;
        flipflops[20] = 32'h00000004;
        flipflops[21] = 32'h2013c2f4;  // JUMP turn_off IF B == 0x1
        flipflops[22] = 32'h00000093;
        flipflops[23] = 32'h00000001;
        flipflops[24] = 32'h2003c000;  // JUMP maybe_toggle_led_jiggle
        flipflops[25] = 32'h0000009d;
        flipflops[26] = 32'h201bc012;  // JUMP loop IF C == 0x0
        flipflops[27] = 32'h0000005a;
        flipflops[28] = 32'h000fbc68;  // AND *0x26, 0xffff -> D
        flipflops[29] = 32'h00000026;
        flipflops[30] = 32'h0000ffff;
        flipflops[31] = 32'h000183eb;  // NOT D -> *0x21
        flipflops[32] = 32'h00000021;
        flipflops[33] = 32'h2003c000;  // JUMP loop
        flipflops[34] = 32'h0000005a;
        flipflops[35] = 32'h000fbfe8;  // use_reg_a: AND *0x20, 0xffffffc -> *0x20
        flipflops[36] = 32'h00000020;
        flipflops[37] = 32'h0ffffffc;
        flipflops[38] = 32'h00000020;
        flipflops[39] = 32'h1003c1e2;  // LOAD 0x0 -> C
        flipflops[40] = 32'h00000000;
        flipflops[41] = 32'h2003c000;  // JUMP loop
        flipflops[42] = 32'h0000005a;
        flipflops[43] = 32'h000fbfe8;  // use_custom_word: AND *0x26, 0xffff -> *0x21
        flipflops[44] = 32'h00000026;
        flipflops[45] = 32'h0000ffff;
        flipflops[46] = 32'h00000021;
        flipflops[47] = 32'h000fbc68;  // AND *0x20, 0xffffffc -> D
        flipflops[48] = 32'h00000020;
        flipflops[49] = 32'h0ffffffc;
        flipflops[50] = 32'h0001bfe9;  // OR D, 0x1 -> *0x20
        flipflops[51] = 32'h00000001;
        flipflops[52] = 32'h00000020;
        flipflops[53] = 32'h1003c1e2;  // LOAD 0x0 -> C
        flipflops[54] = 32'h00000000;
        flipflops[55] = 32'h2003c000;  // JUMP loop
        flipflops[56] = 32'h0000005a;
        flipflops[57] = 32'h000fbc68;  // use_custom_glyphs: AND *0x20, 0xffffffc -> D
        flipflops[58] = 32'h00000020;
        flipflops[59] = 32'h0ffffffc;
        flipflops[60] = 32'h0001bfe9;  // OR D, 0x2 -> *0x20
        flipflops[61] = 32'h00000002;
        flipflops[62] = 32'h00000020;
        flipflops[63] = 32'h1003c1e2;  // LOAD 0x1 -> C
        flipflops[64] = 32'h00000001;
        flipflops[65] = 32'h2003c000;  // JUMP loop
        flipflops[66] = 32'h0000005a;
        flipflops[67] = 32'h000fbc68;  // turn_off: AND *0x20, 0xffffffc -> D
        flipflops[68] = 32'h00000020;
        flipflops[69] = 32'h0ffffffc;
        flipflops[70] = 32'h0001bfe9;  // OR D, 0x3 -> *0x20
        flipflops[71] = 32'h00000003;
        flipflops[72] = 32'h00000020;
        flipflops[73] = 32'h1003c1e2;  // LOAD 0x0 -> C
        flipflops[74] = 32'h00000000;
        flipflops[75] = 32'h2003c000;  // JUMP loop
        flipflops[76] = 32'h0000005a;
        flipflops[77] = 32'h0000bc68;  // maybe_toggle_led_jiggle: AND B, 0x2 -> D
        flipflops[78] = 32'h00000002;
        flipflops[79] = 32'h2013c694;  // JUMP loop IF D == J
        flipflops[80] = 32'h0000005a;
        flipflops[81] = 32'h1003c069;  // LOAD D -> J
        flipflops[82] = 32'h201bc049;  // JUMP loop IF J > 0x0
        flipflops[83] = 32'h0000005a;
        flipflops[84] = 32'h000fbfea;  // XOR *0x20, 0x4 -> *0x20
        flipflops[85] = 32'h00000020;
        flipflops[86] = 32'h00000004;
        flipflops[87] = 32'h00000020;
        flipflops[88] = 32'h2003c000;  // JUMP loop
        flipflops[89] = 32'h0000005a;
        
    end
    
    always @(posedge clock) begin
        if (mode == WRITE_MODE) begin
            if (address_in < SIZE) begin
                flipflops[address_in] <= data_in;
            end
        end
    end
    
    always_comb begin
        if ((mode == READ_MODE) && (address_in < SIZE)) begin            
            data_out = flipflops[address_in];
        end else
            data_out = 0;
        end        
endmodule
