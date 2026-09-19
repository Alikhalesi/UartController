`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/15/2026 05:58:41 PM
// Design Name: 
// Module Name: baud_gen
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


module baud_gen #(parameter int FACTOR=16,localparam int BAUD_RATE=9600,localparam int CLOCK=100_000_000)
(
    input logic clk,
    input logic nrst,
    input logic rst,
    output logic tick
    );
    
    
    localparam int dvsr=(CLOCK/(FACTOR*BAUD_RATE))-1;
       
    logic [14:0] r_reg,r_next;
    
    always_ff @(posedge clk,negedge nrst)
    begin
        if(!nrst)
            r_reg<=0;
         else if(rst)
            r_reg<=0;
         else
            r_reg<=r_next;
            
    end

assign r_next=(r_reg==dvsr)?0:r_reg+1;

assign tick = (r_reg==0);
    
endmodule
