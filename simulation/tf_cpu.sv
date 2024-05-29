`timescale 1ns / 1ps

module tf_cpu(
    );
   
    logic clk; 
    initial clk = 0;
    always #5 clk = ~clk;
    
    logic reset;
           
    cpu cpu (
        .clock_100mhz(clk),
        .reset(reset)
    );
    
    initial begin
        reset = 1;
        #12 reset = 0;
    end
    
endmodule
