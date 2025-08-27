`timescale 1ns / 1ps

module tb_clip();
    reg [24*4-1:0] x_in; //24*4
    wire [16*4-1:0] x_out;
    
    initial begin
        #10 x_in = 96'h000000_000001_000004_00000e;
        #10 x_in = 96'h000100_010001_010000_00ffff;
        #10 $stop;
    end
    
    clip#(
    .VEC_LEN(4),
    .INPUTW(24)
    ) DUT(
    .din(x_in),
    .dout(x_out)
    );
endmodule
