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
    output logic led
    );
    
    logic synced_rst;
    reset_synchronizer rst_synchronizer(.nrst(nsrt),.clk(clk),.sync_nrst(synced_rst));
    
    logic write_enable;
    logic read_enable;// read operation is asynchronous, this signal just pop the data from FIFO.
    
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
    .finish(read_enable),//in_data is sent, can be used to dequeue the item from fifo   
    
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



    
endmodule
