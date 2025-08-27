
// clk delay L/2 -> L로 수정


module gemv_adder_tree#(
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
    
    reg     signed  [W+L-1:0] level_reg    [L:0][N-1:0]; // add bits for sum overflow
    wire   signed  [W-1:0]   temp [0:N-1];
    integer a, b, c;
    genvar g;
    generate 
        for (g = 0; g < N; g = g + 1) begin
            if (IX==1) begin
                assign temp[g] = x_i[g] ? $signed(w_i[g*IW+:IW]): 0;
            end else begin
                assign temp[g] = $signed(x_i[g*IX+:IX]) * $signed(w_i[g*IW+:IW]);
            end
        end
    endgenerate
    always @(posedge clk_i) begin
        if (clear_i) //synchronous clear
            for (a = 0; a < N ; a = a + 1) begin : INPUT_CLEAR
                level_reg[0][a] <= 0;
            end
        else begin
            for (a = 0; a < N; a = a + 1) begin : INPUT_CONNECT
                level_reg[0][a] <= { {L{temp[a][W-1]}}, temp[a] };
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
                        level_reg[c+1][b] <= $signed(level_reg[c][2*b]) + $signed(level_reg[c][2*b+1]);
                    end
                    
                    if ((c==0 & (N % 2 != 0)) || (c > 0 & ((N >> c)+((N>>c-1)%2 !=0)) % 2 != 0)) begin : PASS_THROUGH 
                        level_reg[c+1][N>>(c+1)] <= $signed(level_reg[c][(N>>c) -1]);
                    end
                    
                    else begin: NO_PASS_THROUGH // i = N >> l+1
                        level_reg[c+1][(N >> (c+1))] <= $signed(level_reg[c][2*(N >> (c+1))]) + $signed(level_reg[c][2*(N >> (c+1))+1]);
                    end
                end
            end
        end
    end
    
    
    integer l, i;
    always @(posedge clk_i) begin
        for (l = 0; l < L; l = l + 1) begin : LEVELS_LOOP
            for (i = 0; i < (N >> (l+1)); i = i + 1) begin : BRANCH 
                if (l%2==0) begin
                level_reg[l+1][i] = $signed(level_reg[l][2*i]) + $signed(level_reg[l][2*i+1]);
                end
            end
            if ((l==0 & (N % 2 != 0)) || (l > 0 & ((N >> l)+((N>>l-1)%2 !=0)) % 2 != 0)) begin : PASS_THROUGH
                level_reg[l+1][N>>(l+1)] = $signed(level_reg[l][(N>>l) -1]);
            end
            
            else begin: NO_PASS_THROUGH // i = N >> l+1
                level_reg[l+1][(N >> (l+1))] <= $signed(level_reg[l][2*(N >> (l+1))]) + $signed(level_reg[l][2*(N >> (l+1))+1]);
            end
        end
    end
    
    
    always @(posedge clk_i) begin
            sum <= level_reg[L][0];
    end
endmodule
