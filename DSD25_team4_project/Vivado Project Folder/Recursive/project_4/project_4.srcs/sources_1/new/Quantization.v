module Quantization #(
    parameter BW = 32,
    parameter Q_BW = 8,
    parameter OUT = 128
)(
    input  wire                         clk,
    input  wire                         rst_n,
    input  wire [2:0]                   layer,
    input  wire signed [BW*OUT-1:0]     deq_output_i,
    output reg  signed [Q_BW*OUT-1:0]   pu_output_o
);

    // Internal data unpacked
    reg  signed [BW-1:0]      deq_elem   [OUT-1:0];
    reg  signed [2*BW-1:0]      scaled_val [OUT-1:0];
    reg  signed [2*Q_BW-1:0]  rounded    [OUT-1:0];
    reg  signed [Q_BW-1:0]    clipped    [OUT-1:0];

    integer i;

    // Step 1: Unpack input
    always @(posedge clk) begin
        for (i = 0; i < OUT; i = i + 1)
            deq_elem[i] <= deq_output_i[i*BW +: BW];
    end

    // Step 2: Scaling
    always @(posedge clk) begin
        for (i = 0; i < OUT; i = i + 1) begin
            case (layer)
                3'b001: scaled_val[i] <= (deq_elem[i] * 32'h002E_4E28);
                3'b010: scaled_val[i] <= (deq_elem[i] * 32'h0042_9F73);
                3'b011: scaled_val[i] <= (deq_elem[i] * 32'h0029_2DE1);
            default: scaled_val[i] <= 0;
            endcase
        end
    end

    // Step 3: Rounding
    always @(posedge clk) begin
        for (i = 0; i < OUT; i = i + 1) begin
            if (scaled_val[i] > 0)
                rounded[i] <= (scaled_val[i][47:16] + 32'h00008000) >>> 16;
            else if (scaled_val[i] == 0)
                rounded[i] <= scaled_val[i][47:16] >>> 16;
            else
                rounded[i] <= (scaled_val[i][47:!6] - 32'h00008000) >>> 16;
        end
    end

    // Step 4: Clipping
    always @(posedge clk) begin
        for (i = 0; i < OUT; i = i + 1) begin
            if (rounded[i] > 127)
                clipped[i] <= 8'sd127;
            else if (rounded[i] < -128)
                clipped[i] <= -8'sd128;
            else
                clipped[i] <= rounded[i][7:0];
        end
    end

    // Step 5: Output with reset (only necessary part)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < OUT; i = i + 1)
                pu_output_o[i*Q_BW +: Q_BW] <= 0;
        end else begin
            for (i = 0; i < OUT; i = i + 1)
                pu_output_o[i*Q_BW +: Q_BW] <= clipped[i];
        end
    end

endmodule
