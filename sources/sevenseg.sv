`timescale 1ns / 1ps

// Controls the seven segment displays.
//
// To show distinct digits on all eight displays, we strobe through them rapidly, illuminating each.
// Thus we need a CLOCK signal, which must be in 1kHZ to 60kHz to allow continuous illumination without flicker.
//
// Each display is coded with an eight bit 'value', indicating which segments to light.
// We thus take as input VALUE[7:0][7:0], with each member of the array holding a separate digit.
//
// You can use the convenience param DIGITS to obtain appropriate values; e.g.:
//   - assign VALUE[4] = sevenseg.DIGITS[7]: sets digit 5 to the numeral '7'.
//   - assign VALUE[2] = sevenseg.DIGITS['hc] & sevenseg.DECIMAL: sets digit 3 to the hex numeral 'c' with decimal point added. 
//
// Our outputs are AN and CN, which we expect to be wired to {an[0], ..., an[7]} and {ca, cb, ..., cg, dp} 
// on the output.
module sevenseg(CLOCK, VALUE, AN, CN);
    input  wire                CLOCK;
    input  reg         [7:0]   VALUE[7:0];
    output reg         [7:0]   AN;
    output reg         [7:0]   CN;    
           
           reg         [2:0]   ACTIVE_SEGMENT; 
           localparam  [7:0]   DIGITS[15:0] = {'h8e, 'h86, 'ha1, 'hc6, 'h83, 'h88, 'h90, 'h80, 'hf8, 'h82, 'h92, 'h99, 'hb0, 'ha4, 'hf9, 'hc0};
           localparam  [7:0]   DECIMAL = 'h7f;  // AND this with a value to turn it on                               
                          
    initial ACTIVE_SEGMENT = 0;    
    initial AN = 'hfe;
    initial CN = 'hff;
    
    // Toggle the seven segment strobe on every pulse.
    always @(posedge CLOCK)
    begin                         
        ACTIVE_SEGMENT <= ACTIVE_SEGMENT + 1;
    end
    
    // Enable the appropriate 7-seg as well as its selected digits, based on 
    // the currently-active segment.
    always @(*)
    begin        
        AN <= ~('h01 << ACTIVE_SEGMENT);
        CN <= VALUE[ACTIVE_SEGMENT];
    end          
    
endmodule