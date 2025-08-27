`timescale 1ns / 1ps

/*module gemv_mac #(
parameter MAC_COUNT = 8,
parameter INPUT_LEN = 8,
parameter WEIGHT_LEN = 8,
parameter OUTPUT_LEN = 32
)(
input rstn_i,
input clear_i,
input clk_i,
input en_i,
input [MAC_COUNT*INPUT_LEN-1:0] din_i,
input [WEIGHT_LEN-1:0] win_i,
output reg [MAC_COUNT*OUTPUT_LEN-1:0] gemv_o
    );

    wire [OUTPUT_LEN-1:0] mac_outputs [MAC_COUNT-1:0];

    
    genvar i;
    generate 
        for (i = 0; i < MAC_COUNT; i=i+1) begin : gen_mac
            MAC mac_inst (
                .clk_i(clk_i),
                .rstn_i(rstn_i),
                .dsp_enable_i(en_i),
                .dsp_input_i(din_i[i*INPUT_LEN+:INPUT_LEN]),
                .dsp_weight_i(win_i),
                .dsp_output_o(mac_outputs[i]),
                .clear_i(clear_i)
    );
    end
endgenerate

integer j;
always @ (*) begin
    
    for(j = 0; j < MAC_COUNT; j = j+1) begin 
        gemv_o[(MAC_COUNT-j)*OUTPUT_LEN-1 -: OUTPUT_LEN] = mac_outputs[j];
    end
    end
    
endmodule*/

`timescale 1ns / 1ps

module gemv_mac #(
    parameter WEIGHT_LEN = 16, // weight의 열, MAC 개수
    parameter INPUT_BW = 16, // 한 데이터당 비트수
    parameter WEIGHT_BW = 16, // 한 데이터당 비트수
    parameter OUTPUT_BW = 32 // 한 데이터당 비트수
    )(
    input rstn_i,
    input clear_i,
    input clk_i,
    input en_i,
    input [INPUT_BW-1:0] din_i,
    input [WEIGHT_BW*WEIGHT_LEN-1:0] win_i,
    output[WEIGHT_LEN*OUTPUT_BW-1:0] gemv_o
    );
   
    wire [OUTPUT_BW-1:0] mac_outputs [WEIGHT_LEN-1:0];
   
    genvar j;
    generate 
            for (j = 0; j < WEIGHT_LEN; j=j+1) begin
                MAC #(
                .WEIGHT_LEN(WEIGHT_BW),
                .INPUT_LEN(INPUT_BW),
                .OUTPUT_LEN(OUTPUT_BW),
                .SUM(OUTPUT_BW-1)
                )mac_inst (
                    .clk_i(clk_i),
                    .rstn_i(rstn_i),
                    .dsp_enable_i(en_i),
                    .dsp_input_i(din_i),
                    .dsp_weight_i(win_i[j*WEIGHT_BW+:WEIGHT_BW]),//wbram에서 출력할 때부터 한 행씩 출력할 수 있게 코딩하기// 이거 되나
                    .dsp_output_o(mac_outputs[j]),
                    .clear_i(clear_i)
        );
        assign gemv_o[j*OUTPUT_BW +: OUTPUT_BW] = mac_outputs[j];
        end
    endgenerate
    /*
    integer k;
    always @ (*) begin
        for(k = 0; k < WEIGHT_LEN; k = k+1) begin 
            gemv_o[k*OUTPUT_BW +: OUTPUT_BW] <= mac_outputs[k];
        end
    end*/
    
endmodule




