`timescale 1ns / 1ps

import peripherals::*;

module memory_mapped_peripherals (
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
    
    peripheral_control_bus_t control_state;
    assign peripheral_control_bus = control_state;
    
    // Initialize control bus
    initial begin
        control_state.display_control = 0;
        control_state.sevenseg_data = 64'h0;
        control_state.mono_led_data = 16'h0;
        control_state.color_led_data[0] = 0;
        control_state.color_led_data[1] = 0;
    end
    
    // Write path
    always @(posedge clock) begin
        if (mode == WRITE_MODE) begin
             if (address_in == 32'h20) control_state.display_control <= data_in;
             else if (address_in == 32'h21) control_state.sevenseg_data[31:0] <= data_in;
             else if (address_in == 32'h22) control_state.sevenseg_data[63:32] <= data_in;
             else if (address_in == 32'h23) control_state.mono_led_data <= data_in;
             else if (address_in == 32'h24) control_state.color_led_data[0] <= data_in;
             else if (address_in == 32'h25) control_state.color_led_data[1] <= data_in;                                                                  
        end
     end
     
     // Read path
     always_comb begin
         if (mode == READ_MODE) begin
             if (address_in == 32'h20) data_out = control_state.display_control;
             else if (address_in == 32'h21) data_out = control_state.sevenseg_data[31:0];
             else if (address_in == 32'h22) data_out = control_state.sevenseg_data[63:32];
             else if (address_in == 32'h23) data_out = control_state.mono_led_data;
             else if (address_in == 32'h24) data_out = control_state.color_led_data[0];
             else if (address_in == 32'h25) data_out = control_state.color_led_data[1];
             else if (address_in == 32'h26) data_out = peripheral_status_bus;                                
             else data_out = 0;            
         end else begin
             data_out = 0;
         end  
     end      
endmodule
