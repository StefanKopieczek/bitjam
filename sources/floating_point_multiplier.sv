`timescale 1ns / 1ps

module floating_point_multiplier(
    input logic [31:0] a,
    input logic [31:0] b,
    output logic [31:0] out
    );
    
    logic a_sign;
    int a_exp;
    logic [23:0] a_mant;    
    assign a_sign = a[31];
    assign a_exp = a[30:23] - 127;
    assign a_mant = {1, a[22:0]};  // TODO support subnormals.
    
    logic b_sign;
    int b_exp;
    logic [23:0] b_mant;    
    assign b_sign = b[31];
    assign b_exp = b[30:23] - 127;
    assign b_mant = {1, b[22:0]};  // TODO support subnormals.
    
    // Calculate the raw result of the multiplication,
    // before normalisation and packing.
    logic result_sign;
    int result_exp_biased;
    logic [47:0] result_mant_unrolled;
    assign result_sign = a_sign + b_sign;
    assign result_exp_biased = a_exp + b_exp + 127;        
    assign result_mant_unrolled = a_mant * b_mant;
    
    // Calculate the shift required to normalise the result.
    logic [5:0] shift;
    high_bit_finder #(.WIDTH(48)) high_bit_finder (
        .in(result_mant_unrolled),
        .shift(shift)
    );
    
    // Normalise the result.
    logic [47:0] normal_result_mant_unrolled;
    logic [7:0] normal_result_exp_biased;
    always_comb begin
        if (result_mant_unrolled == 0) begin
            normal_result_mant_unrolled = 64'd0;
            normal_result_exp_biased = '0;
        end else begin
            normal_result_mant_unrolled = result_mant_unrolled << shift;
            // I can't work out for the life of me why I need the +1 here.
            // But it seems to work, so...
            normal_result_exp_biased = result_exp_biased - shift + 1;
        end
    end
    
    // Pack the result, taking the top bits of the mantissa (except the top 1).
    // TODO: support subnormals.
    assign out = { result_sign, normal_result_exp_biased, normal_result_mant_unrolled[46:24] };                            
endmodule
