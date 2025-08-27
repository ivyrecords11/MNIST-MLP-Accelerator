`timescale 1ns / 1ps


module loc_ctrl4#(
    parameter CYCLES = 128      // same as depth
    )(
    input                           clk_i,
    input                           clear_i, //초기화
    input                           start_i,
    output reg                      x_en,
    output reg [$clog2(CYCLES)-1:0] x_addr,
    output reg                      w_en,
    output reg [$clog2(CYCLES)-1:0] w_addr,
    output reg                      save_en,
    output reg                      done
    );
    
    localparam IDLE = 3'b001,
               RUN  = 3'b010,
               DONE = 3'b100;
               
    reg [2:0] present_state, next_state;
    reg [$clog2(CYCLES):0] cnt;
    
    //present_state
    always @(posedge clk_i) begin
        present_state <= clear_i ? IDLE : next_state;
    end
    //next_state
    always @(*) begin
        case (present_state)
            IDLE : next_state = start_i ? RUN  : IDLE;
            RUN  : next_state = done   ? DONE : RUN;
            DONE : next_state = clear_i ? IDLE : DONE;
            default: next_state = IDLE; 
        endcase
    end
    
    always @(posedge clk_i) begin
        // 초기화
        /*if (clear_i) begin
            {done, x_en, w_en, w_addr, cnt, x_addr} <= 0;
        end
        else begin*/
            case (present_state)
                IDLE: begin
                    {done, x_en, w_en, w_addr, cnt, x_addr, save_en} <= 0;
                end
                RUN: begin
                    if (cnt == 0) begin
                        done    <= 0;
                        x_en    <= 1;   x_addr      <= 0;
                        w_en    <= 1;   w_addr      <= 0;
                        cnt     <= cnt + 1;
                        save_en <= 0;
                    end else if (cnt == CYCLES) begin
                        done    <= 1;
                        x_en    <= 0;   x_addr      <= 0;
                        w_en    <= 0;   w_addr      <= 0;
                        cnt     <= cnt;
                        save_en <= 1;
                    end else if (cnt<CYCLES) begin
                        done    <= 0;
                        x_en    <= 1;   x_addr      <= x_addr + 1;
                        w_en    <= 1;   w_addr      <= w_addr + 1;
                        cnt     <= cnt + 1;
                        save_en <= 0;
                    end else begin
                        done    <= 'b0;
                        x_en    <= 'b0;
                        w_en    <= 'b0;
                        save_en <= 0;
                    end
                end
                DONE: begin
                    done<=done;
                    {x_en, w_en, w_addr, cnt, x_addr, save_en} <= 0;
                end
                default: begin
                    {done, x_en, w_en, w_addr, cnt, x_addr, save_en} <= 0;
                end
            endcase
        end
    //end
endmodule
