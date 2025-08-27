`timescale 1ns / 1ps


module pu #(
    parameter IN_X_BUF_DATA_WIDTH = 32,         // you should change if you try to design the int8 streamline architecture
    parameter IN_W_BUF_DATA_WIDTH = 32,         // you should change if you try to design the int8 streamline architecture
    parameter OUT_BUF_ADDR_WIDTH = 32,
    parameter OUT_BUF_DATA_WIDTH = 32

)(
    // system interface
    input   wire                            clk,
    input   wire                            rst_n,
    // global controller interface
    input   wire                            prcss_start,
    output  wire                            prcss_done,
    // input data buffer interface
    input   wire [IN_X_BUF_DATA_WIDTH-1:0]  x_buf_data,
    input   wire [IN_W_BUF_DATA_WIDTH-1:0]  w_buf_data,
    // output data buffer interface
    output  wire                            y_buf_en,
    output  wire                            y_buf_wr_en,
    output  wire [OUT_BUF_ADDR_WIDTH-1:0]   y_buf_addr,
    output  wire [OUT_BUF_DATA_WIDTH-1:0]   y_buf_data,
   output  wire all_done
);
    // Design your own logic!
    // It may contatin local controller, local buffer, quantizer, de-quantizer, and multiple PEs.    
   
    reg [15:0] l1_output [63:0];
    reg [15:0] l2_output [256:0];
    reg [15:0] l3_output [128:0];
    wire clear;
    wire [12543:0] x_buf_data_i;
    wire [783:0] convt_output;
    
    wire [3136:0] weight_layer1;
    wire [25:0] mul_1;
    wire [25:0] slice_1;
    wire [15:0] clip_1;
    wire [15:0] relu_1;
    wire [1024:0] l1_output_o;//1st layer
    
    wire [1023:0] weight_layer2;
    wire [37:0] mul_2;
    wire [29:0] slice_2;
    wire [15:0] clip_2;
    wire [15:0] relu_2;
    wire [4095:0] l2_output_o;//2nd layer
    
    wire [2047:0] weight_layer3;
    wire [4095:0] mul_3;
    wire [3071:0] slice_3;
    wire [2047:0] clip_3;
    wire [2047:0] relu_3;
    wire [2047:0] l3_output_o;//3rd layer
    
    wire [159:0] weight_layer4;
    wire [319:0] mul_4;
    wire [239:0] slice_4;
    wire [159:0] clip_4;
    wire [159:0] relu_4;
    wire [159:0] l4_output_o;//4th layer
    
    
    
    
    // 1st layer
    gemv_adder_tree#(
    .N(196),
    .IX(1), //input width
    .IW(16), //weight width
    .W(16) // multiplied width
    )gemv_adder_tree_1(
    .clk_i(clk), 
    .clear_i(clear),
    .x_i(convt_output),
    .w_i(weight_layer1),
    .sum(mul_1)
    );
    
    slice#(
    .VEC_LEN(1),
    .BW(26),
    .SHIFT(0)
    )slice_l1(
    .din(mul_1),
    .dout(slice_1)
    );
    
    clip#(
    .VEC_LEN(1),
    .INPUTW(26)
    )clip_l1(
    .din(slice_1),
    .dout(clip_1)
    );

    ReLU #(
    .R_BW(16),
    .OUT(1)
    )ReLU_1(
    .gemv_output_i(clip_1),
    .relu_output_o(l1_output_o)
    );
   
    
    // 2nd layer
    gemv_adder_tree#(
    .N(64),
    .IX(16), //input width
    .IW(16), //weight width
    .W(32) // multiplied width
    )gemv_adder_tree_2(
    .clk_i(clk), 
    .clear_i(clear),
    .x_i(l1_output_o),
    .w_i(weight_layer2),
    .sum(mul_2)
    );
    
     slice#(
    .VEC_LEN(1),
    .BW(38),
    .SHIFT(8)
    )slice_l2(
    .din(mul_2),
    .dout(slice_2)
    );
    
    clip#(
    .VEC_LEN(1),
    .INPUTW(30)
    )clip_l2(
    .din(slice_2),
    .dout(clip_2)
    );
    
     ReLU #(
    .R_BW(16),
    .OUT(1)
    )ReLU_2(
    .gemv_output_i(clip_2),
    .relu_output_o(l2_output_o)
    );
    
    // 3rd layer
    gemv_mac #(
     .INPUT_LEN(1),//INPUT 배열 수
     .INPUT_BW(16), // 한 데이터당 비트수
     .WEIGHT_LEN(128), // weight의 열, MAC 개수
     .WEIGHT_BW(16), // 한 데이터당 비트수
     .OUTPUT_BW(32), // 한 데이터당 비트수
     .MODE(0) //layer3에선 0, layer4에선 1
     )
     gemv_mac_3(
    .rstn_i(),
    .clear_i(clear),
    .clk_i(clk),
    .en_i(),
    .din_i(l2_output_o),
    .win_i(weight_layer3),
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
    .R_BW(16),
    .OUT(128)
    )ReLU_3(
    .gemv_output_i(clip_3),
    .relu_output_o(l3_output_o)
    );
    
    
    
   // 4th layer  
     gemv_mac #(
     .INPUT_LEN(128),//INPUT 배열 수
     .INPUT_BW(8), // 한 데이터당 비트수
     .WEIGHT_LEN(128), // weight의 열, MAC 개수
     .WEIGHT_BW(8), // 한 데이터당 비트수
     .OUTPUT_BW(32), // 한 데이터당 비트수
     .MODE(1) //layer3에선 0, layer4에선 1
     )gemv_mac_4(
    .rstn_i(),
    .clear_i(clear),
    .clk_i(clk),
    .en_i(),
    .din_i(l3_output_o),
    .win_i(weight_layer4),
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
    .dout(clip_4)
    );
    
     ReLU #(
    .R_BW(16),
    .OUT(10)
    )ReLU_4(
    .gemv_output_i(clip_4),
    .relu_output_o(l4_output_o)
    );
    
genvar i, j, k;
generate
    for (i = 0; i < 64; i = i + 1) begin : layer1_flattened
        assign l1_output_o[i * 16 +: 16] =  l1_output[i];
    end
endgenerate

generate
    for (j = 0; j < 256; j = j + 1) begin : layer2_flattend
        assign l2_output_o[j * 16 +: 16] =  l2_output[j];
    end
endgenerate

generate
    for (k = 0; k < 128; k = k + 1) begin : layer3_flattend
        assign l3_output_o[k * 16 +: 16] =  l3_output[k];
    end
endgenerate

endmodule
