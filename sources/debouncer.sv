`timescale 1ns / 1ps

module debouncer(
    input logic clock_100mhz,
    input logic raw,
    output logic debounced
    );
    
    // Require the change to be asserted for over 10ms before registering.
    logic [19:0] counter;
    initial counter = 20'd0;    
    initial debounced = raw;
    
    always @(posedge clock_100mhz) begin
        if ((debounced != raw) && counter[19] == 1) begin
            counter <= 0;
            debounced <= raw;
        end else if ((debounced != raw)) begin        
            counter <= counter + 1;
        end else begin
            counter <= 0;            
        end
    end
endmodule
