`timescale 1ns / 1ps

module tb_Processing_Unit();

    parameter BW = 32;
    parameter OUT = 8;  // 테스트 용으로 작게 설정

    // Scaling factor parameters (Q16.16)
    parameter input_SF = 32'h00000204;
    parameter w_SF     = 32'h000001B4;
    parameter l1_SF    = 32'h0000058A;
    parameter w1_SF    = 32'h000001BD;
    parameter l2_SF    = 32'h000003DA;
    parameter w2_SF    = 32'h00000183;
    parameter l3_SF    = 32'h0000061C;
    parameter w3_SF    = 32'h000000AD;

    reg  [1:0] layer;
    reg  signed [BW*OUT-1:0] gemv_output_i;
    wire signed [BW*OUT-1:0] deq_output_o;

    // DUT 인스턴스
    Processing_Unit #(
        .BW(BW),
        .input_SF(input_SF),
        .w_SF(w_SF),
        .l1_SF(l1_SF),
        .w1_SF(w1_SF),
        .l2_SF(l2_SF),
        .w2_SF(w2_SF),
        .l3_SF(l3_SF),
        .w3_SF(w3_SF),
        .OUT(OUT)
    ) dut (
        .layer(layer),
        .gemv_output_i(gemv_output_i),
        .deq_output_o(deq_output_o)
    );

    initial begin
        $display("===== Start Processing_Unit Test =====");

        // Q16.16 값으로 큰 수 테스트 (예: 1.0 = 0x00010000, 2.0 = 0x00020000)
        layer = 2'b00;
        gemv_output_i = {
            32'hFFFF_0000, // -65536 →  -1.0
            32'h0001_0000, //  65536 →   1.0
            32'h0002_0000, // 131072 →   2.0
            32'h0004_0000, // 262144 →   4.0
            32'hFFFE_0000, //-131072 →  -2.0
            32'h0008_0000, // 524288 →   8.0
            32'h0006_0000, // 393216 →   6.0
            32'hFFFC_0000  //-262144 →  -4.0
        };
        #10;

        layer = 2'b01; #10;
        layer = 2'b10; #10;
        layer = 2'b11; #10;

        $display("===== Test Completed =====");
        $finish;
    end

    integer i;
    always @(*) begin
        $display("Layer %0d Output:", layer);
        for (i = 0; i < OUT; i = i + 1) begin
            $display("  [%0d] = %h", i, deq_output_o[i*BW +: BW]);
        end
    end

endmodule
