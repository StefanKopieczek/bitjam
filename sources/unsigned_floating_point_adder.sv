`timescale 1ns / 1ps

//
// Adds together two inputted single-precision floating point numbers, with provisos.
//
// 1) Both inputs should be provided without their sign bit (i.e. only the last 31 bits of each number).
// 2) The addition assumes both numbers are positive.
// 3) Inputs are expected to already be normed (i.e. have equal exponents).
//
// TODO: Handle denormalised numbers, infs, and NaN.
//
module unsigned_floating_point_adder(
    input logic [23:0] a_mant,
    input logic [23:0] b_mant,
    input logic [7:0] exp,    
    output logic [30:0] out   
    );           
          
    logic [24:0] sum_mant_with_overflow;
    assign sum_mant_with_overflow = a_mant + b_mant;         
    
    logic [7:0] out_exp;
    logic [22:0] out_mant;          

    always_comb begin                
        if (sum_mant_with_overflow[24]) begin
            out_mant = sum_mant_with_overflow >> 1;
            out_exp = (exp + 1);
        end
        else begin
            out_mant = sum_mant_with_overflow;
            out_exp = exp;
        end      
        
        // The first bit of the mantissa will always be one, and is not stored in the number.
        out = {out_exp, out_mant[22:0]};  
    end
endmodule
