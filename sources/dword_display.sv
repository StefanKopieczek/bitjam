`timescale 1ns / 1ps

// Displays the given DWORD on eight seven segment displays.
// Optionally can flash either/both of the upper and lower words.
module dword_display(
    input wire clock_100mhz,
    input logic [31:0] dword,
    input logic flash_upper_half,
    input logic flash_lower_half,            
    output logic [7:0] an,
    output logic [7:0] cn
    );
    
    // Set up two clocks:
    // - A ~12kHz clock for strobing the LEDs. 
    // - A ~1.5Hz clock to use for flashing digits.     
    logic [25:0] clock_divider;
    logic strobe_clock;
    logic flash_active;
    initial clock_divider = 'h0;    
    assign strobe_clock = clock_divider[12];    
    assign flash_active = clock_divider[25];    
    always @(posedge clock_100mhz)
        clock_divider <= clock_divider + 'b1;       
    
    // Set up the display.
    logic [7:0] sevenseg_values[7:0];
    sevenseg sevenseg (
        .CLOCK(strobe_clock),
        .VALUE(sevenseg_values),
        .AN(an),
        .CN(cn)
    );

    // Set up masks for flashing the upper and/or lower half, if requested.
    logic [7:0] upper_flash_mask;
    logic [7:0] lower_flash_mask;
    assign upper_flash_mask = (flash_active & flash_upper_half) ? 'hff : 'h00;
    assign lower_flash_mask = (flash_active & flash_lower_half) ? 'hff : 'h00;
    
    // Populate the seven segment display.
    assign sevenseg_values[7] = sevenseg.DIGITS[dword >> 28] | upper_flash_mask;
    assign sevenseg_values[6] = (sevenseg.DIGITS[(dword >> 24) & 'hf]) | upper_flash_mask;
    assign sevenseg_values[5] = (sevenseg.DIGITS[(dword >> 20) & 'hf]) | upper_flash_mask;
    assign sevenseg_values[4] = (sevenseg.DIGITS[(dword >> 16) & 'hf]) | upper_flash_mask;
    assign sevenseg_values[3] = (sevenseg.DIGITS[(dword >> 12) & 'hf]) | lower_flash_mask;
    assign sevenseg_values[2] = (sevenseg.DIGITS[(dword >> 8) & 'hf]) | lower_flash_mask;
    assign sevenseg_values[1] = (sevenseg.DIGITS[(dword >> 4) & 'hf]) | lower_flash_mask;
    assign sevenseg_values[0] = (sevenseg.DIGITS[dword & 'hf]) | lower_flash_mask;              
endmodule
