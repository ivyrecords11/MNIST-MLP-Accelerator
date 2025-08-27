module Dequantization #(
    parameter BW = 32,
    /*parameter input_SF = 32'h00000204,  //0.0078735
    parameter w_SF     = 32'h000001B4,  //0.0066528
    parameter l1_SF    = 32'h0000058A,  //0.0216522
    parameter w1_SF    = 32'h000001BD,  //0.0067902
    parameter l2_SF    = 32'h000003DA,  //0.0150452
    parameter w2_SF    = 32'h00000183,  //0.0059052
    parameter l3_SF    = 32'h0000061C,  //0.0238647
    parameter w3_SF    = 32'h000000AD,  //0.0026398*/
    parameter OUT      = 128
)(
    input  wire clk,
    input  wire rst_n,
    input  wire [2:0] layer,
    input  wire signed [BW*OUT-1:0] relu_output_i,
    output reg  signed [BW*OUT-1:0] deq_output_o
);
    
    
    integer i;
    reg signed [BW-1:0] relu_elem [OUT-1:0];
    reg signed [2*BW-1:0] mul_result [OUT-1:0];
    reg signed [BW-1:0] deq_result [OUT-1:0];

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < OUT; i = i + 1) begin
                relu_elem[i]    <= 0;
                mul_result[i]   <= 0;
                deq_result[i]   <= 0;
                deq_output_o[i*BW +: BW] <= 0;
            end
        end else begin
            for (i = 0; i < OUT; i = i + 1) begin
                relu_elem[i]  <= relu_output_i[i*BW +: BW];
                case (layer)
                    3'b001: mul_result[i] <= relu_elem[i] * 32'h0000_0003;
                    3'b010: mul_result[i] <= relu_elem[i] * 32'h0000_000A;
                    3'b011: mul_result[i] <= relu_elem[i] * 32'h0000_0006;
                    default: mul_result[i] <= relu_elem[i] * 32'h0000_0004;
                endcase
                deq_result[i] <= mul_result[i][31:0];
                deq_output_o[i*BW +: BW] <= deq_result[i];
            end
        end
    end

endmodule