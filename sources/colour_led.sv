`timescale 1ns / 1ps

module colour_led(
    input wire clock_100mhz,
    input logic red,
    input logic green,
    input logic blue,
    output logic led_red,
    output logic led_green,
    output logic led_blue
    );
    
    logic [15:0] clock_divider;
    always @(posedge clock_100mhz)
        clock_divider <= clock_divider + 14'd1;
    logic clock;
    assign clock = clock_divider[12];
    
    always @(posedge clock) begin
        led_red <= red & &clock_divider[15:13];
        led_green <= green & &clock_divider[15:13];
        led_blue <= blue & &clock_divider[15:13];
    end
endmodule
