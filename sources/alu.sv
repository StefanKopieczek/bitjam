`timescale 1ns / 1ps

// Arithmetic-Logic Unit.
// Supports 32-bit integer and floating-point arithmetic.
//
// Single-operand commands use the A input.
// Dual-operand commands use both A and B.
//
// The inputs will be updated on a rising edge to 'clk', but only if input_enable is high.
// Propagation delay to the output has not yet been measured or constrained, so right now
// the setup and hold timings are more of an art than a science :)
//
// The bottom five bits of 'cmd' are used to select the operation:
//
// /---------------------------------------------------------------\
// | Opcode (Bin) | Opcode (Hex) | Operation | Number of Arguments |
// | ------------ | ------------ | --------- | ------------------- |
// | 00000        | 0            | ADD       | 2                   |
// | 00001        | 1            | SUB       | 2                   |
// | 00010        | 2            | MUL       | 2                   |
// | 00011        | 3            | IMUL      | 2                   |
// | 00100        | 4            | DIV       | 2                   |
// | 00101        | 5            | IDIV      | 2                   |
// | 00110        | 6            | MOD       | 2                   |
// | 00111        | 7            | NEG       | 2                   |
// | 01000        | 8            | AND       | 2                   |
// | 01001        | 9            | OR        | 2                   |
// | 01010        | a            | XOR       | 2                   |
// | 01011        | b            | NOT       | 1                   |
// | 01100        | c            | LSHIFT    | 2                   |
// | 01101        | d            | RSHIFT    | 2                   |
// | 01110        | e            | LASHIFT   | 2                   |
// | 01111        | f            | LASHIFT   | 2                   |
// | 10000        | 10           | LROT      | 2                   |
// | 10001        | 11           | RROT      | 2                   |
// | 10010        | 12           | FLADD     | 2                   |
// | 10011        | 13           | FLSUB     | 2                   |
// | 10100        | 14           | FMUL      | 2                   |
// | 10101        | 15           | FDIV      | 2                   |
// | 10110        | 16           | FNEG      | 1                   |
// \--------------------------------------------------------------/
//
module alu(
    input logic  [31:0] a,
    input logic  [31:0] b,
    input logic  [31:0] cmd,
    output logic [31:0] out
    );    
        
    // Mask out the top bits of 'cmd' so we can do equality checks on the last five bits
    // (the bits that command the ALU).
    logic [4:0] instr;
    assign instr = cmd[4:0]; 
    
    // START Module definitions
    logic [31:0] f_add_sub_result;
    logic f_add_sub_should_subtract;
    floating_point_adder_subtracter f_adder_subtracter (
        .a(a),
        .b(b),
        .is_subtract(f_add_sub_should_subtract),
        .out(f_add_sub_result)
    );
           
    logic [31:0] b_float_inverted;
    floating_point_inverter inverter (
        .in(b),
        .out(b_float_inverted)
    );
    
    logic f_should_divide;
    logic [31:0] f_mult_div_result;
    floating_point_multiplier f_multiplier (
        .a(a),
        .b(f_should_divide ? b_float_inverted : b),
        .out(f_mult_div_result)
    );   
    // END module definitions
    
    // Use 'instr' to decide which submodule's output we assign to 'out'.

    always_comb
    begin
        f_add_sub_should_subtract = 0;
        f_should_divide = 0;
        
        if (instr == 5'h0)         
            out = a + b;
        else if (instr == 5'h1)
            out = a - b;
        else if (instr == 5'h2)            
            out = signed'(a) * signed'(b);
        else if (instr == 5'h3)
            out = unsigned'(a) * unsigned'(b);
        else if (instr == 5'h4)
            out = signed'(a) / signed'(b);
        else if (instr == 5'h5)
            out = unsigned'(a) / unsigned'(b);
        else if (instr == 5'h6)
            out = signed'(a) % signed'(b);
        else if (instr == 5'h7)
            out = -a;
        else if (instr == 5'h8) 
            out = a & b;
        else if (instr == 5'h9) 
            out = a | b;
        else if (instr == 5'ha) 
            out = a ^ b;
        else if (instr == 5'hb) 
            out = ~a;
        else if (instr == 5'hc) 
            out = a << b;
        else if (instr == 5'hd) 
            out = a >> b;
        else if (instr == 5'he) 
            out = a <<< b;
        else if (instr == 5'hf) 
            out = a >>> b;
        else if (instr == 5'h10) 
            out = (a << b) | (a >> (32 - b));
        else if (instr == 5'h11) 
            out = (a >> b) | ((((1 << b) - 1) & a) << (32 - b));               
        else if (instr == 5'h12) begin
            f_add_sub_should_subtract = 0;
            out = f_add_sub_result;        
        end
        else if (instr == 5'h13) begin
            f_add_sub_should_subtract = 1;
            out = f_add_sub_result;
        end
        else if (instr == 5'h14) begin
            f_should_divide = 0;
            out = f_mult_div_result;
        end
        else if (instr == 5'h15) begin
            f_should_divide = 1;
            out = f_mult_div_result;
        end
        else if (instr == 5'h16) begin
            out = {~a[31], a[30:0]};
        end
        else        
            out = 0;
    end    
endmodule
