module Processing_Unit #(
    parameter BW   = 32,
    parameter Q_BW = 8,
    parameter KERNEL = 28,
    parameter STRIDE = 12,
    parameter CONV1D_OUT = 64,
    parameter FC1_OUT = 128,
    parameter FC2_OUT = 64,
    parameter FC3_OUT = 10,
    parameter IN_IMG_NUM = 10,
    
    parameter Y_BUF_DATA_WIDTH = 32,
	parameter Y_BUF_ADDR_WIDTH = 32,
    parameter Y_BUF_DEPTH = 10*IN_IMG_NUM * 4
)(
    input  wire clk_i,
    input  wire rstn_i,
    input  wire pu_en,
    input  wire pu_clear,
    input  wire valid,
    input  wire [8:0] cnt_mac,
    input  wire [2:0] layer,

    input  wire        [Q_BW*64-1:0] input_data,
    input  wire signed [Q_BW-1:0] w_data,
    input  wire signed [Q_BW*128-1:0] w1_data,
    input  wire signed [Q_BW*64-1:0] w2_data,
    input  wire signed [Q_BW*10-1:0]  w3_data,
    input  wire signed [Q_BW*128-1:0] temp_data,

    output wire prcss_done_gemv,
    output wire signed [Q_BW*128-1:0] temp_write_data,
    
    output  wire                            y_buf_en,
    output  wire                            y_buf_wr_en,
    output  wire [$clog2(Y_BUF_DEPTH)-1:0]  y_buf_addr,
    output  wire [Y_BUF_DATA_WIDTH-1:0]     y_buf_data,
    output  wire                            all_done
);

    wire signed [BW-1:0] mac_results [127:0];
    // Internal wires
    wire signed [BW*128-1:0] mac_results_wire;
    wire signed [BW*128-1:0] relu_results_wire;
    wire signed [BW*128-1:0] deq_results_wire;

    // Registers between stages
    reg signed [BW*128-1:0] mac_results_reg;
    reg signed [BW*128-1:0] relu_results_reg;
    reg signed [BW*128-1:0] deq_results_reg;
    reg signed [Q_BW*128-1:0] pu_output_reg;
    
    //Y_BUFFER
    reg [$clog2(Y_BUF_DEPTH)-1:0]  r_y_buf_addr;
    reg [Y_BUF_DATA_WIDTH-1:0]     r_y_buf_data;
    
    reg [8:0] count;
    
    always@ (posedge clk_i or negedge rstn_i) begin
        if(!rstn_i)
            count <= 0;
        else begin
            if(cnt_mac == 8'd128)
                count <= 0;
            else
                count <= cnt_mac;    
        end
    end
    
    // Pipeline stage 1: MACs
    genvar i;
    generate
    for (i = 0; i < 128; i = i + 1) begin : GEN_MAC
        wire dsp_enable;
        wire [Q_BW-1:0] dsp_input;
        wire [Q_BW-1:0] dsp_weight;
    
        assign dsp_enable = pu_en && (
            (layer == 3'b001 && i < CONV1D_OUT) ||
            (layer == 3'b010) || 
            (layer == 3'b011 && i < FC2_OUT) ||
            (layer == 3'b100 && i < FC3_OUT)
        );
        
        assign dsp_input = (layer == 3'b001) ? ((i < CONV1D_OUT) ? input_data[i*Q_BW+:Q_BW] : {Q_BW{1'b0}}) :
                           (layer == 3'b010) ? ((count < FC1_OUT) ? temp_data[count*Q_BW+:Q_BW] : {Q_BW{1'b0}}) :
                           (layer == 3'b011) ? ((count < FC2_OUT) ? temp_data[count*Q_BW+:Q_BW] : {Q_BW{1'b0}}) :
                           (layer == 3'b100) ? ((count < FC3_OUT) ? temp_data[count*Q_BW+:Q_BW] : {Q_BW{1'b0}}) :
                           {Q_BW{1'b0}};
    
        assign dsp_weight = (layer == 3'b001) ? w_data :
                            (layer == 3'b010) ? ((i < FC1_OUT) ? w1_data[i*Q_BW +: Q_BW] : {Q_BW{1'b0}}) :
                            (layer == 3'b011) ? ((i < FC2_OUT) ? w2_data[i*Q_BW +: Q_BW] : {Q_BW{1'b0}}) :
                            (layer == 3'b100) ? ((i < FC3_OUT) ? w3_data[i*Q_BW +: Q_BW] : {Q_BW{1'b0}}) :
                            {Q_BW{1'b0}};
    
        MAC #(.BW(BW), .Q_BW(Q_BW)) mac_inst (
            .clk_i(clk_i),
            .rstn_i(rstn_i),
            .pu_clear(pu_clear),
            .dsp_enable_i(dsp_enable),
            .dsp_input_i(dsp_input),
            .dsp_weight_i(dsp_weight),
            .dsp_output_o(mac_results[i])
        );
        
        assign mac_results_wire[i*BW +: BW] = mac_results[i];
    
    end
    endgenerate
    
    
    reg  [319:0] output_y;
    reg          write_start;
    wire [319:0] write_flat;
    
    always@ (posedge clk_i) begin
        if(layer == 3'b100 && prcss_done_gemv) begin
            write_start <= 1;
            output_y <= mac_results_wire[319:0];
        end else begin
            write_start <= 0;
            output_y <= output_y;
        end
    end
    
    assign write_flat = output_y;
    
     y_write Y_WRITE(
    .clk_i(clk_i),    
    .rstn_i(rstn_i),   
    .start_i(write_start),  
    .din(write_flat),      
    .dout(y_buf_data),     
    .y_buf_en(y_buf_en), 
    .y_buf_wr_en(y_buf_wr_en),
    .y_buf_addr(y_buf_addr),
    .done(all_done)
    );


    // Register: MAC -> ReLU
    always @(posedge clk_i or negedge rstn_i) begin
        if (!rstn_i)
            mac_results_reg <= 0;
        else if (pu_clear)
            mac_results_reg <= mac_results_wire;
    end

    // ReLU
    ReLU #(.BW(BW), .OUT(128)) relu_inst (
        .gemv_output_i(mac_results_reg),
        .relu_output_o(relu_results_wire)
    );

    // Register: ReLU -> Dequantization
    always @(posedge clk_i or negedge rstn_i) begin
        if (!rstn_i)
            relu_results_reg <= 0;
        else if (pu_en)
            relu_results_reg <= relu_results_wire;
    end

    // Dequantization
    Dequantization #(
        .BW(BW), .OUT(128)
    ) deq_inst (
        .clk(clk_i),
        .rst_n(rstn_i),
        .layer(layer),
        .relu_output_i(relu_results_reg),
        .deq_output_o(deq_results_wire)
    );

    // Register: Dequantization -> Quantization
    always @(posedge clk_i or negedge rstn_i) begin
        if (!rstn_i)
            deq_results_reg <= 0;
        else if (pu_en)
            deq_results_reg <= deq_results_wire;
    end

    // Quantization
    Quantization #(
        .BW(BW), .Q_BW(Q_BW), .OUT(128)
    ) quant_inst (
        .clk(clk_i),
        .rst_n(rstn_i),
        .deq_output_i(deq_results_reg),
        .layer(layer),
        .pu_output_o(temp_write_data)
    );
    
    // Register: Quantization -> Output
    always @(posedge clk_i or negedge rstn_i) begin
        if (!rstn_i)
            pu_output_reg <= 0;
        else if (pu_en)
            pu_output_reg <= temp_write_data;
    end
    
    reg delay1, delay2, delay3, delay4, delay5, delay6, delay7, delay8, delay9, delay10, delay11, delay12;
    
    always@ (posedge clk_i or negedge rstn_i) begin
        if(!rstn_i) begin
            delay1 <= 0; delay2 <= 0; delay3 <= 0; delay4 <= 0; delay5 <= 0; delay6 <= 0; delay7 <= 0; delay8 <= 0; delay9 <= 0; delay10 <= 0; delay11 <= 0; delay12 <= 0;
        end
        else begin
            delay1 <= valid; delay2 <= delay1; delay3 <= delay2; delay4 <= delay3; delay5 <= delay4; delay6 <= delay5; delay7 <= delay6; delay8 <= delay7;
            delay9 <= delay8; delay10 <= delay9; delay11 <= delay10; delay12 <= delay11;
        end
    end
    
    assign prcss_done_gemv = (delay12) ? 1 : 0;

endmodule