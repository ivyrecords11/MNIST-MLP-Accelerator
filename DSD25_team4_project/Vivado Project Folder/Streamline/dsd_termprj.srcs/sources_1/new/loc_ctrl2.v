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

module loc_ctrl2#(
    parameter CYCLES = 256,      // same as depth
    parameter TREE_DELAY = 5 //64 = 2^6
    )(
    input                           clk_i,
    input                           clear_i, //초기화
    input                           start_i,
    output reg                      x_en,
    output reg                      w_en,
    output reg [$clog2(CYCLES):0] w_addr,
    output reg                      save_en,    //저장 
    //output reg [$clog2(CYCLES):0] save_addr,  //저장 주소
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
            {done, x_en, w_en, w_addr, save_en, cnt} <= 0;
        end
        else begin
            case (present_state)
                IDLE: begin
                    {done, x_en, w_en, w_addr, save_en, cnt} <= 0;
                end
                RUN: begin
                    if          (cnt == 0 && cnt<TREE_DELAY) begin
                        done    <= 0;
                        x_en    <= 1;
                        w_en    <= 1;   w_addr      <= 0;
                        save_en <= 0;   //save_addr   <= 0;
                        cnt     <= cnt+1;
                    end else if (cnt > 0 && cnt<TREE_DELAY) begin
                        done    <= 0;
                        x_en    <= 1;
                        w_en    <= 1;   w_addr      <= w_addr + 1;
                        save_en <= 0;   //ave_addr   <= 0;
                        cnt     <= cnt+1;
                    end else if (cnt == TREE_DELAY) begin
                        done    <= 0;
                        x_en    <= 1;
                        w_en    <= 1;   w_addr      <= w_addr + 1;
                        save_en <= 1;   //save_addr   <= 0;
                        cnt     <= cnt+1;
                    end else if (cnt > TREE_DELAY && cnt<CYCLES) begin
                        done    <= 0;
                        x_en    <= 1;
                        w_en    <= 1;   w_addr      <= w_addr + 1;
                        save_en <= 1;   //save_addr   <= save_addr + 1;
                        cnt     <= cnt+1;
                    end else if (cnt >= CYCLES && cnt < CYCLES + TREE_DELAY) begin
                        done    <= 0;
                        x_en    <= 0;
                        w_en    <= 0;   w_addr      <= w_addr;
                        save_en <= 1;   //save_addr   <= save_addr + 1;
                        cnt     <= cnt+1;
                    end else if (cnt >= CYCLES + TREE_DELAY) begin
                        done    <= 1;
                        x_en    <= 0;
                        w_en    <= 0;   w_addr      <= 0;
                        save_en <= 1;   //save_addr   <= save_addr;
                        cnt     <= cnt;
                    end else begin
                        done    <= 'bx;
                        x_en    <= 'bx;
                        w_en    <= 'bx; w_addr      <= 'bx;
                        save_en <= 'bx; //save_addr   <= 'bx;
                        cnt     <= 'bx;
                    end
                end
                DONE: begin
                    done<=done;
                    {x_en, w_en, w_addr, save_en, cnt} <= 0;
                end
                default: begin
                    {done, x_en, w_en, w_addr, save_en, cnt} <= 0;
                end
            endcase
        end
    end
endmodule
