`timescale 1ns / 1ps

// Given an input bus, returns the left shift that would be necessary in order to
// have the MSB of the bus be high.
// If all bits are zero, the result is undefined - it is the caller's responsibility
// to check this case.
module high_bit_finder #(parameter WIDTH=24)
    (
        input logic [WIDTH-1:0] in,
        output logic [$clog2(WIDTH)-1:0] shift
    );
    
    always_comb begin
        shift = '0;
        for (int i = 0; i <= WIDTH - 1; i = i + 1) begin
          if (in[WIDTH - i - 1]) begin
            shift = i;
            break;
          end
        end
    end
endmodule
