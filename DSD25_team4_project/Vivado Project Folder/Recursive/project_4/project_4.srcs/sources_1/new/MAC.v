module MAC#(
    parameter BW = 32,
    parameter Q_BW = 8
)(
 input       wire                                clk_i,
 input       wire                                rstn_i,
 input       wire                                pu_clear,
 input       wire                                dsp_enable_i,
 input       wire        signed      [Q_BW-1:0]       dsp_input_i,
 input       wire        signed      [Q_BW-1:0]       dsp_weight_i,
 output      wire        signed      [BW-1:0]      dsp_output_o
 );
 
 reg         signed      [30:0]       partial_sum;
 
 always @(posedge clk_i or negedge rstn_i) begin
    if(!rstn_i) begin
     partial_sum <= 0;
    end
    else begin
        if (pu_clear) begin
         partial_sum <= 0;
        end
        else begin
         partial_sum <= dsp_output_o[30:0];
        end
    end
 end

 dsp_macro_0 DSP_for_MAC(
 .CLK(clk_i),  // input wire CLK
 .CE(dsp_enable_i),    // input wire CE
 .SCLR(pu_clear),
 .A(dsp_input_i),      // input wire [7 : 0] A
 .B(dsp_weight_i),      // input wire [7 : 0] B
 .C(partial_sum),      // input wire [30 : 0] C
 .P(dsp_output_o)      // output wire [31 : 0] P
 );
 endmodule
