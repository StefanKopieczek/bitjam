`timescale 1ns / 1ps

module mono_led_controller(
    input logic [31:0] pc,
    input logic [15:0] led_data_in,
    input logic slave_leds_to_pc,    
    output logic [15:0] mono_led_out
    );
    
    always_comb begin
        if (slave_leds_to_pc) mono_led_out = pc[15:0];
        else mono_led_out = led_data_in;
    end
endmodule
