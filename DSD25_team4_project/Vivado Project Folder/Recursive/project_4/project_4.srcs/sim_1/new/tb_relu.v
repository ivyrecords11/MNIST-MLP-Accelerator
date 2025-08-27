`timescale 1ns / 1ps

module tb_ReLU;

    parameter BW = 32;
    parameter OUT = 4; // ������ 4���� �׽�Ʈ

    // �׽�Ʈ�� ��ȣ
    reg [BW*OUT-1:0] gemv_output_i;
    wire [BW*OUT-1:0] relu_output_o;

    // DUT �ν��Ͻ�
    ReLU #(
        .BW(BW),
        .OUT(OUT)
    ) dut (
        .gemv_output_i(gemv_output_i),
        .relu_output_o(relu_output_o)
    );

    // �׽�Ʈ �ó�����
    initial begin
        $display("==== ReLU Testbench ====");

        // �׽�Ʈ ���� 1: ����, ��� ���� �Է�
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

        // �׽�Ʈ ���� 2: ��� ���
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

        // �׽�Ʈ ���� 3: ��� ����
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
