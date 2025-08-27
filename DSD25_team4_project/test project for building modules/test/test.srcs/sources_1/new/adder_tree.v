`timescale 1ns / 1ps
module adder_tree #(
    parameter N = 8,          // Number of inputs (must be power of 2 for this code)
    parameter W = 16           // Width of each input
) (
    input  wire [N*W-1:0] in, // Flattened input: concatenate all inputs
    output wire [W+$clog2(N)-1:0] sum // Output width grows with N
);

    // Internal wires for each level
    function integer log2;
        input integer value;
        integer i;
        begin
            log2 = 0;
            for(i = value-1; i > 0; i = i >> 1)
                log2 = log2 + 1;
        end
    endfunction

    // Generate adder tree
    localparam LEVELS = log2(N);

    // Array to hold values at each level
    wire [(LEVELS+1)*N*W-1:0] tree; // Flattened for simplicity

    // Assign input to level 0 of tree
    genvar i, l;
    generate
        for(i = 0; i < N; i = i + 1) begin : INPUT_ASSIGN
            assign tree[i*W +: W] = in[i*W +: W];
        end
        // Adder tree construction
        for(l = 0; l < LEVELS; l = l + 1) begin : LEVELS_LOOP
            for(i = 0; i < N >> (l+1); i = i + 1) begin : ADD_PAIRS
                assign tree[((l+1)*N + i)*W +: W] =
                    tree[(l*N + 2*i)*W +: W] + tree[(l*N + 2*i + 1)*W +: W];
            end
            // Pass through unused wires (if N is not power of 2, handle here)
        end
    endgenerate

    // Output assignment: last sum in the tree
    assign sum = tree[LEVELS*N*W +: W];

endmodule

/*
module adder_tree#(
    parameter N = 64,
    parameter M = 8 //$clog2(N)
    )(
    input [N-1:0] in,
    input clk_i,
    input en_i,
    input clear_i,
    
    output reg [N+M-1:0] result
    );
    integer c, i, j;
    reg [N-1:0] tmp [M-1:0];
    
    always @(posedge clk_i or posedge clear_i) begin
        if (clear_i) 
            for (c=0;c<M;c=c+1) begin
                tmp[c] <= 0;
            end
        end
        for (i=M; i>0; i=i-1) begin
            if (i==M) begin
                for (j==0; j<i; j=j+2) begin
                    {in[j+1:j]
                end
            end
            else begin
            end
        end
    end
endmodule
*/