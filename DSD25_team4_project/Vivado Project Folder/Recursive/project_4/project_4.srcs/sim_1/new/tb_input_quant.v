`timescale 1ns / 1ps

module tb_input_quant#(
    parameter BW_INPUT = 32,
    parameter Q_BW = 8
);
    
    reg  [Q_BW*4-1:0]     input_data_i;
    wire [Q_BW*4-1:0]     input_data_o;
    
    initial begin
        input_data_i = 32'hFEFE7F00;
        #10 $stop();
    end
    
    input_quant #(
        .BW_INPUT(BW_INPUT),
        .Q_BW(Q_BW)
    ) dut (
        .input_data_i(input_data_i),
        .input_data_o(input_data_o)
    );
endmodule
