`timescale 1ns/1ps

module gemv_adder #(
    parameter    N  = 32,              // 입력 개수(2의 거듭제곱 가정)
    parameter    IX = 16,              // x_i  비트폭
    parameter    IW = 16,              // w_i  비트폭
    parameter    W  = IX + IW,         // 곱셈 결과 비트폭
    parameter    K  = 2                // 파이프라인 간격(2**K-to-1마다 FF)
)(
    input  wire                       clk_i,
    input  wire                       clear_i,   // high = sync-reset
    input  wire signed [N*IX-1:0]     x_i,
    input  wire signed [N*IW-1:0]     w_i,
    output reg  signed [W+$clog2(N)-1:0] sum_o    // 최종 합
);
    // 총 트리 레벨 수
    localparam L      = $clog2(N);
    localparam OUT_W  = W + L;                // 오버플로 방지

    /*------------------------------------------------------------
     * 0-stage : element-wise multiplication
     *-----------------------------------------------------------*/
    wire signed [OUT_W-1:0] stage [0:L][0:N-1];   // [레벨][노드]
    reg signed [OUT_W-1:0] stage_r [0:L][0:N-1];   // [레벨][노드]
    genvar gi;
    generate
        for (gi = 0; gi < N; gi = gi + 1) begin : GEN_MUL
            // 시그널 슬라이스
            wire signed [IX-1:0] x_seg =
                    x_i[IX*gi +: IX];
            wire signed [IW-1:0] w_seg =
                    w_i[IW*gi +: IW];

            // 곱셈 후 사인 확장해 stage[0][gi]에 연결
            assign stage[0][gi] = {{(OUT_W-W){(x_seg[IX-1]^w_seg[IW-1])}},
                                   x_seg * w_seg};
        end
    endgenerate

    /*------------------------------------------------------------
     * 트리 레벨별 Add + 선택적 파이프라인
     *-----------------------------------------------------------*/
    genvar lvl, idx;
    generate
        for (lvl = 0; lvl < L; lvl = lvl+1) begin : GEN_LEVEL
            localparam NUM_IN  = N >>  lvl;   // 이번 레벨 입력 수
            localparam NUM_OUT = N >> (lvl+1);// 다음 레벨 출력 수

            for (idx = 0; idx < NUM_OUT; idx = idx + 1) begin : GEN_NODE
                wire signed [OUT_W-1:0] add_res =
                        stage[lvl][2*idx] + stage[lvl][2*idx+1];

                // (lvl+1)번째 레벨이  K 의 배수일 때 레지스터 배치
                if ( ((lvl+1) % K) == 0 || (lvl == L-1) ) begin : PIPE
                    always @(posedge clk_i) begin
                        if (clear_i)
                            stage_r[lvl+1][idx] <= 0;
                        else
                            stage_r[lvl+1][idx] <= add_res;
                    end
                    assign stage[lvl+1][idx] = stage_r[lvl+1][idx];
                end
                else begin : COMB
                    assign stage[lvl+1][idx] = add_res;
                end
            end
        end
    endgenerate

    /*------------------------------------------------------------
     * 마지막 결과를 동기화
     *-----------------------------------------------------------*/
    always @(posedge clk_i) begin
        if (clear_i)
            sum_o <= 0;
        else
            sum_o <= stage[L][0];
    end
endmodule
