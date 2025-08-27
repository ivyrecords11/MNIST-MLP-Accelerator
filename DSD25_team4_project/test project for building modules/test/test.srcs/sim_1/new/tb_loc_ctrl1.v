`timescale 1ns / 1ps

module tb_loc_ctrl1();
    reg clk, clear, start;

    wire                      x_en;
    //wire [1:0]                x_addr;
    wire                      w_en; 
    wire [$clog2(256):0] w_addr;
    wire                      save_en;
    wire [$clog2(256):0] save_addr;
    wire                      done;
    
    initial begin
        clk <= 0;
        clear <= 0;
        
        #15 clear <= 1;
        #15 clear <= 0;
        #20 start <= 1;
        #5000 $stop;
    end
    
    always @(*) begin
        #5 clk <= ~clk;
    end
    
    loc_ctrl2 DUT(
    .clk_i(clk),                    
    .clear_i(clear), //초기화            
    .start_i(start),                  
    .x_en(x_en),                     
    //.x_addr(x_addr),                   
    .w_en(w_en),                     
    .w_addr(w_addr),                   
    .save_en(save_en),    //저장          
    .save_addr(save_addr),  //저장 주소       
    .done(done)                      
    );
endmodule
