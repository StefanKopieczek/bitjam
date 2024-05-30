`timescale 1ns / 1ps

import internal_state::*;
import peripherals::*; 

module peripheral_manager(
    input logic clock_100mhz,
    input internal_state_bus_t cpu_state,
    input peripheral_control_bus_t peripheral_control_bus,
    input buttons_t buttons,
    input logic [15:0] switches,
    output peripheral_status_bus_t peripheral_status_bus,
    output logic [7:0] sevenseg_anode,
    output logic [7:0] sevenseg_cathode,
    output logic [15:0] mono_leds,
    output color_led_pins_t left_rgb_led,
    output color_led_pins_t right_rgb_led
    );    
    
    logic [3:0] displayed_word_idx;
    initial displayed_word_idx = 0;
    always @(posedge clock_100mhz) begin
        if (buttons.center) displayed_word_idx <= 0;      // Reg A
        else if (buttons.up) displayed_word_idx <= 1; // Reg B
        else if (buttons.right) displayed_word_idx <= 2; // Reg C
        else if (buttons.down) displayed_word_idx <= 3; // Reg D
        else if (buttons.left) displayed_word_idx <= 4; // Reg E
    end
    logic [31:0] displayed_word;
    assign displayed_word = cpu_state.registers[displayed_word_idx];
    
    dword_display sevensegs (
        .clock_100mhz(clock_100mhz),
        .dword(displayed_word),
        .flash_upper_half(0),
        .flash_lower_half(0),
        .an(sevenseg_anode),
        .cn(sevenseg_cathode)
    );
    
    assign mono_leds = cpu_state.pc[15:0];
    
    colour_led cmd_led (
        .clock_100mhz(clock_100mhz),
        .red(cpu_state.cmd[31:28] == 4'd0),
        .green(cpu_state.cmd[31:28] == 4'd1),
        .blue(cpu_state.cmd[31:28] == 4'd2),
        .led_red(left_rgb_led.red),
        .led_green(left_rgb_led.green),
        .led_blue(left_rgb_led.blue)
    );
    
    colour_led memory_led (
        .clock_100mhz(clock_100mhz),
        .red(cpu_state.memory_state == 4'd3),                                      // Writing
        .green(cpu_state.memory_state == 4'd1 || cpu_state.memory_state == 4'd2),  // Reading argument
        .blue(cpu_state.memory_state == 4'd4 || cpu_state.memory_state == 4'd5),   // Reading pointer
        .led_red(right_rgb_led.red),
        .led_green(right_rgb_led.green),
        .led_blue(right_rgb_led.blue)
    );
endmodule
