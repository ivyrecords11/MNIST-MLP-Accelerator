`timescale 1ns / 1ps

module tb_quantization();

    parameter BW = 32;
    parameter Q_BW = 8;
    parameter OUT = 8;

    // Scaling factor (Q16.16 ¿ª¼ö °ª)
    parameter REVERSED_l1_SF = 32'h002E_33C7;
    parameter REVERSED_l2_SF = 32'h0042_7F0E; 
    parameter REVERSED_l3_SF = 32'h0029_361E; 
    
    reg clk;
    reg rst_n;
    reg [2:0] layer;
    reg signed [BW*OUT-1:0] deq_output_i;
    wire signed [Q_BW*OUT-1:0] pu_output_o;

    Quantization #(
        .BW(BW),
        .REVERSED_l1_SF(REVERSED_l1_SF),
        .REVERSED_l2_SF(REVERSED_l2_SF),
        .REVERSED_l3_SF(REVERSED_l3_SF),
        .Q_BW(Q_BW),
        .OUT(OUT)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .deq_output_i(deq_output_i),
        .layer(layer),
        .pu_output_o(pu_output_o)
    );
    
    // Clock generation: 10ns period
    initial clk = 0;
    always #5 clk = ~clk;
    
    integer i;

    initial begin
        $display("===== Quantization Testbench Start =====");
        rst_n = 0;
        #10 rst_n = 1;
        // Test Layer 1 (3'b001)
        layer = 3'b001;
       deq_output_i = {
    32'h00080000, // 8.0
    32'h00040000, // 4.0
    32'h00020000, // 2.0
    32'h00010000, // 1.0
    32'h00000000, // 0.0
    32'hFFFF0000, // -1.0
    32'hFFFC0000, // -4.0
    32'hFFF80000  // -8.0
};
        #30;
        print_output("Layer 1");

        // Test Layer 2 (3'b010)
        layer = 3'b010;
        #30;
        print_output("Layer 2");

        // Test Layer 3 (3'b001)
        layer = 3'b011;
        #30;
        print_output("Layer 3");
        #30;
        $display("===== Quantization Testbench Complete =====");
        $finish;
    end

    task print_output(input [127:0] label);
        begin
            $display("--- %s ---", label);
            for (i = 0; i < OUT; i = i + 1) begin
                $display("  [%0d] = %0d", i, $signed(pu_output_o[i*Q_BW +: Q_BW]));
            end
        end
    endtask

endmodule
