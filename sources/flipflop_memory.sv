`timescale 1ns / 1ps

module flipflop_memory #(SIZE=80) (
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
        flipflops[21] = 32'h2003c000;  // JUMP sqrt
        flipflops[22] = 32'h00000080;
        flipflops[48] = 32'h00028cf5;  // sqrt: FLDIV F, D -> H
        flipflops[49] = 32'h00019cf2;  // FLADD D, H -> H
        flipflops[50] = 32'h00039874;  // FLMUL H, G -> D
        flipflops[51] = 32'h0004bd21;  // SUB J, 0x1 -> J
        flipflops[52] = 32'h00000001;
        flipflops[53] = 32'h201bc049;  // JUMP sqrt IF J > 0x0
        flipflops[54] = 32'h00000080;
        flipflops[55] = 32'h1003c060;  // LOAD D -> A
        flipflops[56] = 32'h2003c000;  // JUMP loop
        flipflops[57] = 32'h0000005c;
        
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
