`timescale 1ns / 1ps

//CONTROLER FOR 2ND ADDER TREE
/*
clk_i           clock                  
clear_i         clear = negative reset
start_i         start signal       
x_en            x buffer enable
w_en            w bram enable
w_addr          w bram address
save_en         output save signal   
save_addr       output save address
done            output done signal
*/

module loc_ctrl3#(
    parameter CYCLES = 256,      // same as depth
    parameter L2_PRE_DELAY = 5,
    parameter SAVE_DELAY = 2
    )(
    input                           clk_i,
    input                           clear_i, //초기화
    input                           start_i,
    //input                           valid_i, //이전 연산의 완료 신호
    //output reg                      x_en,
    //output reg [$clog2(CYCLES):0]   x_addr,
    output reg                      mac_clear,
    output reg                      w_en,
    output reg [$clog2(CYCLES):0]   w_addr,
    output reg                      save_en,
    output reg                      done
    );
    
    localparam IDLE = 3'b001,
               RUN  = 3'b010,
               DONE = 3'b100;
               
    reg [2:0] present_state, next_state;
    reg [$clog2(CYCLES+L2_PRE_DELAY):0] cnt;
    
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
            {done, w_en, w_addr, cnt, save_en} <= 0;
            mac_clear = 1;
        end
        else begin
            case (present_state)
                IDLE: begin
                    {done, w_en, w_addr, cnt, save_en} <= 0;
                    mac_clear <= 1;
                end
                RUN: begin
                    if          (cnt >= 0 && cnt < L2_PRE_DELAY) begin
                        done    <= 0;
                        w_en    <= 0;   w_addr  <= 0;
                        cnt     <= cnt + 1;
                        mac_clear <= 1;
                    end else if (cnt == L2_PRE_DELAY) begin
                        done    <= 0;
                        w_en    <= 1;   w_addr      <= 0;
                        save_en <= 0;
                        cnt     <= cnt+1;
                        mac_clear <= 0;
                    end else if (cnt > L2_PRE_DELAY && cnt < CYCLES + L2_PRE_DELAY) begin
                        done    <= 0;
                        w_en    <= 1;   w_addr      <= w_addr+1;
                        save_en <= 0;
                        cnt     <= cnt+1;
                        mac_clear <= 0;
                    end else if (cnt >= CYCLES + L2_PRE_DELAY && cnt < CYCLES + L2_PRE_DELAY + SAVE_DELAY) begin
                        done    <= 0;
                        w_en    <= 0;   w_addr      <= w_addr;
                        save_en <= 0;
                        cnt     <= cnt+1;
                        mac_clear <= 0;
                    end else if (cnt >= CYCLES + L2_PRE_DELAY + SAVE_DELAY) begin
                        done    <= 1;
                        w_en    <= 0;   w_addr      <= w_addr;
                        save_en <= 1;
                        cnt     <= cnt;
                        mac_clear <= 0;
                    end else begin // 통제를 벗어났을 경우, x 출력
                        done    <= 'bx;
                        w_en    <= 'bx; w_addr      <= 'bx;
                        save_en <= 'bx;
                        cnt     <= 'bx;
                        mac_clear <= 'bx;
                    end
                end
                DONE: begin
                    done<=done;
                    {w_en, w_addr, cnt, save_en} <= 0;
                    mac_clear <= 1;
                end
                default: begin
                    {done, w_en, w_addr, cnt, save_en} <= 0;
                    mac_clear <= 1;
                end
            endcase
        end
    end
endmodule
