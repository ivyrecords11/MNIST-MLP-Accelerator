`timescale 1ns / 1ps
//1st layer using tree addition. 786 -> 64
module PU_L1 #(
    parameter TREEDELAY =  //1024 = 2^10 = 2^5*2
    )(
        
    );
    wire reg_addr;
    
    gemv_adder_tree a
    
    loc_ctrl1 ctrl_layer1(
        .clk_i(clk_i),
        .rstn_i(rstn_i),
        .
        .reg_addr_o(reg_addr)
        );
    relu relu1();
        
endmodule