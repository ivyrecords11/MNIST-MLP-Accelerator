`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
//    input               clk_i,
//    input               rstn_i,
//    input               start_i,
//    input      [3:0]    done_i,
//    output reg [3:0]    start_o,
//    output reg [3:0]    clear_o,
//    output reg          done_o
//////////////////////////////////////////////////////////////////////////////////


module tb_glbl_ctrl();
    wire [3:0] start, clear;
    wire [3:0] done;
    reg clk, rstn, global_start;
    wire global_done;
    wire             x_en1,     x_en2,     x_en3,     x_en4;
    wire [1:0]     x_addr1,   x_addr2,   x_addr3,   x_addr4;
    wire             w_en1,     w_en2,     w_en3,     w_en4;
    wire [9:0]     w_addr1,   w_addr2,   w_addr3,   w_addr4;
    wire          save_en1,  save_en2,  save_en3,  save_en4;
    wire [9:0]  save_addr1,save_addr2,save_addr3,save_addr4;
    
    initial begin
        clk <= 0;
        rstn <= 0;
        global_start <= 0;
        
        #15 rstn <= 1;
        #10 global_start <= 1;
        #10 global_start <= 0;
        /*
        #50 done <= 4'b0001;
        #10 done <= 4'b0000;
        #50 done <= 4'b0011;
        #10 done <= 4'b0000;
        #50 done <= 4'b0111;
        #10 done <= 4'b0000;
        
        #50 done <= 4'b1111;
        #10 done <= 4'b0000;
        #50 done <= 4'b1111;
        #10 done <= 4'b0000;
        #20 done <= 4'b0010;        #30 done <= 4'b1111;
        #10 done <= 4'b0000;
        #50 done <= 4'b1111;
        #10 done <= 4'b0000;
        #50 done <= 4'b1111;
        #10 done <= 4'b0000;
        #50 done <= 4'b1111;
        #10 done <= 4'b0000;
        #50 done <= 4'b1111;
        #10 done <= 4'b0000;
        #50 done <= 4'b1111;
        #10 done <= 4'b0000;
        #50 done <= 4'b1111;
        #10 done <= 4'b0000;
        #50 done <= 4'b1111;
        #10 done <= 4'b0000;
        */
       
        
    end
    
    always@(*) begin
        #5 clk <= ~clk;
    end
    
    
    global_controller DUT(
    .clk_i(clk),       
    .rstn_i(rstn),      
    .start_i(global_start),     
    .done_i(done),      
    .start_o(start),     
    .clear_o(clear),     
    .done_o(global_done)       
    );
    
    loc_ctrl1 ctrl1(
    .clk_i(clk),
    .clear_i(clear[0]), //초기화
    .start_i(start[0]),
    .x_en(x_en1),
    .w_en(w_en1),
    .w_addr(w_addr1),
    .save_en(save_en1),    //저장 
    .save_addr(save_addr1),  //저장 주소
    .done(done[0])
    );
    
    loc_ctrl2 ctrl2(
    .clk_i(clk),
    .clear_i(clear[1]), //초기화
    .start_i(start[1]),
    .x_en(x_en2),
    .w_en(w_en2),
    .w_addr(w_addr2),
    .save_en(save_en2),    //저장 
    .save_addr(save_addr2),  //저장 주소
    .done(done[1])
    );
    
    loc_ctrl3 ctrl3(
    .clk_i(clk),
    .clear_i(clear[2]), //초기화
    .start_i(start[2]),
    //.valid_i(save_en2),
    //.x_en(x_en3),
    //.x_addr(x_addr3),
    .w_en(w_en3),
    .w_addr(w_addr3),
    .save_en(save_en3),    //저장 
    .done(done[2])
    );
    
    loc_ctrl4 ctrl4(
    .clk_i(clk),
    .clear_i(clear[3]), //초기화
    .start_i(start[3]),
    .x_en(x_en4),
    .x_addr(x_addr4),
    .w_en(w_en4),
    .w_addr(w_addr4),
    .save_en(save_en4),    //저장 
    .done(done[3])
    );
    
endmodule
