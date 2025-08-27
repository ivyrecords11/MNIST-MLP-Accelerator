`timescale 1 ns / 1 ps
//////////////////////////////////////////////////////////////////////////////////
// local controller_1
// inputs: clock, reset, start
// outputs: done_1_o, 
//////////////////////////////////////////////////////////////////////////////////

module local_controller_1(
    input   wire                        clk_i,
    input   wire                        rstn_i,
    input   wire                        start_i,
    
    input   wire                        p_done_0,
    output  wire                        done_1_o,
    output  wire                        pu_1_clear_o,
    output  wire                [2:0]   din3_addr_o,
    output  wire                        din3_en_o,
    output  wire                        en_psum_o
    );
    //PARAMETERS
    localparam      IDLE = 2'b00,
                    RUN = 2'b01,
                    DONE = 2'b11;
        
    reg     [1:0]               present_state_1, next_state_1;
    reg                         done, en_psum, pu_1_clear;
    reg     [2:0]     din3_addr;
    reg                         din3_en; //w_en

    //INTERNAL (NO NEED FOR ASSIGN)
    reg     [4:0]               count_mac_1;
    reg                         delay1;
    
    assign done_1_o = done;
    assign din3_en_o = din3_en;
    assign din3_addr_o = din3_addr;
    assign en_psum_o = en_psum;
    assign pu_1_clear_o = pu_1_clear;
    
    //ASSIGN NEXT STATE TO PRESENT STATE
    always @(posedge clk_i or negedge rstn_i) begin
        if (!rstn_i) begin
            present_state_1 <= IDLE;
        end
        else begin
            present_state_1 <= next_state_1;
        end
    end    
    
    //DECIDE NEXT STATE
    always @(*) begin
        case(present_state_1)
            IDLE: begin
                if(start_i) begin
                    next_state_1 = RUN;
                end
                else begin
                    next_state_1 = IDLE;
                end
            end
            //UNTIL MAC CYCLES REACH 8
            RUN: begin
                if(count_mac_1 == 4'd8) begin //until mac cycles reach 8
                    next_state_1 = DONE;
                end
                else begin
                    next_state_1 = RUN;
                end
            end
            DONE: begin
                next_state_1 = IDLE;
            end
            // IN CASE OF ERRORS
            default:begin
                next_state_1 = IDLE;
            end
        endcase
    end
    
    //CONTROL SIGNALS
    always@(posedge clk_i or negedge rstn_i) begin
        //IN CASE OF RESET
        if (!rstn_i) begin
            done            <= 0;
            en_psum         <= 0;
            pu_1_clear      <= 0;
            din3_addr       <= 0;
            din3_en         <= 0;
            count_mac_1     <= 0;
        end
        else begin
            case(present_state_1)
                IDLE: begin
                    done            <= 0;
                    en_psum         <= 0;
                    pu_1_clear      <= 0;
                    din3_addr       <= 0;
                    din3_en         <= 0;
                    count_mac_1     <= 0;
                end
                RUN: begin
                //END CONDITION
                din3_en         <= 1;
                    if (count_mac_1 == 4'd8) begin
                        done            <= 1;
                        en_psum         <= 0;
                        pu_1_clear      <= 1;
                        din3_addr       <= 0;
                        din3_en         <= 0;
                        count_mac_1     <= 0;
                    end
                    else begin
                        done <= 0;
                        if (delay1) begin
                            delay1          <= 0;
                            en_psum         <= 0;
                        end else if (p_done_0) begin
                            delay1          <= 1;
                            en_psum         <= 1;
                            pu_1_clear      <= 0;
                            din3_addr       <= din3_addr + 1;
                            din3_en         <= 1;
                            count_mac_1     <= count_mac_1 + 1;
                        end
                    end
                end
                DONE: begin
                    done            <= 0;
                    en_psum         <= 0;
                    pu_1_clear      <= 0;
                    din3_addr       <= 0;
                    din3_en         <= 0;
                    count_mac_1     <= 0;
                end
                default: begin
                    done            <= 0;
                    en_psum         <= 0;
                    pu_1_clear      <= 0;
                    din3_addr       <= 0;
                    din3_en         <= 0;
                    count_mac_1     <= 0;
                end
            endcase
        end
    end
                        
            
endmodule
