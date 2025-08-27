module ReLU #(
    parameter BW = 32,
    parameter OUT = 128
)(
    input  wire [BW*OUT-1:0] gemv_output_i,
    output wire [BW*OUT-1:0] relu_output_o
);

    genvar i;
    generate
        for (i = 0; i < OUT; i = i + 1) begin : relu_block
            wire signed [BW-1:0] in_val;
            reg  signed [BW-1:0] out_val;

            assign in_val = $signed(gemv_output_i[i*BW +: BW]);

            always @(*) begin
                if (in_val[BW-1])
                    out_val = 0;
                else
                    out_val = in_val;
            end

            assign relu_output_o[i*BW +: BW] = out_val;
        end
    endgenerate

endmodule