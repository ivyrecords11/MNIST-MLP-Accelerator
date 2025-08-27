module pu #(
    parameter X_BUF_DATA_WIDTH   = 3136,
    parameter W1_BUF_DATA_WIDTH   = 3136,
    parameter W2_BUF_DATA_WIDTH   = 1024,
    parameter W3_BUF_DATA_WIDTH   = 2048,
    parameter W4_BUF_DATA_WIDTH   = 160,
    parameter OUT_BUF_ADDR_WIDTH = 13,
    parameter OUT_BUF_DATA_WIDTH = 32
)(
    // system interface
    input   wire                            clk,
    input   wire                            rst_n,
    // global controller interface
    input   wire                     [3:0]  prcss_start,
    input   wire                     [3:0]  prcss_clear,
    output  wire                     [3:0]  prcss_done,
    // input data buffer interface
    input   wire [3:0]                      img_cnt,
    input   wire [X_BUF_DATA_WIDTH-1:0]     x_buf_data,
    input   wire [W1_BUF_DATA_WIDTH-1:0]    w1_buf_data,
    input   wire [W2_BUF_DATA_WIDTH-1:0]    w2_buf_data,
    input   wire [W3_BUF_DATA_WIDTH-1:0]    w3_buf_data,
    input   wire [W4_BUF_DATA_WIDTH-1:0]    w4_buf_data,
    // output data buffer interface
    output wire                             x_en1,
    output wire [7:0]                       x_addr1,
    output wire                             w_en1,
    output wire [$clog2(256):0]             w_addr1,
    output wire                             w_en2,
    output wire [$clog2(256):0]             w_addr2,
    output wire                             w_en3,
    output wire [$clog2(256):0]             w_addr3,
    output wire                             w_en4,
    output wire [$clog2(128):0]             w_addr4,
    
    output  wire                            y_buf_en,
    output  wire                            y_buf_wr_en,
    output  wire [OUT_BUF_ADDR_WIDTH-1:0]   y_buf_addr,
    output  wire [OUT_BUF_DATA_WIDTH-1:0]   y_buf_data,
    output  wire                            all_done
);
    
    
    // Design your own logic!
    // It may contatin local controller, local buffer, quantizer, de-quantizer, and multiple PEs.    
    wire [195:0] convt_output;
    
    //loc_ctrl1
    wire save_en1;
    wire [$clog2(256):0] save_addr1;
    //loc_ctrl2
    wire x_en2;
    wire save_en2;
    //loc_ctrl3
    wire save_en3;
    //loc_ctrl4
    wire  x_en4;
    wire [$clog2(128):0] x_addr4;
    wire save_en4;
    
    //1st layer
    wire signed [23:0] mul_1;
    wire signed [15:0] clip_1;
    wire [1023:0] l1_output_f;
    wire [1023:0] l1_output_o;
    //2st layer
    wire [37:0] mul_2;
    wire [29:0] slice_2;
    wire [15:0] clip_2;
    wire [15:0] l2_output_o;
    //3rd layer
    wire mac_clear3;
    wire [4095:0] mul_3;
    wire [3071:0] slice_3;
    wire [2047:0] clip_3;
    wire [2047:0] l3_output_o;
    //4th layer
    wire [319:0] mul_4;
    wire [239:0] slice_4;
    wire [159:0] l4_output_o;
    
    
    // binary converter
    binary_convt#(
    .X_BIT(16),
    .X_LEN(196)
    )binary_convt(
    .x_buf_data(x_buf_data),       // 3135:0
    .convt_output(convt_output)
    );
    
    //////////////////////////////// 1st layer /////////////////////////////
    loc_ctrl1#(.CYCLES(64*4), .TREE_DELAY(10), .SAVE_DELAY(5)
    )layer1(
    .clk_i(clk),
    .clear_i(prcss_clear[0]),
    .start_i(prcss_start[0]),
    .img_cnt_i(img_cnt),
    .x_en(x_en1),
    .x_addr(x_addr1),
    .w_en(w_en1),
    .w_addr(w_addr1),
    .save_en(save_en1),
    .save_addr(save_addr1),
    .done(prcss_done[0])
    );
    
    gemv_adder_tree#(.N(196),   .IX(1),     .IW(16),    .W(16))
    gemv_adder_tree_1(
    .clk_i(clk), 
    .clear_i(prcss_clear[0]),
    .x_i(convt_output),
    .w_i(w1_buf_data),
    .sum(mul_1)
    );
    
    clip#(.VEC_LEN(1), .INPUTW(24))
    clip_l1(
    .din(mul_1),
    .dout(clip_1)
    );
    //we have to change this
    
    reg signed [15:0] l1_output [63:0];
    integer b;
    //work in progress
    // layer1 write
    always @ (posedge clk) begin
        if (!rst_n) begin
            for (b = 0; b<64; b=b+1) begin
                l1_output[b] <= 0;
            end
        end else begin
            if (prcss_clear[0]) begin
                for (b = 0; b<64; b=b+1) begin
                    l1_output[b] <= 0;
                end
            end else if(save_en1) begin
                l1_output[save_addr1>>2] <= l1_output[save_addr1>>2] + clip_1;
            end else begin
                 l1_output[save_addr1>>2] <= l1_output[save_addr1>>2];
            end
        end
     end
        
     // layer1 flatten
     genvar i;
     generate
         for (i =0; i<64; i=i+1) begin : layer1_flatten
             assign l1_output_f[i * 16 +: 16] =  l1_output[i];
         end
     endgenerate
  
    ReLU#(.BW(16), .OUT(64))
    ReLU_1(
    .gemv_output_i(l1_output_f),
    .relu_output_o(l1_output_o)
    );
    
    reg [1023:0] output_reg_1;
    
    always @(posedge clk) begin
        if (!rst_n) begin
            output_reg_1 <= 0;
        end else if (prcss_done[0]) begin
            output_reg_1 <= l1_output_o;
        end else begin
            output_reg_1 <= output_reg_1;
        end
    end
     
    
    //////////////////////////////// 2nd layer /////////////////////////////
    
    loc_ctrl2#(
    .CYCLES(256), .TREE_DELAY(9) //64 = 2^6
    )layer2(
    .clk_i(clk),
    .clear_i(prcss_clear[1]), //초기화
    .start_i(prcss_start[1]),
    .x_en(x_en2),
    .w_en(w_en2),
    .w_addr(w_addr2),
    .save_en(save_en2),    //저장 
    .done(prcss_done[1])
    );

    
    
    gemv_adder_tree#(
    .N(64),
    .IX(16), //input width
    .IW(16), //weight width
    .W(32) // multiplied width
    )gemv_adder_tree_2(
    .clk_i(clk), 
    .clear_i(prcss_clear[1]),
    .x_i(output_reg_1),
    .w_i(w2_buf_data),
    .sum(mul_2)
    );
    
    slice#(.VEC_LEN(1), .BW(38), .SHIFT(7)
    )slice_l2(
    .din(mul_2),
    .dout(slice_2)
    );
    
    clip#(.VEC_LEN(1), .INPUTW(30)
    )clip_l2(
    .din(slice_2),
    .dout(clip_2)
    );
    
     ReLU #(.BW(16), .OUT(1)
    )ReLU_2(
    .gemv_output_i(clip_2),
    .relu_output_o(l2_output_o)
    );
        
    //////////////////////////////// 3rd layer ///////////////////////////// 
    loc_ctrl3#(
    .CYCLES(256),
    .L2_PRE_DELAY(7),
    .SAVE_DELAY(2)
    )layer3(
    .clk_i(clk),
    .clear_i(prcss_clear[2]), //초기화
    .start_i(prcss_start[2]),
    .mac_clear(mac_clear3),
    .w_en(w_en3),
    .w_addr(w_addr3),
    .save_en(save_en3),
    .done(prcss_done[2])
    );

    
    
    gemv_mac #(
    .WEIGHT_LEN(128),
    .INPUT_BW(16),
    .WEIGHT_BW(16), 
    .OUTPUT_BW(32) 
    )gemv_mac_3(
    .rstn_i(1),
    .clear_i(mac_clear3),
    .clk_i(clk),
    .en_i(1), //임시값
    .din_i(l2_output_o),
    .win_i(w3_buf_data),
    .gemv_o(mul_3)
    );
    
     slice#(
    .VEC_LEN(128),
    .BW(32),
    .SHIFT(8)
    )slice_l3(
    .din(mul_3),
    .dout(slice_3)
    );
    
    clip#(
    .VEC_LEN(128),
    .INPUTW(24)
    )clip_l3(
    .din(slice_3),
    .dout(clip_3)
    );
    
     ReLU #(
    .BW(16),
    .OUT(128)
    )ReLU_3(
    .gemv_output_i(clip_3),
    .relu_output_o(l3_output_o)
    );    
    
    reg [15:0]   output_reg_3 [127:0];
    integer j;
    
    always @(posedge clk) begin
        if (!rst_n) begin
            for(j = 0; j<128; j = j + 1) begin
                output_reg_3[j] <= 'bx;
            end
        end
        if (save_en3) begin
            for(j = 0; j<128; j = j + 1) begin : layer3_part_selection
                output_reg_3[j] <= l3_output_o[j*16+:16];
            end
        end else begin
            for(j = 0; j<128; j = j + 1) begin
                output_reg_3[j] <= output_reg_3[j];
            end
        end 
    end
    
    //timing modification
    reg [15:0] l4_input_reg;
    always @(posedge clk) begin
        l4_input_reg <= (x_en4) ? output_reg_3[x_addr4] : {15*{1'b0}};
    end
    
    wire [15:0] l4_input;
    assign l4_input = l4_input_reg;
    
    //////////////////////////////// 4th layer /////////////////////////////
    loc_ctrl4#(
    .CYCLES(128), .SAVE_DELAY(1)      // same as depth
    )layer4(
    .clk_i(clk),
    .clear_i(prcss_clear[3]), //초기화
    .start_i(prcss_start[3]),
    .x_en(x_en4),
    .x_addr(x_addr4),
    .w_en(w_en4),
    .w_addr(w_addr4),
    .save_en(save_en4),
    .done(prcss_done[3])
    );

     
     gemv_mac #(
     .WEIGHT_LEN(10),
     .INPUT_BW(16),
     .WEIGHT_BW(16), 
     .OUTPUT_BW(32) 
     )gemv_mac_4
    (
    .rstn_i(1),
    .clear_i(prcss_clear[3]),
    .clk_i(clk),
    .en_i(1), //임시값
    .din_i(l4_input),
    .win_i(w4_buf_data),
    .gemv_o(mul_4)
    );
    
     slice#(
    .VEC_LEN(10),
    .BW(32),
    .SHIFT(8)
    )slice_l4(
    .din(mul_4),
    .dout(slice_4)
    );
    
    clip#(
    .VEC_LEN(10),
    .INPUTW(24)
    )clip_l4(
    .din(slice_4),
    .dout(l4_output_o)
    );
    reg [159:0] output_reg_4;
    reg         write_start;
    wire [159:0] write_flat;
    
    always @(posedge clk) begin
        if (save_en4) begin
            write_start <= 1;
            output_reg_4 <= l4_output_o;
        end else begin
            write_start <= 0;
            output_reg_4 <= output_reg_4;
        end
    end
    
    assign write_flat = output_reg_4;
    
    y_write Y_WRITE(
    .clk_i(clk),    
    .rstn_i(rst_n),   
    .start_i(write_start),  
    .din(write_flat),      
    .dout(y_buf_data),     
    .y_buf_en(y_buf_en), 
    .y_buf_wr_en(y_buf_wr_en),
    .y_buf_addr(y_buf_addr),
    .done(all_done)
    );
    
endmodule