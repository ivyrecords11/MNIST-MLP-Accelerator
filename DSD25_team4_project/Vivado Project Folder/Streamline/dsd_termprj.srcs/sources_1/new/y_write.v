module y_write(
    input               clk_i,
    input               rstn_i,
    input               start_i,
    input       [319:0] din,
    output reg  signed [31:0]  dout, 
    output reg          y_buf_en,    
    output reg          y_buf_wr_en, 
    output reg  [12:0] y_buf_addr,
    output reg          done
    );
    
    reg [$clog2(10)-1:0] cnt;
    reg [$clog2(10)-1:0] img_cnt;
    localparam IDLE = 3'b001,
                RUN = 3'b010,
               DONE = 3'b100;
    reg [3:0] present_state;
    
    always @(posedge clk_i) begin
        if (!rstn_i) begin
            present_state <= IDLE;
            {y_buf_addr, y_buf_en, y_buf_wr_en, dout, done} <= 0;
            cnt <= 0;
            img_cnt <= 0;
        end else begin
            case (present_state)
                IDLE: begin
                    if (start_i) begin
                        present_state <= RUN;
                        y_buf_addr      <= y_buf_addr;
                        y_buf_en        <= 0;
                        y_buf_wr_en     <= 0;
                        dout            <= 0;
                        cnt             <= 0;
                        img_cnt         <= img_cnt;
                        done            <= 0;
                    end else begin
                        present_state   <= present_state;
                        y_buf_addr      <= y_buf_addr;
                        y_buf_en        <= 0;
                        y_buf_wr_en     <= 0;
                        dout            <= 0;
                        cnt             <= 0;
                        img_cnt         <= img_cnt;
                        done            <= 0;
                    end
                end
                RUN: begin
                    if (cnt == 0) begin
                        present_state   <= present_state;
                        y_buf_addr      <= y_buf_addr;
                        y_buf_en        <= 1;
                        y_buf_wr_en     <= 1;
                        dout            <= $signed(din[cnt*16+:16]);//{{16*{din[cnt*16+15]}}, din[cnt*16+:16]};
                        cnt             <= cnt+1;
                        img_cnt         <= img_cnt;
                        done            <= 0;
                    end else if (cnt > 0 && cnt < 10) begin
                        present_state   <= present_state;
                        y_buf_addr      <= y_buf_addr + 4;
                        y_buf_en        <= 1;
                        y_buf_wr_en     <= 1;
                        dout            <= $signed(din[cnt*16+:16]);//{{16*{din[cnt*16+15]}}, din[cnt*16+:16]};
                        cnt             <= cnt+1;
                        img_cnt         <= img_cnt;
                        done            <= 0;
                    end else if (cnt == 10 && img_cnt < 9) begin
                        present_state   <= IDLE;
                        y_buf_addr      <= y_buf_addr + 4;
                        y_buf_en        <= 0;
                        y_buf_wr_en     <= 0;
                        dout            <= 0;
                        cnt             <= cnt;
                        img_cnt         <= img_cnt + 1;
                        done            <= 0;
                    end else if (cnt == 10 && img_cnt == 9) begin
                        present_state   <= DONE;
                        y_buf_addr      <= y_buf_addr;
                        y_buf_en        <= 0;
                        y_buf_wr_en     <= 0;
                        dout            <= 0;
                        cnt             <= cnt;
                        img_cnt         <= img_cnt;
                        done            <= 0;
                    end else begin
                        present_state   <= IDLE;
                        y_buf_addr      <= y_buf_addr;
                        y_buf_en        <= 0;
                        y_buf_wr_en     <= 0;
                        dout            <= 0;
                        cnt             <= 0;
                        img_cnt         <= img_cnt;
                        done            <= 0;
                    end
                end
                DONE: begin
                    present_state   <= DONE;
                    y_buf_addr      <= 0;
                    y_buf_en        <= 0;
                    y_buf_wr_en     <= 0;
                    dout            <= 0;
                    cnt             <= 0;
                    img_cnt         <= 0;
                    done            <= 1;
                end
            endcase
        end
    end
endmodule
