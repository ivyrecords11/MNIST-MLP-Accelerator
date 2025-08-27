`timescale 1ns / 1ps

module pass_through_branch#(
        parameter W = 16
    ) (
        input wire clk_i,
        input wire clear_i,
        input wire signed [W-1:0] in,
        output reg signed [W:0] out
    );
        always @(posedge clk_i or posedge clear_i) begin
            if (clear_i)
                out <= {(W+1){1'b0}};
            else
                out <= in;
        end
    endmodule