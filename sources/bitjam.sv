`timescale 1ns / 1ps

module bitjam(
    input logic CLK_100MHZ,
    input logic [15:0] SW,
    input logic BTN_RES,
    input logic BTNC,
    input logic BTNU,
    input logic BTNR,
    input logic BTND,
    input logic BTNL,      
    output logic [7:0] AN,
    output logic [7:0] CN,
    output logic [15:0] LED,
    output logic LED16_R,
    output logic LED16_G,
    output logic LED16_B,
    output logic LED17_R,
    output logic LED17_G,
    output logic LED17_B    
    );
    
    import internal_state::*;
    import peripherals::*;
    
    buttons_t buttons;
    assign buttons.left = BTNL;
    assign buttons.right = BTNR;
    assign buttons.up = BTNU;
    assign buttons.down = BTND;
    assign buttons.center = BTNC;
    
    color_led_pins_t rgb_led_left;
    color_led_pins_t rgb_led_right;
    assign rgb_led_left.red = LED17_R;
    assign rgb_led_left.green = LED17_G;
    assign rgb_led_left.blue = LED17_B;
    assign rgb_led_right.red = LED16_R;
    assign rgb_led_right.green = LED16_G;
    assign rgb_led_right.blue = LED16_B;
        
    peripheral_control_bus_t peripheral_control_bus;
    peripheral_status_bus_t peripheral_status_bus;    
    internal_state_bus_t cpu_internal_state;      
    
    logic [150:0] clock_divider;
    always @(posedge CLK_100MHZ) begin
        clock_divider <= clock_divider + 15'b1;
    end
             
    cpu cpu (
        .clock_100mhz(clock_divider[1 + SW[6:0]]),           
        .reset(~BTN_RES),        
        .internal_state(cpu_internal_state),
        .peripheral_control_bus(peripheral_control_bus),
        .peripheral_status_bus(peripheral_status_bus)
    );
    
    peripheral_manager peripheral_manager (
        .clock_100mhz(CLK_100MHZ),        
        .buttons(buttons),
        .switches(SW),
        .sevenseg_anode(AN),
        .sevenseg_cathode(CN),
        .mono_leds(LED),
        .left_rgb_led(rgb_led_left),
        .right_rgb_led(rgb_led_right),
        .cpu_state(cpu_internal_state),
        .peripheral_control_bus(peripheral_control_bus),
        .peripheral_status_bus(peripheral_status_bus)                
    );    
    
endmodule

