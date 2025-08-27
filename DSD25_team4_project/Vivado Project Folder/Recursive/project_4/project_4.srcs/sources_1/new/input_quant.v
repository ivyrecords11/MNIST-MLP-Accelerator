module input_quant #(
    parameter BW_INPUT = 32,
    parameter Q_BW = 8
)(
    input  wire [Q_BW*64-1:0]     input_data_i,  
    output reg  [Q_BW*64-1:0]     input_data_o   // int8 출력
);

    integer i;
    reg [Q_BW-1:0] raw_input [63:0];
    reg [Q_BW-1:0] divided   [63:0];
    reg [Q_BW-1:0] rounded   [63:0];

    always @(*) begin
        for (i = 0; i < 64; i = i + 1) begin
            // 1) 추출
            raw_input[i] = input_data_i[i*Q_BW +: Q_BW];

            // 2) 2로 나누기
            divided[i] = raw_input[i] >> 1;

            // 3) 반올림: LSB가 1이면 0.5 존재 → +1
            if (raw_input[i][0] == 1'b1)
                rounded[i] = divided[i] + 1;
            else
                rounded[i] = divided[i];

            // 4) 클리핑 (127 제한)
            if (rounded[i] > 127)
                input_data_o[i*Q_BW +: Q_BW] = 127;
            else
                input_data_o[i*Q_BW +: Q_BW] = rounded[i];
        end
    end

endmodule
