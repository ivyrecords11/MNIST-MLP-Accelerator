`timescale 1ns / 1ps

module gemv_adder_tree#(
    parameter N = 12,
    parameter IX = 16, //input width
    parameter IW = 16, //weight width
    parameter W = 32 // multiplied width
    )(
    input                   clk_i, 
    input                   clear_i,
    input [N*IX-1:0]        x_i,
    input [N*IW-1:0]        w_i,
    
    output wire signed [W+$clog2(N)-1:0] sum
    );
    localparam L = $clog2(N);
    
    reg     signed  [W+L-1:0]   level_reg   [L:0]   [N-1:0] ;
    wire    signed  [W-1:0]     temp        [N-1:0]         ;
    
    
    
    assign sum = level_reg[L][0];
    
    genvar g;
    generate
        for (g = 0; g<N; g=g+1) begin
            if (IX == 1) begin //start or operation
                assign temp[g] = x_i[g] ? $signed(w_i[g*IW+:IW]) : 0;
            end else begin
                assign temp[g] = $signed(x_i[g*IX+:IX]) * $signed(w_i[g*IW+:IW]);
            end
        end
    endgenerate
    
    genvar b, l;
    integer a, c;
    generate
        // Level 0: load from temp[]
        for (l = 0; l < N; l = l + 1) begin : INPUT_STAGE
            always @(posedge clk_i) begin
                if (clear_i) level_reg[0][l] <= 0;
                else level_reg[0][l] <= temp[l];
            end
        end
    
        // Levels 1..L: adder tree
        for (b = 1; b <= L; b = b + 1) begin : TREE_LEVEL
            // compute how many nodes at this level
            localparam integer WIDTH_B = (N + (1<<b) - 1) >> b;
            always @(posedge clk_i) begin
                if (clear_i) begin
                    for (c = 0; c<N; c=c+1) begin
                        $display(a);
                        level_reg[b][c] <= 0;
                    end
                end else begin
                    for (a = 0; a < WIDTH_B; a = a + 1) begin : ADD_AND_REG
                        $display(a);
                        level_reg[b][a] <= level_reg[b-1][2*a] + level_reg[b-1][2*a + 1];
                    end
                end
            end
        end
    endgenerate
/*
    
    integer a, b;
    always @(posedge clk_i) begin
        if (clear_i) begin
            for (a = 0; a < N; a=a+1) begin : INPUT_0
                level_reg[0][a]<=0;
            end
        end else begin
            for (a = 0; a < N; a=a+1) begin : INPUT_CONNECT
                level_reg[0][a]<=temp[a];
            end
        end
    end
    
    
    integer level_width = N;
    
    localparam integer WIDTH_B = (N + (1<<b) - 1) >> b;

    always @(posedge clk_i) begin
    
        if(clear_i) begin
            for (b = 1; b < L+1; b=b+1) begin
                for (a = 0; a < N; a=a+1) begin : PROCESS_0
                    level_reg[b][a]<=0;
                end
            end
        end else begin
            for (b = 1; b < L+1; b=b+1) begin
                level_width <= (level_width + 1) >>> 1;
                for (a = 0; a < level_width; a=a+1) begin : PROCESS_ADD
                    level_reg[b][a]<=level_reg[b-1][2*a]+level_reg[b-1][2*a+1];
                end
            end
        end
    end
    */
endmodule
