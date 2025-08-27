`timescale 1ns / 1ps

module tb_top_mlp();
     reg                             clk;
     reg                             rst_n;
     reg                             start_i;
     
     wire                            done_intr_o;
     wire                            done_led_o;
     wire                            y_buf_en;
     wire                            y_buf_wr_en;
     wire [$clog2(400)-1:0]       y_buf_addr;
     wire [31:0]     y_buf_data;
            
     initial begin
     clk <= 0;
     rst_n <= 0;
     start_i <= 0;
     end
     
     initial begin
     # 10 rst_n <= 1;
     # 20 start_i <= 1;
     # 20 start_i <= 0;
     end
     
     always @ (*) begin
     #5 clk <= ~clk;
     end
     
     
     
    top_mlp dut(
    .clk           (clk),          
    .rst_n         (rst_n),        
    .start_i       (start_i),      
    .done_intr_o   (done_intr_o),  
    .done_led_o    (done_led_o),   
    .y_buf_en      (y_buf_en),     
    .y_buf_wr_en   (y_buf_wr_en),  
    .y_buf_addr    (y_buf_addr),   
    .y_buf_data    (y_buf_data)   
);
endmodule
