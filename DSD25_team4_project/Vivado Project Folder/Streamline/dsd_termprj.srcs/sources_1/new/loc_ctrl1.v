`timescale 1ns / 1ps

//CONTROLER FOR 1ST ADDER TREE
/*
clk_i           clock                  
clear_i         clear = negative reset
start_i         start signal       
x_en            x buffer enable
x_addr          x input address
w_en            w bram enable
w_addr          w bram address
save_en         output save signal  
save_addr       output save address -> 0~256, pu에서 64개씩 더하기
done            output done signal
*/

module loc_ctrl1#(
    parameter CYCLES = 256,     // same as depth
    parameter TREE_DELAY = 5,    //256 = 2^8
    parameter SAVE_DELAY = 5
    )(
    input                           clk_i,
    input                           clear_i, //초기화
    input                           start_i,
    input      [3:0]                img_cnt_i,
    output reg                      x_en,
    output reg [7:0]                x_addr,
    output reg                      w_en,
    output reg [$clog2(CYCLES):0] w_addr,
    output reg                      save_en,    //저장 
    output reg [$clog2(CYCLES):0] save_addr,  //저장 주소
    output reg                      done
    );
    
    localparam IDLE = 3'b001,
               RUN  = 3'b010,
               DONE = 3'b100;
               
    reg [2:0] present_state, next_state;
    reg [$clog2(CYCLES+TREE_DELAY):0] cnt;
    
    //present_state
    always @(posedge clk_i) begin
        present_state <= clear_i ? IDLE : next_state;
    end
    //next_state
    always @(*) begin
        case (present_state)
            IDLE : next_state = start_i ? RUN  : IDLE;
            RUN  : next_state = done    ? DONE : RUN;
            DONE : next_state = clear_i ? IDLE : DONE;
            default: next_state = IDLE; 
        endcase
    end

    always @(posedge clk_i) begin
        // 초기화
        if (clear_i) begin
            {done, x_en, x_addr, w_en, w_addr, save_en, save_addr, cnt} <= 0;
        end
        else begin
            case (present_state)
                IDLE: begin
                    {done, x_en, x_addr, w_en, w_addr, save_en, save_addr, cnt} <= 0;
                end
                RUN: begin
                    if          (cnt == 0) begin
                        done    <= 0;
                        x_en    <= 1;   x_addr      <= 0 + img_cnt_i*4;
                        w_en    <= 1;   w_addr      <= 0;
                        save_en <= 0;   save_addr   <= 0;
                        cnt     <= cnt + 1;
                    end else if (cnt > 0 && cnt<TREE_DELAY) begin
                        done    <= 0;
                        x_en    <= 1;   x_addr      <= cnt%4 + img_cnt_i*4;
                        w_en    <= 1;   w_addr      <= w_addr + 1;
                        save_en <= 0;   save_addr   <= 0;
                        cnt     <= cnt+1;
                    end else if (cnt == TREE_DELAY) begin //64로 나누었을 때 
                        done    <= 0;
                        x_en    <= 1;   x_addr      <= cnt%4 + img_cnt_i*4;
                        w_en    <= 1;   w_addr      <= w_addr + 1;
                        save_en <= 1;   save_addr   <= 0;
                        cnt     <= cnt+1;
                    end else if (cnt > TREE_DELAY && cnt < 1*(CYCLES>>2)) begin //64로 나누었을 때 
                        done    <= 0;
                        x_en    <= 1;   x_addr      <= cnt%4 + img_cnt_i*4;
                        w_en    <= 1;   w_addr      <= w_addr + 1;
                        save_en <= 1;   save_addr   <= save_addr + 1;
                        cnt     <= cnt+1;
                    end else if (cnt>= 1*(CYCLES>>2) && cnt < 2*(CYCLES>>2)) begin //128로 나누었을 때 
                        done    <= 0;
                        x_en    <= 1;   x_addr      <= cnt%4 + img_cnt_i*4;
                        w_en    <= 1;   w_addr      <= w_addr + 1;
                        save_en <= 1;   save_addr   <= save_addr + 1;
                        cnt     <= cnt+1;
                    end else if (cnt>= 2*(CYCLES>>2) && cnt < 3*(CYCLES>>2)) begin //192로 나누었을 때 
                        done    <= 0;
                        x_en    <= 1;   x_addr      <= cnt%4 + img_cnt_i*4;
                        w_en    <= 1;   w_addr      <= w_addr + 1;
                        save_en <= 1;   save_addr   <= save_addr + 1;
                        cnt     <= cnt+1;
                    end else if (cnt>= 3*(CYCLES>>2) && cnt < CYCLES) begin //256으로 나누었을 때 
                        done    <= 0;
                        x_en    <= 1;   x_addr      <= cnt%4 + img_cnt_i*4;
                        w_en    <= 1;   w_addr      <= w_addr + 1;
                        save_en <= 1;   save_addr   <= save_addr + 1;
                        cnt     <= cnt+1;
                    end else if (cnt >= CYCLES && cnt < CYCLES + TREE_DELAY) begin
                        done    <= 0;
                        x_en    <= 0;   x_addr      <= x_addr;
                        w_en    <= 0;   w_addr      <= w_addr;
                        save_en <= 1;   save_addr   <= save_addr + 1;
                        cnt     <= cnt+1;
                    end else if (cnt >= CYCLES+TREE_DELAY && cnt < CYCLES + TREE_DELAY+SAVE_DELAY) begin
                        done    <= 0;
                        x_en    <= 0;   x_addr      <= x_addr;
                        w_en    <= 0;   w_addr      <= w_addr;
                        save_en <= 0;   save_addr   <= 0;
                        cnt     <= cnt+1;
                    end else if (cnt >= CYCLES + TREE_DELAY + SAVE_DELAY) begin
                        done    <= 1;
                        x_en    <= 0;   x_addr      <= 0;
                        w_en    <= 0;   w_addr      <= 0;
                        save_en <= 0;   save_addr   <= 0;
                        cnt     <= cnt;
                    end else begin
                        done    <= 'bx;
                        x_en    <= 'bx; x_addr      <= 'bx;
                        w_en    <= 'bx; w_addr      <= 'bx;
                        save_en <= 'bx; save_addr   <= 'bx;
                        cnt     <= 'bx;
                    end
                end
                DONE: begin
                    done<=done;
                    {x_en, x_addr, w_en, w_addr, save_en, save_addr, cnt} <= 0;
                end
                default: begin
                    {done, x_en, x_addr, w_en, w_addr, save_en, save_addr, cnt} <= 0;
                end
            endcase
        end
    end
endmodule
