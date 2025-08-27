`timescale 1ns / 1ps

module tb_ReLU;

    parameter BW = 32;
    parameter OUT = 4; // 간단히 4개로 테스트

    // 테스트용 신호
    reg [BW*OUT-1:0] gemv_output_i;
    wire [BW*OUT-1:0] relu_output_o;

    // DUT 인스턴스
    ReLU #(
        .BW(BW),
        .OUT(OUT)
    ) dut (
        .gemv_output_i(gemv_output_i),
        .relu_output_o(relu_output_o)
    );

    // 테스트 시나리오
    initial begin
        $display("==== ReLU Testbench ====");

        // 테스트 벡터 1: 음수, 양수 섞인 입력
        gemv_output_i = {
            $signed(-32'd10),  // [127:96]
            $signed(32'd15),   // [95:64]
            $signed(32'd0),    // [63:32]
            $signed(-32'd100)  // [31:0]
        };
        #10;
        $display("Input : %d %d %d %d", 
                 $signed(gemv_output_i[127:96]), 
                 $signed(gemv_output_i[95:64]), 
                 $signed(gemv_output_i[63:32]), 
                 $signed(gemv_output_i[31:0]));
        $display("Output: %d %d %d %d", 
                 $signed(relu_output_o[127:96]), 
                 $signed(relu_output_o[95:64]), 
                 $signed(relu_output_o[63:32]), 
                 $signed(relu_output_o[31:0]));

        // 테스트 벡터 2: 모두 양수
        gemv_output_i = {
            $signed(32'd5),
            $signed(32'd100),
            $signed(32'd200),
            $signed(32'd1)
        };
        #10;
        $display("Input : %d %d %d %d", 
                 $signed(gemv_output_i[127:96]), 
                 $signed(gemv_output_i[95:64]), 
                 $signed(gemv_output_i[63:32]), 
                 $signed(gemv_output_i[31:0]));
        $display("Output: %d %d %d %d", 
                 $signed(relu_output_o[127:96]), 
                 $signed(relu_output_o[95:64]), 
                 $signed(relu_output_o[63:32]), 
                 $signed(relu_output_o[31:0]));

        // 테스트 벡터 3: 모두 음수
        gemv_output_i = {
            $signed(-32'd5),
            $signed(-32'd100),
            $signed(-32'd200),
            $signed(-32'd1)
        };
        #10;
        $display("Input : %d %d %d %d", 
                 $signed(gemv_output_i[127:96]), 
                 $signed(gemv_output_i[95:64]), 
                 $signed(gemv_output_i[63:32]), 
                 $signed(gemv_output_i[31:0]));
        $display("Output: %d %d %d %d", 
                 $signed(relu_output_o[127:96]), 
                 $signed(relu_output_o[95:64]), 
                 $signed(relu_output_o[63:32]), 
                 $signed(relu_output_o[31:0]));

        $display("==== Test Finished ====");
        $finish;
    end

endmodule
