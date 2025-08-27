module glbl_ctrl #(
    parameter X_ADDR = 5,
    parameter W_ADDR = 5,
    parameter W1_ADDR = 6,
    parameter W2_ADDR = 7,
    parameter W3_ADDR = 6
)(
    // system interface
    input   wire                        clk_i,
    input   wire                        rstn_i,
    input   wire                        start_i,
    output  wire                       done_intr_o,
    output  wire                       done_led_o,
    // x_buffer interface
    output  wire                       x_en,
    output  wire [X_ADDR-1:0]          x_addr,
    // w_buffer interface
    output  wire                       w_en,
    output  wire [W_ADDR-1:0]          w_addr,
    output  wire                       w1_en,
    output  wire [W1_ADDR-1:0]         w1_addr,
    output  wire                       w2_en,
    output  wire [W2_ADDR-1:0]         w2_addr,
    output  wire                       w3_en,
    output  wire [W3_ADDR-1:0]         w3_addr,
    output  wire                       temp_en,
    output  wire                       temp_wen,
    output  wire                       temp_addr,
    // processing unit interface
    output  wire                       pu_en,
    output  wire                       pu_clear,
    output  wire [2:0]                 layer,
    output  wire                       valid,
    output  wire [8:0]                 cnt_mac,
    input   wire                       prcss_done_gemv,
    input   wire                       all_done
);

    localparam IDLE   = 6'b000001,
               LAYER1 = 6'b000010,
               LAYER2 = 6'b000100,
               LAYER3 = 6'b001000,
               LAYER4 = 6'b010000,
               DONE   = 6'b100000;

    reg [5:0] present_state, next_state;
    reg [8:0] r_cnt_mac;

    reg                       r_done_intr_o;
    reg                       r_done_led_o;
    reg                       r_x_en;
    reg [X_ADDR-1:0]          r_x_addr;
    reg                       r_w_en;
    reg [W_ADDR-1:0]          r_w_addr;
    reg                       r_w1_en;
    reg [W1_ADDR-1:0]         r_w1_addr;
    reg                       r_w2_en;
    reg [W2_ADDR-1:0]         r_w2_addr;
    reg                       r_w3_en;
    reg [W3_ADDR-1:0]         r_w3_addr;
    reg                       r_temp_en;
    reg                       r_temp_wen;
    reg                       r_temp_addr;
    reg                       r_pu_en;
    reg                       r_pu_clear;
    reg [2:0]                 r_layer;
    reg                       r_valid;

    assign done_intr_o = r_done_intr_o;
    assign done_led_o = r_done_led_o;
    assign x_en = r_x_en;
    assign x_addr = r_x_addr;
    assign w_en = r_w_en;
    assign w_addr = r_w_addr;
    assign w1_en = r_w1_en;
    assign w1_addr = r_w1_addr;
    assign w2_en = r_w2_en;
    assign w2_addr = r_w2_addr;
    assign w3_en = r_w3_en;
    assign w3_addr = r_w3_addr;
    assign temp_en = r_temp_en;
    assign temp_wen = r_temp_wen;
    assign temp_addr = r_temp_addr;
    assign pu_en = r_pu_en;
    assign pu_clear = r_pu_clear;
    assign layer = r_layer;
    assign valid = r_valid;
    assign cnt_mac = r_cnt_mac;

    always@ (posedge clk_i or negedge rstn_i) begin
        if(!rstn_i)
            present_state <= IDLE;
        else
            present_state <= next_state;  
    end

    always@ (*) begin
        case(present_state)
            IDLE:   next_state = start_i ? LAYER1 : IDLE;
            LAYER1: next_state = r_temp_wen ? LAYER2 : LAYER1;
            LAYER2: next_state = r_temp_wen ? LAYER3 : LAYER2;
            LAYER3: next_state = r_temp_wen ? LAYER4 : LAYER3;
            LAYER4: next_state = r_temp_wen ? DONE : LAYER4;
            DONE:   next_state = all_done ? DONE : LAYER1; 
            default: next_state = IDLE;
        endcase
    end

    always@ (posedge clk_i or negedge rstn_i) begin
        if(!rstn_i) begin
            r_done_intr_o <= 0;
            r_done_led_o <= 0;
            r_x_en <= 0;
            r_x_addr <= 0;
            r_w_en <= 0;
            r_w_addr <= 0;
            r_w1_en <= 0;
            r_w1_addr <= 0;
            r_w2_en <= 0;
            r_w2_addr <= 0;
            r_w3_en <= 0;
            r_w3_addr <= 0;
            r_temp_en <= 0;
            r_temp_wen <= 0;
            r_temp_addr <= 0;
            r_pu_en <= 0;
            r_pu_clear <= 0;
            r_cnt_mac <= 0;
            r_layer <= 0;
            r_valid <= 0;
        end
        else begin
            case(present_state)
                IDLE: begin 
                    r_done_intr_o <= 0;
                    r_done_led_o <= 0;
                    r_x_en <= 0;
                    r_x_addr <= 0;
                    r_w_en <= 0;
                    r_w_addr <= 0;
                    r_w1_en <= 0;
                    r_w1_addr <= 0;
                    r_w2_en <= 0;
                    r_w2_addr <= 0;
                    r_w3_en <= 0;
                    r_w3_addr <= 0;
                    r_temp_en <= 0;
                    r_temp_wen <= 0;
                    r_temp_addr <= 0;
                    r_pu_en <= 0;
                    r_pu_clear <= 0;
                    r_cnt_mac <= 0;
                    r_layer <= 0;
                    r_valid <= 0;
                end

               LAYER1: begin
                    r_done_intr_o <= 0;
                    r_done_led_o <= 0;
                    r_x_en <= 1;
                    r_w_en <= 1;
                    r_w1_en <= 0;
                    r_w2_en <= 0;
                    r_w3_en <= 0;
                    r_pu_en <= 1;
                    r_pu_clear <= 0;
                    r_valid <= 0;
                    r_layer <= 3'b001;
                    r_w_addr <= 0;
                    if(x_en && w_en) begin
                        r_w_addr <= r_w_addr + 1;
                        r_x_addr <= r_x_addr + 1;
                        r_cnt_mac <= r_cnt_mac + 1;
                    end
                    if(r_w_addr == 5'd27)
                        r_w_addr <= 0;
                    if(r_x_addr == 5'd27)
                        r_x_addr <= 0;
                        
                    if (cnt_mac == 8'd28) begin
                        r_cnt_mac <= 0;
                        r_pu_en <= 0;            // PU off (계산 끝)
                        r_pu_clear <= 1;         // Clear next cycle
                        r_valid <= 1;
                        r_w_addr <= 0;
                    end else begin
                        r_temp_en <= 0;
                        r_temp_wen <= 0;
                        r_pu_clear <= 0;
                    end
                        
                    if(prcss_done_gemv) begin
                        r_temp_en <= 1;
                        r_temp_wen <= 1;
                        r_pu_clear <= 1;
                        r_pu_en <= 0;
                    end

                    r_w1_addr <= 0;
                    r_w2_addr <= 0;
                    r_w3_addr <= 0;
                    r_temp_addr <= 0;  // 저장 위치는 kernel index
                end

                LAYER2: begin
                    r_done_intr_o <= 0;
                    r_done_led_o <= 0;
                    r_x_en <= 0;
                    r_x_addr <= 0;
                    r_w_en <= 0;
                    r_w_addr <= 0;
                    r_w1_en <= 1;
                    r_w2_en <= 0;
                    r_w3_en <= 0;
                    r_temp_en <= 1;
                    r_temp_wen <= 0;
                    r_pu_en <= 1;
                    r_pu_clear <= 0;
                    r_layer <= 3'b010;
                    r_cnt_mac <= 0;
                    r_temp_addr <= 0;
                    r_valid <= 0;
                    
                    if (r_temp_en && r_w1_en) begin
                        r_w1_addr <= r_w1_addr + 1;
                        r_cnt_mac <= r_cnt_mac + 1;
                    end

                    if(cnt_mac == 8'b0100_0000) begin
                        r_w1_addr <= 0;
                        r_temp_addr <= 0;
                        r_pu_en <= 0;
                        r_cnt_mac <= 0;
                        r_w1_en <= 0;
                        r_temp_en <= 0;
                        r_pu_clear <= 1;
                        r_valid <= 1;
                    end

                    if(prcss_done_gemv) begin
                        r_temp_wen <= 1;
                        r_temp_en <= 1;
                        r_pu_clear <= 1;
                        r_pu_en <= 0;
                        r_w1_en <= 0;
                    end
                    
                    if(r_pu_clear)
                        r_w1_en <= 0;

                    r_w2_addr <= 0;
                    r_w3_addr <= 0;
                    r_x_addr <= 0;
                end

                LAYER3: begin
                    r_done_intr_o <= 0;
                    r_done_led_o <= 0;
                    r_x_en <= 0;
                    r_x_addr <= 0;
                    r_w_en <= 0;
                    r_w_addr <= 0;
                    r_w1_en <= 0;
                    r_w1_addr <= 0;
                    r_w2_en <= 1;
                    r_w3_en <= 0;
                    r_temp_en <= 1;
                    r_temp_wen <= 0;
                    r_pu_en <= 1;
                    r_pu_clear <= 0;
                    r_layer <= 3'b011;
                    r_cnt_mac <= 0;
                    r_temp_addr <= 0;
                    r_valid <= 0;
                    
                    if (r_temp_en && r_w2_en) begin
                        r_w2_addr <= r_w2_addr + 1;
                        r_cnt_mac <= r_cnt_mac + 1;
                    end

                    if(cnt_mac == 8'b1000_0000) begin
                        r_w2_addr <= 0;
                        r_temp_addr <= 0;
                        r_pu_en <= 0;
                        r_cnt_mac <= 0;
                        r_w2_en <= 0;
                        r_temp_en <= 0;
                        r_pu_clear <= 1;
                        r_valid <= 1;
                    end 

                    if(prcss_done_gemv) begin
                        r_temp_wen <= 1;
                        r_temp_en <= 1;
                        r_pu_clear <= 1;
                        r_pu_en <= 0;
                        r_w2_en <= 0;
                    end
                    
                    if(r_pu_clear)
                        r_w2_en <= 0;

                    r_w3_addr <= 0;
                    r_x_addr <= 0;
                    r_w1_addr <= 0;
                end

                LAYER4: begin
                    r_done_intr_o <= 0;
                    r_done_led_o <= 0;
                    r_x_en <= 0;
                    r_x_addr <= 0;
                    r_w_en <= 0;
                    r_w_addr <= 0;
                    r_w1_en <= 0;
                    r_w1_addr <= 0;
                    r_w2_en <= 0;
                    r_w2_addr <= 0;
                    r_w3_en <= 1;
                    r_temp_en <= 1;
                    r_temp_wen <= 0;
                    r_pu_en <= 1;
                    r_pu_clear <= 0;
                    r_layer <= 3'b100;
                    r_cnt_mac <= 0;
                    r_valid <= 0;
                    r_temp_addr <= 0;

                    if (r_temp_en && r_w3_en) begin
                        r_w3_addr <= r_w3_addr + 1;
                        r_cnt_mac <= r_cnt_mac + 1;
                    end

                    if(cnt_mac == 8'b0100_0000) begin
                        r_w3_addr <= 0;
                        r_temp_addr <= 0;
                        r_pu_en <= 0;
                        r_cnt_mac <= 0;
                        r_w3_en <= 0;
                        r_temp_en <= 0;
                        r_pu_clear <= 1;
                        r_valid <= 1;
                    end

                    if(prcss_done_gemv) begin
                        r_temp_wen <= 1;
                        r_temp_en <= 1;
                        r_pu_clear <= 1;
                        r_pu_en <= 0;
                        r_w3_en <= 0;
                    end
                    
                    if(r_w3_addr == 6'd63)
                        r_w3_addr <= 0;
                        
                    if(r_pu_clear)
                        r_w3_en <= 0;

                    r_x_addr <= 0;
                    r_w_addr <= 0;
                    r_w1_addr <= 0;
                    r_w2_addr <= 0;
                end

                DONE: begin 
                    r_done_intr_o <= 1;
                    r_done_led_o <= 1;
                    r_x_en <= 0;
                    r_x_addr <= 0;
                    r_w_en <= 0;
                    r_w_addr <= 0;
                    r_w1_en <= 0;
                    r_w1_addr <= 0;
                    r_w2_en <= 0;
                    r_w2_addr <= 0;
                    r_w3_en <= 0;
                    r_w3_addr <= 0;
                    r_temp_en <= 0;
                    r_temp_wen <= 0;
                    r_temp_addr <= 0;
                    r_pu_en <= 0;
                    r_pu_clear <= 0;
                    r_cnt_mac <= 0; 
                    r_layer <= 0;
                    r_valid <= 0;
                end

                default: begin 
                    r_done_intr_o <= 0;
                    r_done_led_o <= 0;
                    r_x_en <= 0;
                    r_x_addr <= 0;
                    r_w_en <= 0;
                    r_w_addr <= 0;
                    r_w1_en <= 0;
                    r_w1_addr <= 0;
                    r_w2_en <= 0;
                    r_w2_addr <= 0;
                    r_w3_en <= 0;
                    r_w3_addr <= 0;
                    r_temp_en <= 0;
                    r_temp_wen <= 0;
                    r_temp_addr <= 0;
                    r_pu_en <= 0;
                    r_pu_clear <= 0;
                    r_cnt_mac <= 0;
                    r_layer <= 0;
                    r_valid <= 0;
                end
            endcase
        end
    end
endmodule
