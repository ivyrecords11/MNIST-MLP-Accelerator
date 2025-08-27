`timescale 1ns / 1ps

module slice#(
    parameter VEC_LEN = 128,
    parameter BW = 32,
    parameter SHIFT = 8
    )(
    input [BW*VEC_LEN-1:0] din,
    output [(BW-SHIFT)*VEC_LEN-1:0] dout
    );
    genvar i;
    generate 
        if (SHIFT == 0) begin
            assign dout = din;
        end else begin
            for (i=0;i<VEC_LEN;i=i+1) begin: slice
                assign dout[i*(BW-SHIFT) +: (BW-SHIFT)] = din [i*BW +: BW] >> SHIFT;
            end
        end
    endgenerate
endmodule
