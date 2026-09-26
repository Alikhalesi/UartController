`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/19/2026 05:18:10 PM
// Design Name: 
// Module Name: top
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module top(
  input logic rx,
 output logic tx,
    input logic clk,
    input logic nsrt,
    output logic led,
    output logic [7:0] sseg_ctrl,
    output logic [7:0] sseg_data
        );
    
    
    
    (* mark_debug = "true" *) logic rx_reg;
(* mark_debug = "true" *) logic tx_reg;

// 2. Sample them using your clock matrix
always_ff @(posedge clk) begin
    rx_reg <= rx;
    tx_reg <= tx;
end
    
    
    logic synced_rst;
    reset_synchronizer rst_synchronizer(.nrst(nsrt),.clk(clk),.sync_nrst(synced_rst));
    
    logic write_enable;
    logic read_enable;// read operation is asynchronous, this signal just pop the data from FIFO.
    
    logic transmit_finished;
    
    logic[7:0] fifo_read;
    logic[7:0] fifo_write;
    logic fifo_empty;
    logic fifo_full;
    fifo  #(.DATA_WIDTH(8)) fifo_instance
    (.clk(clk),.nrst(synced_rst),.w_en(write_enable),.r_en(read_enable),.r_data(fifo_read),.w_data(fifo_write),.empty(fifo_empty),.full(fifo_full));
    
    logic baud_gen_rst;
    logic baud_gen_tick;
    baud_gen tx_baud_gen(
    .clk(clk),
    .nrst(synced_rst),
    .rst(baud_gen_rst),
    .tick(baud_gen_tick));
    
    transmitter uart_transmitter(
    .clk(clk),
    .nrst(synced_rst),
    .tx(tx),
    .in_data(fifo_read),
    .enable(!fifo_empty),// means in_data is valid and should be transmitted
    .finish(transmit_finished),//in_data is sent, can be used to dequeue the item from fifo   
    .data_acquired(read_enable),
    .s_tick(baud_gen_tick), //input from baudrate generator
    .tick_rst(baud_gen_rst) // use this to reset baudrate generator
   );
    
    
        logic rx_baud_gen_rst;
    logic rx_baud_gen_tick;
    baud_gen rx_baud_gen(
    .clk(clk),
    .nrst(synced_rst),
    .rst(rx_baud_gen_rst),
    .tick(rx_baud_gen_tick));
    
    receiver uart_receiver(.clk(clk),
.nrst(synced_rst),
.s_tick(rx_baud_gen_tick),
.rx(rx),
.s_tick_rst(rx_baud_gen_rst),
.data_out(fifo_write), 
.data_ready(write_enable));


logic [3:0] decoded_data;

ascii_decoder decoder(.ascii_data_in(fifo_write),.decimal_data_out(decoded_data));


logic[3:0] hard_sseg_ctrl=4'b1111;
assign sseg_ctrl[7:4]=hard_sseg_ctrl;
assign start_signal=write_enable;
 logic finished_signal;

sseg_mux seven_mux(.number( {12'b0,decoded_data} ),
.ctrl(sseg_ctrl[3:0]),
.data(sseg_data),
.start_signal(start_signal),
.finished_signal(finished_signal),
.clk(clk),
.nRst(synced_rst));

assign led=1'b1;
    
endmodule
