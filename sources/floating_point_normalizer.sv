`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06.05.2024 10:08:29
// Design Name: 
// Module Name: floating_point_normalizer
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module floating_point_normalizer(
    input logic [31:0] a,
    input logic [31:0] b,
    output logic [7:0] exp,
    output logic a_sign,
    output logic [23:0] a_mant,
    output logic b_sign,
    output logic [23:0] b_mant    
    );
    
    logic [7:0] a_exp_prenorm;
    logic [7:0] b_exp_prenorm;
    logic [23:0] a_mant_prenorm;
    logic [23:0] b_mant_prenorm;
    
    logic [6:0] shift;
    
    assign a_sign = a[31];
    assign b_sign = b[31];                
    
    always @(a, b) begin        
        a_exp_prenorm = a[30:23];
        b_exp_prenorm = b[30:23];
        a_mant_prenorm = {1, a[22:0]};  // TODO handle subnormal, zero, etc
        b_mant_prenorm = {1, b[22:0]};
        
        if (a_exp_prenorm >= b_exp_prenorm) begin
            shift = a_exp_prenorm - b_exp_prenorm;
            exp = a_exp_prenorm;
            a_mant = a_mant_prenorm;
            b_mant = b_mant_prenorm >>> shift;
        end
        else begin
            shift = b_exp_prenorm - a_exp_prenorm;
            exp = b_exp_prenorm;
            b_mant = b_mant_prenorm;
            a_mant = a_mant_prenorm >>> shift;        
        end
   end    
    
endmodule
