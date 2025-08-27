`timescale 1 ns / 1 ps

module streamline_top(
    input wire clk_i,
    input wire rstn_i, 
    input wire start_i, 
    input wire en_i,
    
    output wire done_o,
    output wire [63:0] out_o
    );
    //cei l log2 2^3 => 3bit address
    wire    [4:0]               din1_addr = 0;
    wire                        din1_en;
    wire    [16320:0]              din1_data;
    
    wire    [2:0]               din2_addr = 0;
    wire                        din2_en;
    wire    [7:0]               din2_data;
    
    wire    [31:0]              temp_w [7:0];
    wire    [31:0]              temp2_w [7:0];
    wire    [7:0]               temp2_i[7:0];
    
    wire    clear;
    assign clear = ~rstn_i;
    assign din1_en = en_i;
    assign din2_en = en_i;
    
    
    single_port_bram #(
    .WIDTH(262144), // 64 * 256 *16
    .DEPTH(1),
    .INIT_FILE("C:\\Users\\ivyre\\Vivado\\fixed_point_W2_hex.txt")
    ) din1_bram( 
    .clk                    (clk_i), 
    .en                     (din1_en), 
    .wen                    (),  //not used
    .addr                   (din1_addr), 
    .din                    (), //not used
    .dout                   (din1_data) 
    );
    single_port_bram #(
    .WIDTH(4096),   //16*256
    .DEPTH(32), //5:0
    .INIT_FILE("C:\\Users\\ivyre\\Vivado\\layer2_output.txt")
    )din2_bram( 
    .clk                    (clk_i), 
    .en                     (din2_en), 
    .wen                    (), //not used
    .addr                   (din2_addr), 
    .din                    (), //not used
    .dout                   (din2_data) 
    );
endmodule

