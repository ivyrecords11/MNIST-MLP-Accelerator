`timescale 1ns / 1ps

module tb_glbl_ctrl#(
    parameter X_ADDR = 10,
    parameter W_ADDR = 5,
    parameter W1_ADDR = 7,
    parameter W2_ADDR = 6,
    parameter W3_ADDR = 4,
    parameter TEMP_ADDR = 7
);

    reg                        clk_i;
    reg                        rstn_i;
    reg                        start_i;
    
    wire                        done_intr_o;
    wire                        done_led_o;
    
    wire                        x_en;
    wire  [X_ADDR-1:0]          x_addr;
    wire                        w_en;
    wire  [W_ADDR-1:0]          w_addr;
    wire                        w1_en;
    wire  [W1_ADDR-1:0]         w1_addr;
    wire                        w2_en;
    wire  [W2_ADDR-1:0]         w2_addr;
    wire                        w3_en;
    wire  [W3_ADDR-1:0]         w3_addr;
    wire                        temp_en;
    wire                        temp_wen;
    wire  [TEMP_ADDR-1:0]       temp_addr;
    wire                        pu_en;
    wire                        pu_clear;
    wire  [2:0]                 layer;
    reg                        prcss_done_gemv;
    
    always begin
        #5 clk_i = ~clk_i; // Blocking assignment를 사용하여 순차적인 클럭 토글
    end
    
    /*test layer 1
    initial begin
        clk_i <= 0; rstn_i <= 1; start_i <= 0; prcss_done_gemv <= 0;
        #10 rstn_i <= 0;
        #10 rstn_i <= 1;
        #20 start_i <= 1;
        #10 start_i <= 0;
        #100000 $stop;
    end*/
    
    /*test layer 2
    initial begin
        clk_i <= 0; rstn_i <= 1; start_i <= 0; prcss_done_gemv <= 0;
        #10 rstn_i <= 0;
        #10 rstn_i <= 1;
        #15 start_i <= 1;
        #10 start_i <= 0;
        prcss_done_gemv <= 1;
        #10 prcss_done_gemv <= 0;
        #100000 $stop;
    end */
    
    //test layer 3 & layer 4 & DONE
    initial begin
        clk_i <= 0; rstn_i <= 1; start_i <= 0; prcss_done_gemv <= 0;
        #10 rstn_i <= 0;
        #10 rstn_i <= 1;
        #15 start_i <= 1;
        #10 start_i <= 0;
        prcss_done_gemv <= 1;
        #10 prcss_done_gemv <= 0;
        #10 prcss_done_gemv <= 1;
        #10 prcss_done_gemv <= 0;
        #650 prcss_done_gemv <= 1;
        #10 prcss_done_gemv <= 0;
        #120 prcss_done_gemv <= 1;
        #10 prcss_done_gemv <= 0;
        #1000 $stop;
    end
    
    
    glbl_ctrl #(
   .X_ADDR(X_ADDR),
   .W_ADDR(W_ADDR),
   .W1_ADDR(W1_ADDR),
   .W2_ADDR(W2_ADDR),
   .W3_ADDR(W3_ADDR),
   .TEMP_ADDR(TEMP_ADDR)
)inst_glbl_ctrl(
    .clk_i(clk_i),
    .rstn_i(rstn_i),
    .start_i(start_i),
    .done_intr_o(done_intr_o),
    .done_led_o(done_led_o),
    .x_en(x_en),
    .x_addr(x_addr),
    .w_en(w_en),
    .w_addr(w_addr),
    .w1_en(w1_en),
    .w1_addr(w1_addr),
    .w2_en(w2_en),
    .w2_addr(w2_addr),
    .w3_en(w3_en),
    .w3_addr(w3_addr),
    .temp_en(temp_en),
    .temp_wen(temp_wen),
    .temp_addr(temp_addr),
    .pu_en(pu_en),
    .pu_clear(pu_clear),
    .layer(layer),
    .prcss_done_gemv(prcss_done_gemv)
);

    
endmodule
