`timescale 1ns / 1ps

// TODO: Handle denormalised numbers, infs, and NaN.
module floating_point_adder_subtracter(
    input logic[31:0] a,
    input logic[31:0] b,
    input logic is_subtract,
    output logic[31:0] out
    );
    
    // First, normalise the inputs so they have the same exponent.
    // At the same time, unroll the mantissas from the significands (e.g. add in the implied 1 bit).
    logic a_sign;
    logic b_sign;
    logic [7:0] shared_exponent;
    logic [23:0] a_mant;
    logic [23:0] b_mant;    
    floating_point_normalizer normer (
        .a(a),
        .b(b),
        .exp(shared_exponent),
        .a_sign(a_sign),
        .b_sign(b_sign),
        .a_mant(a_mant),
        .b_mant(b_mant)        
    );
    
    // If this is a subtraction, flip the sign on 'b' and consider it an addition.
    // This reduces the number of cases we need to cover.
    logic is_a_positive;
    logic is_b_positive;
    assign is_a_positive = ~a_sign;
    assign is_b_positive = is_subtract ? b_sign : ~b_sign;              
    
    // We are now adding two numbers, each of which may be positive or negative.
    // We will handle each possible combination of +/- separately, with each case
    // resulting in either an unsigned addition or an unsigned subtraction.
    logic [23:0] a_mant_final;
    logic [23:0] b_mant_final;    
    logic [30:0] addition_result;
    logic [30:0] subtraction_result;
    logic subtraction_underflowed;
    logic use_subtraction;
    logic invert_result;
    always @(*) begin
        if (is_a_positive & is_b_positive) begin
            // Adding two positive numbers together; just add them unsigned.
            a_mant_final = a_mant;
            b_mant_final = b_mant;              
            use_subtraction = 0;
            invert_result = 0;            
        end 
        else if (is_a_positive) begin
            // Adding a positive number to a negative number; use unsigned subtraction.            
            a_mant_final = a_mant;
            b_mant_final = b_mant;
            use_subtraction = 1;
            invert_result = 0;
        end
        else if (is_b_positive) begin
            // Adding a negative number to a positive number; swap arguments and subtract.
            a_mant_final = b_mant;
            b_mant_final = a_mant;
            use_subtraction = 1;
            invert_result = 0;
        end
        else begin
            // Adding two negative numbers together; add them as positives and then invert.
            a_mant_final = a_mant;
            b_mant_final = b_mant;
            use_subtraction = 0;
            invert_result = 1;
        end
    end
    
    // Perform addition/subtraction using the relevant submodules.
    unsigned_floating_point_adder adder (
        .a_mant(a_mant_final),
        .b_mant(b_mant_final),
        .exp(shared_exponent),        
        .out(addition_result)
    );
    unsigned_floating_point_subtracter subtracter (
        .a_mant(a_mant_final),  
        .b_mant(b_mant_final),
        .exp(shared_exponent),    
        .out(subtraction_result),
        .underflow(subtraction_underflowed)
    );
    
    // Select the appropriate result and tweak as needed.
    logic sign;
    assign sign = (use_subtraction & subtraction_underflowed) ^ invert_result;
    assign out[31] = sign;
    assign out[30:0] = use_subtraction ? subtraction_result : addition_result;                
endmodule
