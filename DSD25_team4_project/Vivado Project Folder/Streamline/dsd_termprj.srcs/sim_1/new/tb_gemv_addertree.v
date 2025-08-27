`timescale 1ns / 1ps

module tb_gemv_adder_tree(
    //input clk,
    //input clear,
    //input ix, iw,
    //input [15*16-1:0] x,
    //input [15*16-1:0] w,
    //output reg [39:0] sum_o
    );
    reg clk, clear;

    reg [391:0] x = 392'h01_02_03_04_05_06_07_08_09_0a_0b_0c_0d_0e_0f_01_02_03_04_05_06_07_08_09;
    reg [391:0] w = 392'h01_ff_01_ff_01_ff_01_ff_01_ff_01_ff_01_ff_01_01_ff_01_ff_01_ff_01_ff_01;
    wire [11:0] sum;
    
    initial begin
        clk <= 0;
        clear <= 1;
        #15 clear <= 0;
        
        #150;
        $stop;
    end
    always begin
        #5 clk <= ~clk;
    end
    gemv_adder_tree#(
    .N(196),
    .IX(2),
    .IW(2),
    .W(4)
    ) DUT(
    .clk_i(clk), 
    .clear_i(clear),
    .x_i(x),
    .w_i(w),
    .sum(sum)
    );
endmodule
