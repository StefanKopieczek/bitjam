`timescale 1ns / 1ps

//
// Subtracts together two inputted single-precision floating point numbers, with provisos.
//
// 1) Both inputs should be provided without their sign bit (i.e. only the last 31 bits of each number).
// 2) The subtraction assumes both numbers are positive.
// 3) Inputs are expected to already be normed (i.e. have equal exponents).
//
// Returns the result as 'out', which may have wrapped around.
// If wraparound has occurred, the 'underflow' output will be high (and will be low otherwise).
//
module unsigned_floating_point_subtracter(
    input logic [23:0] a_mant,
    input logic [23:0] b_mant,
    input logic [7:0] exp,    
    output logic [30:0] out,
    output logic underflow
    );         
       
    assign underflow = (a_mant < b_mant) ? 1 : 0;
    logic [23:0] result;
    assign result = underflow ? b_mant - a_mant : a_mant - b_mant;    
    
    logic [23:0] out_mant;
    logic [7:0] final_exp;
    
    logic [4:0] shift;
    high_bit_finder #(.WIDTH(24)) high_bit_finder (
        .in(result),
        .shift(shift)
    );
    
    always_comb begin
        if (result == 0) begin
            // Result is a literal zero. To represent that we set both mant and exp to 0.
            out_mant = 0;
            final_exp = 0;
        end else begin
            out_mant = result << shift;
            final_exp = exp - shift;
        end        
    end   
        
    assign out = { final_exp, out_mant[22:0] };
endmodule