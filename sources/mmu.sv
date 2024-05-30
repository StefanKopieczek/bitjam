`timescale 1ns / 1ps

import peripherals::*;

module mmu (
    input wire clock,
    input logic [31:0] address_in,
    input logic mode,
    input peripheral_status_bus_t peripheral_status_bus,
    input logic [31:0] data_in,
    output logic [31:0] data_out,
    output peripheral_control_bus_t peripheral_control_bus 
    );
    
    localparam logic WRITE_MODE = 1;
    localparam logic READ_MODE = 0;
    
    localparam int PERIPHERAL_START = 'h0;
    localparam int PERIPHERAL_END = 'h4f;
    localparam int FLIPFLOP_START = PERIPHERAL_END + 1;
    localparam int FLIPFLOP_END = 'hff;
    
    logic use_peripherals;
    assign use_peripherals = (address_in >= PERIPHERAL_START) && (address_in <= PERIPHERAL_END);
    
    logic use_flipflops;
    assign use_flipflops = (address_in >= FLIPFLOP_START) && (address_in <= FLIPFLOP_END);                     
    
    logic peripheral_mode;
    assign peripheral_mode = use_peripherals & mode;
    logic [31:0] peripheral_data_out;
    memory_mapped_peripherals memory_mapped_peripherals (
        .clock(clock),
        .address_in(address_in - PERIPHERAL_START),
        .mode(peripheral_mode),
        .data_in(data_in),
        .data_out(peripheral_data_out),
        .peripheral_control_bus(peripheral_control_bus),
        .peripheral_status_bus(peripheral_status_bus)   
    );
    
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
        
    always @(posedge clock) begin      
        if (use_peripherals) data_out <= peripheral_data_out;
        else if (use_flipflops) data_out <= flipflop_data_out;
        else data_out <= 0;
    end        
        
endmodule
