`timescale 1ns / 1ps

module sevenseg_controller(
    input logic clock_100mhz,
    input logic [1:0] control_bits,
    input logic [63:0] data_bits,
    input logic [31:0] register_a,
    output logic [7:0] anode,
    output logic [7:0] cathode    
    );
    
    typedef enum {
        DISPLAY_REGISTER_A,    
        DISPLAY_CUSTOM_WORD,   // Display word held in lowest 32 bits of data.
        FULL_CONTROL,          // Address individual segments using all 64 data bits.
        OFF                    // Switch off the display.
    } sevenseg_mode_e; 
    sevenseg_mode_e sevenseg_mode;
        
    // Determine the current display mode
    always_comb begin
        if (control_bits == 2'd0) sevenseg_mode = DISPLAY_REGISTER_A;
        else if (control_bits == 2'd1) sevenseg_mode = DISPLAY_CUSTOM_WORD;
        else if (control_bits == 2'd2) sevenseg_mode = FULL_CONTROL;
        else sevenseg_mode = OFF;
    end
    
    // If displaying a word (either from reg A or a custom word), determine what it is.
    logic [31:0] displayed_word;  
    always_comb begin            
        if (sevenseg_mode == DISPLAY_REGISTER_A) displayed_word = register_a;
        else if (sevenseg_mode == DISPLAY_CUSTOM_WORD) displayed_word = data_bits[31:0];
        else displayed_word = 0;
    end
    
    // If displaying a word, calculate the desired anode and cathode values.
    logic [7:0] anode_for_word;
    logic [7:0] cathode_for_word;    
    dword_display word_displayer (
        .clock_100mhz(clock_100mhz),
        .dword(displayed_word),
        .flash_upper_half(0),
        .flash_lower_half(0),
        .an(anode_for_word),
        .cn(cathode_for_word)
    );
    
    // If displaying a fully custom readout, calculate the desired anode and cathode values.
    // We need to set up our own strobe clock to do this.   
    logic [7:0] custom_anode;
    logic [7:0] custom_cathode;       
    logic [12:0] clock_divider;
    logic strobe_clock;    
    initial clock_divider = 12'h0;    
    assign strobe_clock = clock_divider[12];        
    always @(posedge clock_100mhz) clock_divider <= clock_divider + 'b1;
    logic [7:0] custom_glyphs[7:0];
    assign {>>{custom_glyphs[7], custom_glyphs[6], custom_glyphs[5], custom_glyphs[4], custom_glyphs[3], custom_glyphs[2], custom_glyphs[1], custom_glyphs[0]}} = data_bits;        
    sevenseg custom_display (
        .CLOCK(strobe_clock),
        .VALUE(custom_glyphs),
        .AN(custom_anode),
        .CN(custom_cathode)
    );
    
    // Now decide which AN/CN to use.
    always_comb begin
        if (sevenseg_mode == DISPLAY_REGISTER_A || sevenseg_mode == DISPLAY_CUSTOM_WORD) begin
            anode = anode_for_word;
            cathode = cathode_for_word;
        end else if (sevenseg_mode == FULL_CONTROL) begin
            anode = custom_anode;
            cathode = custom_cathode;
        end else begin
            anode = 8'h0;
            cathode = 8'hff;
        end
    end
    
endmodule
