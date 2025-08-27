`timescale 1ns / 1ps

module gemv_adder_tree_old#(
    parameter N = 784,
    parameter IX = 1, //input width
    parameter IW = 16, //weight width
    parameter W = 16 // multiplied width
    )(
    input                   clk_i, 
    input                   clear_i,
    input [N*IX-1:0]        x_i,
    input [N*IW-1:0]        w_i,
    
    output reg signed [W+$clog2(N)-1:0] sum
    );
    
    localparam L = $clog2(N); // layer of tree
    
    wire    signed  [W+L-1:0] level_wire   [L:0][N-1:0]; // add bits for sum overflow
    reg     signed  [W+L-1:0] level_reg    [L:0][N-1:0]; // add bits for sum overflow
    reg    signed  [W-1:0]   temp [0:N-1];
    integer a, b, c;

    always @(posedge clk_i) begin
        if (clear_i) //synchronous clear
            for (a = 0; a < N ; a = a + 1) begin : INPUT_CLEAR
                level_reg[0][a] = 0;
            end
        else begin
            for (a = 0; a < N; a = a + 1) begin : INPUT_CONNECT
                if (IX==1) begin
                    temp[a] = x_i[a] ? $signed(w_i[a*IW+:IW]): 0;
                end else begin
                    temp[a] = $signed(x_i[a*IX+:IX]) * $signed(w_i[a*IW+:IW]);
                end
                level_reg[0][a] = { {L{temp[a][W-1]}}, temp[a] };
            end
        end
    end

    always @(posedge clk_i) begin
        if (clear_i) begin
            for (c = 0; c < L; c = c + 1) begin
                for (b = 0; b < (N >> (c+1)); b = b + 1) begin
                    level_reg[c+1][b] <= 0;
                end
            end
        end else begin
            for (c = 0; c < L; c = c + 1) begin : LEVELS_LOOP_ALWAYS
                if (c%2!=0) begin
                    for (b = 0; b < (N >> (c+1)); b = b + 1) begin : BRANCH
                        level_reg[c+1][b] <= $signed(level_wire[c][2*b]) + $signed(level_wire[c][2*b+1]);
                    end
                    
                    if ((c==0 & (N % 2 != 0)) || (c > 0 & ((N >> c)+((N>>c-1)%2 !=0)) % 2 != 0)) begin : PASS_THROUGH 
                        level_reg[c+1][N>>(c+1)] <= $signed(level_wire[c][(N>>c) -1]);
                    end
                    
                    else begin: NO_PASS_THROUGH // i = N >> l+1
                        level_reg[c+1][(N >> (c+1))] <= $signed(level_wire[c][2*(N >> (c+1))]) + $signed(level_wire[c][2*(N >> (c+1))+1]);
                    end
                end
            end
        end
    end
    
    
    genvar i, l;
    generate
        for (l = 0; l < L; l = l + 1) begin : LEVELS_LOOP
            for (i = 0; i < (N >> (l+1)); i = i + 1) begin : BRANCH 
                if (l%2==0) begin
                    assign level_wire[l+1][i] = $signed(level_reg[l][2*i]) + $signed(level_reg[l][2*i+1]);
                end
            end
            if ((l==0 & (N % 2 != 0)) || (l > 0 & ((N >> l)+((N>>l-1)%2 !=0)) % 2 != 0)) 
            begin : PASS_THROUGH
                assign level_wire[l+1][N>>(l+1)] = $signed(level_reg[l][(N>>l) -1]);
            end
            
            else begin: NO_PASS_THROUGH // i = N >> l+1
                assign level_wire[l+1][(N >> (l+1))] = $signed(level_reg[l][2*(N >> (l+1))]) + $signed(level_reg[l][2*(N >> (l+1))+1]);
            end
        end
    endgenerate
    
    
    always @(posedge clk_i) begin
        if (L%2==0)
            sum <= level_reg[L][0];
        else
            sum <= level_wire[L][0];
    end
endmodule
