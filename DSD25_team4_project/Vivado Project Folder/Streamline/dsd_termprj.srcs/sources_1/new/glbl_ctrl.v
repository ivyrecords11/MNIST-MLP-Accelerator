`timescale 1ns / 1ps

/*
done[0], start[0], clear[0] -> 1th layer
*/

module glbl_ctrl #(
    parameter IMG_NUM = 10
    )(
    input               clk_i,
    input               rstn_i,
    input               start_i,
    output reg [$clog2(IMG_NUM)-1:0]    img_cnt,
    output reg [$clog2(IMG_NUM)-1:0]    input_cnt,
    input       [3:0]   done_i,
    output reg  [3:0]   start_o,
    output reg  [3:0]   clear_o,
    output reg          done_o
    );
    
    localparam IDLE = 3'b001,
               RUN  = 3'b010,
               DONE = 3'b100;
               
    reg [2:0] present_state, next_state;
    //reg [3:0] stage;
    //reg [$clog2(IMG_NUM)-1:0] img_cnt_delay;
    reg cnt_add;
    
    always @(posedge clk_i) begin
        present_state <= !rstn_i ? IDLE : next_state;
    end
    //next_state
    always @(*) begin
        case (present_state)
            IDLE : next_state = start_i ? RUN  : IDLE;
            RUN  : next_state = done_o  ? DONE : RUN;
            DONE : next_state = !rstn_i ? IDLE : DONE;
            default: next_state = IDLE; 
        endcase
    end
    

    always @(posedge clk_i) begin
        // 초기화
        if (!rstn_i) begin
            {cnt_add, img_cnt, input_cnt, done_o} <= 0;
            start_o <= 4'b0000;
            clear_o <= 4'b1111;
            //{start1, start2, start3, start4, clear1, clear2, clear3, clear4, img_cnt, done} <= 0;
        end else begin
            case (present_state)
                IDLE: begin
                    {cnt_add, img_cnt, input_cnt, done_o, clear_o} <= 0;
                    start_o <= 4'b0000;
                    //{start1, start2, start3, start4, img_cnt, done} <= 0;  {clear1, clear2, clear3, clear4} <= 4'b1111;
                end
                RUN:  begin
                    if          ((start_o==4'b0000) && (img_cnt == 0)) begin
                        start_o   <= 4'b0001;
                        clear_o <= 4'b1111;
                        cnt_add = 0;
                        input_cnt <= 0;
                        img_cnt <= img_cnt;
                        done_o  <= 0;
                    end else if ((start_o==4'b0001)&&(done_i == 4'b0001)) begin
                        start_o   <= 4'b0111;
                        clear_o <= 4'b1111;
                        cnt_add = 1;
                        input_cnt <= input_cnt;
                        img_cnt   <= img_cnt;
                        done_o  <= 0;
                    end else if ((start_o==4'b0111)&&(done_i == 4'b0111)) begin
                        start_o   <= 4'b1111;
                        clear_o <= 4'b1111;
                        cnt_add = 1;
                        input_cnt <= input_cnt;
                        img_cnt   <= img_cnt;
                        done_o  <= 0;
                    end else if  (&{done_i} && img_cnt < IMG_NUM-1) begin
                        start_o   <= 4'b1111;
                        clear_o <= 4'b1111;
                        cnt_add = 1;
                        input_cnt <= input_cnt;
                        img_cnt <= img_cnt;
                        done_o  <= 0;
                    end else if (&{done_i[3]} && img_cnt == IMG_NUM-1) begin
                        start_o   <= 4'b0000;
                        clear_o <= 4'b1111;
                        cnt_add = 1;
                        input_cnt <= input_cnt;
                        img_cnt   <= img_cnt;
                        done_o  <= 1;
                    end else begin
                        start_o   <= start_o;
                        clear_o <= 4'b0000;
                        input_cnt <= input_cnt + cnt_add;
                        img_cnt   <= input_cnt >= 2 ? img_cnt + cnt_add : img_cnt;
                        done_o  <= 0;
                        cnt_add <= 0;
                    end
                end
                DONE: begin
                    cnt_add = 0;
                    start_o <= 4'b0000;
                    clear_o <= 4'b0000;
                    input_cnt       <= 0;
                    img_cnt         <= 0;
                    done_o          <= 0;
                end
                default: begin
                    cnt_add = 0;
                    start_o <= 4'b0000;
                    clear_o <= 4'b0000;
                    input_cnt       <= 0;
                    img_cnt         <= 0;
                    done_o          <= 0;
                end
            endcase
        end
    end
endmodule


/*
module glbl_ctrl#(
    parameter IMG_NUM = 10
    )(
    input                               clk_i,
    input                               rstn_i,
    input                               start_i,
    
    input      [3:0]                    done_i,
    output reg [$clog2(IMG_NUM)-1:0]    img_cnt,
    output reg [$clog2(IMG_NUM)-1:0]    input_cnt,
    output reg [3:0]                    start_o,
    output reg [3:0]                    clear_o,
    output reg                          done_o,
    output                              done_led_o
    );
    
    localparam IDLE = 3'b001,
               RUN  = 3'b010,
               DONE = 3'b100;
               
    reg [2:0] present_state, next_state;
    reg [3:0] stage;
    assign done_led_o = done_o;
    always @(posedge clk_i) begin
        present_state <= !rstn_i ? IDLE : next_state;
    end
    //next_state
    always @(*) begin
        case (present_state)
            IDLE : next_state = start_i ? RUN  : IDLE;
            RUN  : next_state = done_o  ? DONE : RUN;
            DONE : next_state = !rstn_i  ? IDLE : DONE;
            default: next_state = IDLE; 
        endcase
    end
    
    always @(posedge clk_i) begin
        // 초기화
        if (!rstn_i) begin
            {start_o, clear_o, img_cnt, input_cnt, done_o} <= 0;
            stage <= 4'b0001;
            //{start1, start2, start3, start4, clear1, clear2, clear3, clear4, img_cnt, done} <= 0;
        end else begin
            case (present_state)
                IDLE: begin
                    {start_o, img_cnt, input_cnt, done_o, clear_o} <= 0;
                    stage <= 4'b0001;
                    //{start1, start2, start3, start4, img_cnt, done} <= 0;  {clear1, clear2, clear3, clear4} <= 4'b1111;
                end
                RUN:  begin
                    if          ((start_o==4'b0001)&&(done_i == 4'b0001)) begin
                        stage   <= 4'b0011;
                        start_o <= stage;
                        clear_o <= 4'b0001;
                        img_cnt <= img_cnt;
                        input_cnt <= input_cnt;
                        done_o  <= 0;
                    end else if ((start_o==4'b0011)&&(done_i == 4'b0011)) begin
                        stage   <= 4'b0111;
                        start_o <= stage;
                        clear_o <= 4'b0011;
                        img_cnt <= img_cnt;
                        input_cnt <= input_cnt+1;
                        done_o  <= 0;
                    end else if ((start_o==4'b0111)&&(done_i == 4'b0111)) begin
                        stage   <= 4'b1111;
                        start_o <= stage;
                        clear_o <= 4'b0111;
                        img_cnt <= img_cnt;
                        input_cnt <= input_cnt+1;
                        done_o  <= 0;
                    end else if  (&{done_i} && img_cnt < IMG_NUM-1) begin
                        stage   <= 4'b1111;
                        start_o <= stage;
                        clear_o <= 4'b1111;
                        img_cnt <= img_cnt + 1;
                        input_cnt <= input_cnt+1;
                        done_o  <= 0;
                    end else if  (&{done_i} && img_cnt < IMG_NUM-3) begin
                        stage   <= 4'b1111;
                        start_o <= stage;
                        clear_o <= 4'b1111;
                        img_cnt <= img_cnt + 1;
                        input_cnt <= input_cnt;
                        done_o  <= 0;
                    end else if (&{done_i} && img_cnt == IMG_NUM-1) begin
                        stage   <= 4'b1111;
                        start_o <= stage;
                        clear_o <= 4'b1111;
                        img_cnt <= img_cnt;
                        input_cnt <= input_cnt;
                        done_o  <= 1;
                    end else begin
                        stage   <= stage;
                        start_o <= stage;
                        clear_o <= 4'b0000;
                        img_cnt <= img_cnt;
                        input_cnt <= input_cnt;
                        done_o  <= 0;
                    end
                end
                DONE: begin
                    stage   <= 4'b0001;
                    start_o <= 4'b0000;
                    clear_o <= 4'b0000;
                    img_cnt         <= 0;
                    input_cnt       <= 0;
                    done_o          <= 0;
                end
                default: begin
                    stage   <= 4'b0001;
                    start_o <= 4'b0000;
                    clear_o <= 4'b0000;
                    img_cnt         <= 0;
                    input_cnt       <= 0;
                    done_o          <= 0;
                end
            endcase
        end
    end
endmodule
*/
