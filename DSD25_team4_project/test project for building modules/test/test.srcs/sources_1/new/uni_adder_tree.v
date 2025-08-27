
module adder_branch #(
    parameter W = 16 //num. of inputs
    )(
    input                           clk_i,
    input                           clear_i,
    input           signed  [W-1:0] din_1, din_2,
    
    output  reg     signed  [W:0]   dout_o
    );
    always @(posedge clk_i or posedge clear_i) begin
        if (clear_i) begin
            dout_o <= 0;
        end
        else begin
            dout_o <= din_1+din_2;
        end
    end
endmodule