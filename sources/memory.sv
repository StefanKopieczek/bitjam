`timescale 1ns / 1ps

// Janky temporary memory module that just uses a bunch of flipflops.
module memory #(SIZE=300) (
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
        
//        // Calculate fibonacci numbers <= 0x10000
//        flipflops[0]  = 32'h1003c1e0;
//        flipflops[1]  = 32'h00000001;
//        flipflops[2]  = 32'h1003c001;
//        flipflops[3]  = 32'h1003c002;
//        flipflops[4]  = 32'h00000400;
//        flipflops[5]  = 32'h1003c041;
//        flipflops[6]  = 32'h2013c0f8; 
//        flipflops[7]  = 32'h00000003;
//        flipflops[8]  = 32'h10000000;
//        flipflops[9]  = 32'h2003c000;
//        flipflops[10] = 32'h00000009;

        // Calculate prime numbers < 0x10000000
//        flipflops[0] = 32'h1003c1e0;
//        flipflops[1] = 32'h00000002;
//        flipflops[2] = 32'h1003c005;
//        flipflops[3] = 32'h1003c1e0;
//        flipflops[4] = 32'h00000003;
//        flipflops[5] = 32'h1003c001;
//        flipflops[6] = 32'h1003c024;
//        flipflops[7] = 32'h00009420;        
//        flipflops[8] = 32'h1003c1e2;
//        flipflops[9] = 32'h00000001;
//        flipflops[10] = 32'h00011440;
//        flipflops[11] = 32'h00008866;
//        flipflops[12] = 32'h201bc01a;
//        flipflops[13] = 32'h00000006;
//        flipflops[14] = 32'h2013c448;
//        flipflops[15] = 32'h0000000a;
//        flipflops[16] = 32'h1003c020;
//        flipflops[17] = 32'h2013c2f8;
//        flipflops[18] = 32'h00000006;
//        flipflops[19] = 32'h10000000;
//        flipflops[20] = 32'h2003c000;
//        flipflops[21] = 32'h00000014;

//        // Calculate prime numbers < 0x10000000 fast
//        flipflops[00] = 32'h1003c1e0;
//        flipflops[01] = 32'h00000002;
//        flipflops[02] = 32'h1003c005;
//        flipflops[03] = 32'h1003c1e0;
//        flipflops[04] = 32'h00000003;
//        flipflops[05] = 32'h1003c001;
//        flipflops[06] = 32'h00009420;
//        flipflops[07] = 32'h1003c1e4;
//        flipflops[08] = 32'h00004000;
//        flipflops[09] = 32'h2013c2f2;
//        flipflops[10] = 32'h00000017;
//        flipflops[11] = 32'h00100000;
//        flipflops[12] = 32'h1003c1e4;
//        flipflops[13] = 32'h00000400;
//        flipflops[14] = 32'h2013c2f2;
//        flipflops[15] = 32'h00000017;
//        flipflops[16] = 32'h00001000;
//        flipflops[17] = 32'h1003c1e4;
//        flipflops[18] = 32'h00000040;
//        flipflops[19] = 32'h2013c2f2;
//        flipflops[20] = 32'h00000017;
//        flipflops[21] = 32'h00000041;
//        flipflops[22] = 32'h1003c004;
//        flipflops[23] = 32'h1003c1e2;
//        flipflops[24] = 32'h00000001;
//        flipflops[25] = 32'h00011440;
//        flipflops[26] = 32'h00008866;
//        flipflops[27] = 32'h201bc01a;
//        flipflops[28] = 32'h00000006;
//        flipflops[29] = 32'h2013c448;
//        flipflops[30] = 32'h00000019;
//        flipflops[31] = 32'h1003c020;
//        flipflops[32] = 32'h2013c2f8;
//        flipflops[33] = 32'h00000006;
//        flipflops[34] = 32'h10000000;
//        flipflops[35] = 32'h2003c000;
//        flipflops[36] = 32'h00000023;

        flipflops[0] = 32'h1003c1e0;  // LOAD 0x40400000 -> A
        flipflops[1] = 32'h40400000;
        flipflops[2] = 32'h1003c1e1;  // LOAD 0x3f800000 -> B
        flipflops[3] = 32'h3f800000;
        flipflops[4] = 32'h1003c022;  // LOAD B -> C
        flipflops[5] = 32'h1003c028;  // LOAD B -> I
        flipflops[6] = 32'h1003c1e6;  // LOAD 0x3f000000 -> G
        flipflops[7] = 32'h3f000000;
        flipflops[8] = 32'h1003c023;  // LOAD B -> D
        flipflops[9] = 32'h00018c72;  // FLADD D, D -> D
        flipflops[10] = 32'h00018c94;  // FLMUL D, D -> E
        flipflops[11] = 32'h00019092;  // FLADD D, E -> E
        flipflops[12] = 32'h00012052;  // loop: FLADD C, I -> C
        flipflops[13] = 32'h1003c043;  // LOAD C -> D
        flipflops[14] = 32'h00018c74;  // FLMUL D, D -> D
        flipflops[15] = 32'h00040c75;  // FLDIV I, D -> D
        flipflops[16] = 32'h00008c32;  // FLADD B, D -> B
        flipflops[17] = 32'h000090b4;  // FLMUL B, E -> F
        flipflops[18] = 32'h1003c1e9;  // LOAD 0x14 -> J
        flipflops[19] = 32'h00000014;
        flipflops[20] = 32'h1003c003;  // LOAD A -> D
        flipflops[21] = 32'h00028cf5;  // sqrt: FLDIV F, D -> H
        flipflops[22] = 32'h00019cf2;  // FLADD D, H -> H
        flipflops[23] = 32'h00039874;  // FLMUL H, G -> D
        flipflops[24] = 32'h0004bd21;  // SUB J, 0x1 -> J
        flipflops[25] = 32'h00000001;
        flipflops[26] = 32'h201bc049;  // JUMP sqrt IF J > 0x0
        flipflops[27] = 32'h00000015;
        flipflops[28] = 32'h1003c060;  // LOAD D -> A
        flipflops[29] = 32'h2003c000;  // JUMP loop
        flipflops[30] = 32'h0000000c;
        
    end
    
    always @(posedge clock) begin
        if (mode == WRITE_MODE) begin
            if (address_in < SIZE) begin
                flipflops[address_in] <= data_in;
            end
        end else if (mode == READ_MODE) begin
            if (address_in < SIZE) begin
                data_out = flipflops[address_in];
            end else
                data_out = 0;
            end
        end
        
endmodule
