`timescale 1ns / 1ps

module top_mlp #(
    parameter IN_IMG_NUM = 10,
	parameter FP_BW = 16,
	parameter INT_BW = 8,
	// parameter X_BUF_DATA_WIDTH = INT_BW,  				// if you try INT8 recursive, you should change X_BUF_DATA_WIDTH to this line
	parameter X_BUF_DATA_WIDTH = 3136,
	parameter X_BUF_DEPTH = 4*IN_IMG_NUM,
	
	parameter W1_BUF_DATA_WIDTH = 3136,
	parameter W1_BUF_DEPTH = 4*64,
	parameter W2_BUF_DATA_WIDTH = 1024,
	parameter W2_BUF_DEPTH = 256,
	parameter W3_BUF_DATA_WIDTH = 2048,
	parameter W3_BUF_DEPTH = 256,
	parameter W4_BUF_DATA_WIDTH = 160,
	parameter W4_BUF_DEPTH = 128,							// just example
	// parameter W2_BUF_DEPTH = .. ,
	// parameter W3_BUF_DEPTH = .. ,	
	
	
	/*************DO NOT MODIFY THESE PARAMETERS	*****************/
    parameter Y_BUF_DATA_WIDTH = 32,
	parameter Y_BUF_ADDR_WIDTH = 32,
    parameter Y_BUF_DEPTH = 10*IN_IMG_NUM * 4				// we need to store data using byte addressing ( * 4 means byte addressing)
	/*************DO NOT MODIFY THESE PARAMETERS	*****************/
)(
	/*************DO NOT MODIFY THESE I/O PORTS	*****************/
    // system interface
    input   wire                            clk,
    input   wire                            rst_n,
    input   wire                            start_i,
    output  wire                            done_intr_o,
    output  wire                            done_led_o,
    // output buffer interface
    output  wire                            y_buf_en,
    output  wire                            y_buf_wr_en,
    output  wire [$clog2(Y_BUF_DEPTH)-1:0]  y_buf_addr,
    //output  wire [31:0]  y_buf_addr,
    output  wire [Y_BUF_DATA_WIDTH-1:0]     y_buf_data
	/*************DO NOT MODIFY THESE I/O PORTS	*****************/
);
    //need to change directory
    localparam X_BUF_INIT_FILE  =  "C:/Users/ivyre/OneDrive/Desktop/00_RTL_Skeleton/dsd_termprj.srcs/sources_1/new/1_flat_label_2.mem";
    localparam W1_BUF_INIT_FILE =  "C:/Users/ivyre/OneDrive/Desktop/00_RTL_Skeleton/dsd_termprj.srcs/sources_1/new/fixed_point_W1_flat_3136_t_F.mem";
    localparam W2_BUF_INIT_FILE =  "C:/Users/ivyre/OneDrive/Desktop/00_RTL_Skeleton/dsd_termprj.srcs/sources_1/new/fixed_point_W2_flat_1024_t_F.mem";
    localparam W3_BUF_INIT_FILE =  "C:/Users/ivyre/OneDrive/Desktop/00_RTL_Skeleton/dsd_termprj.srcs/sources_1/new/fixed_point_W3_flat_2048_t_T.mem";
    localparam W4_BUF_INIT_FILE =  "C:/Users/ivyre/OneDrive/Desktop/00_RTL_Skeleton/dsd_termprj.srcs/sources_1/new/fixed_point_W4_flat_160_t_T.mem";
    
    wire x_buf_en;
    wire [$clog2(X_BUF_DEPTH)-1:0] x_buf_addr;
    wire [X_BUF_DATA_WIDTH-1:0] x_buf_data;
    wire                            w1_buf_en;
    wire [$clog2(W1_BUF_DEPTH)-1:0] w1_buf_addr;
    wire [W1_BUF_DATA_WIDTH-1:0]      w1_buf_data;
    wire                            w2_buf_en;
    wire [$clog2(W2_BUF_DEPTH)-1:0] w2_buf_addr;
    wire [W2_BUF_DATA_WIDTH-1:0]      w2_buf_data;
    wire                            w3_buf_en;
    wire [$clog2(W3_BUF_DEPTH)-1:0] w3_buf_addr;
    wire [W3_BUF_DATA_WIDTH-1:0]      w3_buf_data;
    wire                            w4_buf_en;
    wire [$clog2(W4_BUF_DEPTH)-1:0] w4_buf_addr;
    wire [W4_BUF_DATA_WIDTH-1:0]      w4_buf_data;
    
    wire [3:0]  prcss_start;
    wire [3:0]  prcss_done;
    
    wire [$clog2(IN_IMG_NUM)-1:0] img_cnt;
    wire [$clog2(IN_IMG_NUM)-1:0] input_cnt;
    wire [3:0] local_clear;
    
    glbl_ctrl #(
        .IMG_NUM(IN_IMG_NUM)
    ) glbl_ctrl_inst(
        // system interface
        .clk_i(clk),
        .rstn_i(rst_n),
        .start_i(start_i),
        .done_o(),
        .img_cnt(img_cnt),
        .input_cnt(input_cnt),
        .done_i(prcss_done),   
        .start_o(prcss_start),  
        .clear_o(local_clear)
    );
	
	
    pu #(
        .OUT_BUF_ADDR_WIDTH($clog2(Y_BUF_DEPTH)),
        .OUT_BUF_DATA_WIDTH(Y_BUF_DATA_WIDTH)
    ) pu_inst(
        // system interface
        .clk(clk),
        .rst_n(rst_n),
        // global controller interface
        .prcss_start(prcss_start),
        .prcss_clear(local_clear),   
        .prcss_done(prcss_done),
        // output data buffer interface
        .img_cnt(input_cnt),
        .y_buf_en(y_buf_en),
        .y_buf_wr_en(y_buf_wr_en),
        .y_buf_addr(y_buf_addr),
        .y_buf_data(y_buf_data),
        .x_buf_data(x_buf_data),
        .w1_buf_data(w1_buf_data),
        .w2_buf_data(w2_buf_data),
        .w3_buf_data(w3_buf_data),
        .w4_buf_data(w4_buf_data),
        
        .x_en1(x_buf_en),
        .x_addr1(x_buf_addr),       
        .w_en1(w1_buf_en),         
        .w_addr1(w1_buf_addr),         
        .w_en2(w2_buf_en),         
        .w_addr2(w2_buf_addr),         
        .w_en3(w3_buf_en),         
        .w_addr3(w3_buf_addr),         
        .w_en4(w4_buf_en),         
        .w_addr4(w4_buf_addr),      
        
        .all_done(done_intr_o)       
    );
    assign done_led_o = done_intr_o;

    single_port_bram  #(
        .WIDTH(X_BUF_DATA_WIDTH),
        .DEPTH(X_BUF_DEPTH),
        .INIT_FILE("1_flat_label_2.mem")
    ) x_buffer_inst (
        .clk(clk),
        .en(x_buf_en),
        //.wen(),
        .addr(x_buf_addr),
        //.din(),
        .dout(x_buf_data)
    );
    
    single_port_bram  #(
        .WIDTH(W1_BUF_DATA_WIDTH),
        .DEPTH(W1_BUF_DEPTH),
        .INIT_FILE(W1_BUF_INIT_FILE)
    ) w1_buffer_inst (
        .clk(clk),
        .en(w1_buf_en),
        //.wen(),
        .addr(w1_buf_addr),
        //.din(),
        .dout(w1_buf_data)
    );
    
    single_port_bram  #(
        .WIDTH(W2_BUF_DATA_WIDTH),
        .DEPTH(W2_BUF_DEPTH),
        .INIT_FILE(W2_BUF_INIT_FILE)
    ) w2_buffer_inst (
        .clk(clk),
        .en(w2_buf_en),
        //.wen(),
        .addr(w2_buf_addr),
        //.din(),
        .dout(w2_buf_data)
    );
    
    single_port_bram  #(
        .WIDTH(W3_BUF_DATA_WIDTH),
        .DEPTH(W3_BUF_DEPTH),
        .INIT_FILE(W3_BUF_INIT_FILE)
    ) w3_buffer_inst (
        .clk(clk),
        .en(w3_buf_en),
        //.wen(),
        .addr(w3_buf_addr),
        //.din(),
        .dout(w3_buf_data)
    );
    
    single_port_bram  #(
        .WIDTH(W4_BUF_DATA_WIDTH),
        .DEPTH(W4_BUF_DEPTH),
        .INIT_FILE(W4_BUF_INIT_FILE)
    ) w4_buffer_inst (
        .clk(clk),
        .en(w4_buf_en),
        //.wen(),
        .addr(w4_buf_addr),
        //.din(),
        .dout(w4_buf_data)
    );
    
endmodule
