`timescale 1ns / 1ps

import color::*;
import internal_state::*;
import peripherals::*; 
import registers::*;

module peripheral_manager(
    input logic clock_100mhz,
    input internal_state_bus_t cpu_state,
    input peripheral_control_bus_t control_bus,
    input buttons_t buttons,
    input logic [15:0] switches,
    output peripheral_status_bus_t status_bus,
    output logic [7:0] sevenseg_anode,
    output logic [7:0] sevenseg_cathode,
    output logic [15:0] mono_leds,
    output color_led_pins_t left_rgb_led,
    output color_led_pins_t right_rgb_led
    );                      
    
    // Configure the seven segment displays.
    sevenseg_controller sevenseg_controller (
        .clock_100mhz(clock_100mhz),
        .control_bits(control_bus.display_control[1:0]),
        .data_bits(control_bus.sevenseg_data),
        .register_a(cpu_state.registers[A]),
        .anode(sevenseg_anode),
        .cathode(sevenseg_cathode)
    );
    
    // Configure the mono LEDs;
    mono_led_controller mono_led_controller (
        .pc(cpu_state.pc),
        .led_data_in(control_bus.mono_led_data),
        .slave_leds_to_pc(~control_bus.display_control[2]),
        .mono_led_out(mono_leds)
    );    
    
    // Configure the left RGB LED.
    color_t left_led;
    assign left_led.red = cpu_state.cmd[31:28] == 4'd0 ? 8'h40 : 8'h0;
    assign left_led.green = cpu_state.cmd[31:28] == 4'd1 ? 8'h40 : 8'h0;
    assign left_led.blue = cpu_state.cmd[31:28] == 4'd2 ? 8'h40 : 8'h0;    
    colour_led cmd_led (
        .clock_100mhz(clock_100mhz),
        .color(left_led),
        .red_enable(left_rgb_led.red),
        .green_enable(left_rgb_led.green),
        .blue_enable(left_rgb_led.blue)
    );
    
    // Configure the right RGB LED.
    color_t right_led;
    assign right_led.red = cpu_state.memory_state == 4'd3 ? 8'h40 : 8'h0; // Writing
    assign right_led.green = (cpu_state.memory_state == 4'd1 || cpu_state.memory_state == 4'd2) == 4'd1 ? 8'h40 : 8'h0; // Reading arg
    assign right_led.blue = (cpu_state.memory_state == 4'd4 || cpu_state.memory_state == 4'd5) == 4'd2 ? 8'h40 : 8'h0; // Reading ptr    
    colour_led memory_led (
        .clock_100mhz(clock_100mhz),
        .color(right_led),
        .red_enable(right_rgb_led.red),
        .green_enable(right_rgb_led.green),
        .blue_enable(right_rgb_led.blue)
    );
    
    // Populate the status bus with the (debounced) state of the switches and buttons. 
    genvar i;
    generate
        for (i = 0; i < 16; i = i + 1) begin : gen_switch_debouncers
            debouncer debouncer (
                .clock_100mhz(clock_100mhz),
                .raw(switches[i]),
                .debounced(status_bus.switch_state[i])
            );
        end
    endgenerate
    generate
        for (i = 0; i < 5; i = i + 1) begin : gen_button_debouncers
            debouncer debouncer (
                .clock_100mhz(clock_100mhz),
                .raw(buttons[i]),
                .debounced(status_bus.button_state[i])
            );
        end
    endgenerate
endmodule
