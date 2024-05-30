`timescale 1ns / 1ps

import color::*;

module colour_led(
    input wire clock_100mhz,
    input color_t color,
    output logic red_enable,
    output logic green_enable,
    output logic blue_enable
    );
    
    logic [20:0] clock_divider;
    initial clock_divider = 16'h0;
    always @(posedge clock_100mhz)
        clock_divider <= clock_divider + 14'd1;
    logic clock;
    assign clock = clock_divider[10];
    
    always @(posedge clock) begin
        red_enable <= (clock_divider[18:11] <= color.red);
        green_enable <= (clock_divider[18:11] <= color.green);
        blue_enable <= (clock_divider[18:11] <= color.blue);
    end
endmodule
