`timescale 1ns / 1ps

module binary_convt#(
    parameter X_BIT = 16,
    parameter X_LEN = 783
    )(
    input  [X_BIT*X_LEN-1:0] x_buf_data,       // 12543:0
    output [X_LEN-1:0]    convt_output
    );

    genvar i;
    generate
        for (i = 0; i < X_LEN; i = i + 1) begin : bin_conv
            assign convt_output[i] = |x_buf_data[i*X_BIT +: X_BIT];
        end
    endgenerate

endmodule