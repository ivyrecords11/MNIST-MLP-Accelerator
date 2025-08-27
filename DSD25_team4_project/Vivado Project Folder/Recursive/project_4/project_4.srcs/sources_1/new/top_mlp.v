module top_mlp #(
    parameter BW   = 32,
    parameter BW_INPUT = 16,
    parameter Q_BW = 8,
    parameter KERNEL = 28,
    parameter STRIDE = 12,
    parameter CONV1D_OUT = 64,
    parameter FC1_OUT = 128,
    parameter FC2_OUT = 64,
    parameter FC3_OUT = 10,
    parameter IN_IMG_NUM = 10,
    
    parameter X_ADDR = 5,
    parameter W_ADDR = 5,
    parameter W1_ADDR = 6,
    parameter W2_ADDR = 7,
    parameter W3_ADDR = 6,
    parameter OUT = 784,
    
    parameter Y_BUF_DATA_WIDTH = 32,
	parameter Y_BUF_ADDR_WIDTH = 32,
    parameter Y_BUF_DEPTH = 10*IN_IMG_NUM * 4				// we need to store data using byte addressing ( * 4 means byte addressing)
)(
    input wire clk,
    input wire rst_n,
    input wire start_i,

    output wire done_intr_o,
    output wire done_led_o,
    output  wire                            y_buf_en,
    output  wire                            y_buf_wr_en,
    output  wire [$clog2(Y_BUF_DEPTH)-1:0]  y_buf_addr,
    output  wire [Y_BUF_DATA_WIDTH-1:0]     y_buf_data
);

    wire pu_en, pu_clear, valid, prcss_done_gemv;
    wire [2:0] layer;
    wire [8:0] cnt_mac;
    wire all_done;

    wire signed [Q_BW-1:0] w_data;
    wire signed [Q_BW*128-1:0] w1_data;
    wire signed [Q_BW*64-1:0]  w2_data;
    wire signed [Q_BW*10-1:0]  w3_data;
    wire signed [Q_BW*128-1:0] temp_data;
    wire signed [Q_BW*128-1:0] temp_write_data;

    wire x_en, w_en, w1_en, w2_en, w3_en, temp_en, temp_wen;
    wire [X_ADDR-1:0] x_addr;
    wire [W_ADDR-1:0] w_addr;
    wire [W1_ADDR-1:0] w1_addr;
    wire [W2_ADDR-1:0] w2_addr;
    wire [W3_ADDR-1:0] w3_addr;
    wire               temp_addr;

    wire [Q_BW*64-1:0] input_data_bram;

    wire [Q_BW*64-1:0] quantized_input_data;
    
    input_quant #(
        .BW_INPUT(BW),
        .Q_BW(Q_BW)
    ) quant_inst (
        .input_data_i(input_data_bram),
        .input_data_o(quantized_input_data)
    );

    Processing_Unit #(
        .BW(BW),
        .Q_BW(Q_BW),
        .KERNEL(KERNEL),
        .STRIDE(STRIDE),
        .CONV1D_OUT(CONV1D_OUT),
        .FC1_OUT(FC1_OUT),
        .FC2_OUT(FC2_OUT),
        .FC3_OUT(FC3_OUT),
        .IN_IMG_NUM(IN_IMG_NUM),
        .Y_BUF_DATA_WIDTH(Y_BUF_DATA_WIDTH),
	    .Y_BUF_ADDR_WIDTH(Y_BUF_ADDR_WIDTH),
        .Y_BUF_DEPTH(Y_BUF_DEPTH)
    )processing_unit_inst (
        .clk_i(clk),
        .rstn_i(rst_n),
        .pu_en(pu_en),
        .pu_clear(pu_clear),
        .cnt_mac(cnt_mac),
        .layer(layer),
        .input_data(quantized_input_data),
        .w_data(w_data),
        .w1_data(w1_data),
        .w2_data(w2_data),
        .w3_data(w3_data),
        .temp_data(temp_data),
        .temp_write_data(temp_write_data),
        .prcss_done_gemv(prcss_done_gemv),
        .valid(valid),
        .y_buf_en(y_buf_en),
        .y_buf_wr_en(y_buf_wr_en),
        .y_buf_addr(y_buf_addr),
        .y_buf_data(y_buf_data),
        .all_done(all_done)
    );

    glbl_ctrl #(
        .X_ADDR(X_ADDR),
        .W_ADDR(W_ADDR),
        .W1_ADDR(W1_ADDR),
        .W2_ADDR(W2_ADDR),
        .W3_ADDR(W3_ADDR)
    ) glbl_ctrl_inst (
        .clk_i(clk),
        .rstn_i(rst_n),
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
        .valid(valid),
        .cnt_mac(cnt_mac),
        .prcss_done_gemv(prcss_done_gemv),
        .all_done(all_done)
    );

    single_port_bram #(
        .WIDTH(Q_BW*64),
        .DEPTH(28),
        .INIT_FILE("D:/02_Provided_Data/2_ref_mnist_testset_txt_per_pixel/1_label_2.txt")
    ) input_bram (
        .clk(clk), .en(x_en), .wen(1'b0), .addr(x_addr), .din(), .dout(input_data_bram)
    );

    single_port_bram #(
        .WIDTH(Q_BW),
        .DEPTH(28),
        .INIT_FILE("D:/02_Provided_Data/1_int8_weight_hex/int8_Conv1d_W_hex.txt")
    ) w_bram (
        .clk(clk), .en(w_en), .wen(1'b0), .addr(w_addr), .din(), .dout(w_data)
    );

    single_port_bram #(
        .WIDTH(Q_BW*128),
        .DEPTH(64),
        .INIT_FILE("D:/02_Provided_Data/w1.txt")
    ) w1_bram (
        .clk(clk), .en(w1_en), .wen(1'b0), .addr(w1_addr), .din(), .dout(w1_data)
    );

    single_port_bram #(
        .WIDTH(Q_BW*64),
        .DEPTH(128),
        .INIT_FILE("D:/02_Provided_Data/w2.txt")
    ) w2_bram (
        .clk(clk), .en(w2_en), .wen(1'b0), .addr(w2_addr), .din(), .dout(w2_data)
    );

    single_port_bram #(
        .WIDTH(Q_BW*10),
        .DEPTH(64),
        .INIT_FILE("D:/02_Provided_Data/w3.txt")
    ) w3_bram (
        .clk(clk), .en(w3_en), .wen(1'b0), .addr(w3_addr), .din(), .dout(w3_data)
    );

    single_port_bram #(
        .WIDTH(Q_BW*128),
        .DEPTH(2),
        .INIT_FILE("D:/02_Provided_Data/4_ref_int8_weight/int8_Linear_TEMP.txt")
    ) temp_bram (
        .clk(clk), .en(temp_en), .wen(temp_wen), .addr(temp_addr), .din(temp_write_data), .dout(temp_data)
    );

endmodule
