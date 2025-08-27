`timescale 1ns / 1ps
/*
CREF: Clip to FP16 range
if (layer_intermediate[i] > 32767)
    layer_intermediate[i] = 32767;
else if (layer_intermediate[i] < -32768)
    layer_intermediate[i] = -32768;
else
    layer_intermediate[i] = layer_intermediate[i];
*/

module clip#(
    parameter VEC_LEN = 128,
    parameter INPUTW = 32
    )(
    input [INPUTW*VEC_LEN-1:0] din,
    output reg [16*VEC_LEN-1:0] dout
    );
    integer i;
    always @(*) begin
        for (i=0;i<VEC_LEN;i=i+1) begin: CLIP_GEN
            if ($signed(din[i*INPUTW +: INPUTW]) > 32767) begin
                dout[i*16 +: 16] = 16'd32767;
            end else if ($signed(din[i*INPUTW +: INPUTW]) < -32768) begin
                dout[i*16 +: 16] = -16'd32768;
            end else begin
                dout[i*16 +: 16] = din[i*INPUTW +: INPUTW];
            end
        end
    end
endmodule
