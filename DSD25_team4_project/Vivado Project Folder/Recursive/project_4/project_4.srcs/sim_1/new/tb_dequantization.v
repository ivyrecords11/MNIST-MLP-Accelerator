`timescale 1ns/1ps

module tb_dequantization;

    parameter BW = 32;
    parameter OUT = 4;  // 테스트 간소화를 위해 4개만 사용

    reg clk;
    reg rst_n;
    reg  [2:0] layer;
    reg  signed [BW*OUT-1:0] relu_output_i;
    wire signed [BW*OUT-1:0] deq_output_o;

    integer i, j;

    // DUT (Device Under Test)
    Dequantization #(
        .BW(BW),
        .OUT(OUT)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .layer(layer),
        .relu_output_i(relu_output_i),
        .deq_output_o(deq_output_o)
    );

    // Clock generation: 10ns period
    initial clk = 0;
    always #5 clk = ~clk;

    initial begin
        $display("===== Start Dequantization Test =====");

        // Initialize inputs
        rst_n = 0;
        layer = 0;
        relu_output_i = 0;

        // Wait a bit then release reset
        #12;
        rst_n = 1;

        // 입력 설정 (Q16.16 format)
        relu_output_i[ 31:  0] = 32'h00040000;  // 4.0
        relu_output_i[ 63: 32] = 32'h00020000;  // 2.0
        relu_output_i[ 95: 64] = 32'h00010000;  // 1.0
        relu_output_i[127: 96] = 32'h00080000;  // 8.0

        // 각 layer별 테스트
        for (i = 1; i <= 3; i = i + 1) begin
            @(posedge clk);  // 입력 적용 시점
            layer = i[2:0];

            @(posedge clk);  // 연산 타이밍 대기
            @(posedge clk);  // 출력 반영 시점

            $display("\n=== Layer = %b ===", layer);
            for (j = 0; j < OUT; j = j + 1) begin
                $display("input[%0d]  = %h (%0f)", j, relu_output_i[j*BW +: BW],
                         $itor($signed(relu_output_i[j*BW +: BW])) / 65536.0);
                $display("output[%0d] = %h (%0f)", j, deq_output_o[j*BW +: BW],
                         $itor($signed(deq_output_o[j*BW +: BW])) / 65536.0);
            end
            $display("--------------------------");
        end

        $display("===== Test Done =====");
        $finish;
    end

endmodule
