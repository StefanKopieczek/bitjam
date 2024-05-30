`timescale 1ns / 1ps

// Finds the reciprocal of the input floating point number.
module floating_point_inverter(
    input logic [31:0] in,
    output logic [31:0] out
    );
    
    logic in_sign;
    assign in_sign = in[31];
    
    int in_exp;
    assign in_exp = in[30:23] - 127;
    
    logic [23:0] in_mant;
    assign in_mant = {'b1, in[22:0]};
        
    logic [47:0] mant_reciprocal;
    assign mant_reciprocal = (1 << 46) / in_mant;
    
    int exp_reciprocal_biased;
    assign exp_reciprocal_biased = 127 - in_exp;
    
    logic [4:0] shift;
    high_bit_finder #(.WIDTH(24)) high_bit_finder (
        .in(mant_reciprocal[23:0]),
        .shift(shift)
    );
        
    logic [23:0] normalized_mant;
    logic [7:0] normalized_exp;
    assign normalized_mant = mant_reciprocal << shift;
    assign normalized_exp = exp_reciprocal_biased - shift;
    
    assign out = { in_sign, normalized_exp, normalized_mant[22:0] }; 
    
endmodule
