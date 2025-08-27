module ReLU #(
    parameter BW = 32,
    parameter OUT = 128
)(
    input  wire signed [BW*OUT-1:0] gemv_output_i,
    output wire signed [BW*OUT-1:0] relu_output_o
);

    genvar i;
    generate
        for (i = 0; i < OUT; i = i + 1) begin : relu_block
            wire signed [BW-1:0] in_val;

            assign in_val = gemv_output_i[i*BW +: BW];
            assign relu_output_o[i*BW +: BW] = (in_val < 0) ? 0 : in_val;
        end
    endgenerate

endmodule
