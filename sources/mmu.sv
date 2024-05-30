`timescale 1ns / 1ps

module mmu (
    input wire clock,
    input logic [31:0] address_in,
    input logic mode,
    input logic [31:0] data_in,
    output logic [31:0] data_out 
    );
    
    localparam logic WRITE_MODE = 1;
    localparam logic READ_MODE = 0;
    
    localparam int FLIPFLOP_START = 'h50;
    localparam int FLIPFLOP_END = 'hff;
    
    logic use_flipflops;
    assign use_flipflops = (address_in >= FLIPFLOP_START) && (address_in <= FLIPFLOP_END); 
        
    logic flipflop_mode;
    assign flipflop_mode = use_flipflops & mode;
    logic [31:0] flipflop_data_out;
    flipflop_memory flipflop_memory (
        .clock(clock),
        .address_in(address_in - FLIPFLOP_START),
        .mode(flipflop_mode),
        .data_in(data_in),
        .data_out(flipflop_data_out)
    );
    
    logic did_use_flipflops;
    always @(posedge clock) did_use_flipflops <= use_flipflops;
    
    always_comb begin        
        if (did_use_flipflops) begin
            data_out = flipflop_data_out;
        end else begin
            data_out = 32'h0;
        end
    end
        
endmodule
