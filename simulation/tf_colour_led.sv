`timescale 1ns / 1ps

module tf_colour_led(
    );
    
    logic clk; 
    initial clk = 0;
    always #5 clk = ~clk;
    
    logic led_red;
    logic led_green;
    logic led_blue;
    
    colour_led led (
        .clock_100mhz(clk),
        .red(8'h40),
        .green(8'h60),
        .blue(8'h80),
        .led_red(red_out),
        .led_green(green_out),
        .led_blue(blue_out)
    );
endmodule
