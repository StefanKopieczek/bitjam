`timescale 1ns / 1ps

module colour_led(
    input wire clock_100mhz,
    input logic[7:0] red,
    input logic[7:0] green,
    input logic[7:0] blue,
    output logic led_red,
    output logic led_green,
    output logic led_blue
    );
    
    logic [20:0] clock_divider;
    initial clock_divider = 16'h0;
    always @(posedge clock_100mhz)
        clock_divider <= clock_divider + 14'd1;
    logic clock;
    assign clock = clock_divider[10];
    
    always @(posedge clock) begin
        led_red <= (clock_divider[18:11] <= red);
        led_green <= (clock_divider[18:11] <= green);
        led_blue <= (clock_divider[18:11] <= blue);
    end
endmodule
