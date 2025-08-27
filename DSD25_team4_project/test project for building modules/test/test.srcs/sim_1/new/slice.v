`timescale 1ns / 1ps
module tb_slice();
    reg [37:0] a;
    wire [29:0] b;
    
    initial begin
        #10;
        a = 38'b00_0000_0000_0000_0000_0010_1101_0001_0001_0000;
        #10 $stop;
    end
    
    slice#(
    .VEC_LEN(1),
    .BW(38),
    .SHIFT(8)
    ) DUT(
    .din(a),
    .dout(b)
    );
endmodule
