`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/26/2026 10:05:36 AM
// Design Name: 
// Module Name: ascii_decoder
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


module ascii_decoder(
input logic [7:0] ascii_data_in,
output logic [3:0] decimal_data_out
    );
    


always_comb
    begin
      decimal_data_out = 4'd0;
    case (ascii_data_in)
        8'd48: decimal_data_out = 4'd0;
        8'd49: decimal_data_out = 4'd1;
        8'd50: decimal_data_out = 4'd2;
        8'd51: decimal_data_out = 4'd3;
        8'd52: decimal_data_out = 4'd4;
        8'd53: decimal_data_out = 4'd5;
        8'd54: decimal_data_out = 4'd6;
        8'd55: decimal_data_out = 4'd7;
        8'd56: decimal_data_out = 4'd8;
        8'd57: decimal_data_out = 4'd9;
        default: decimal_data_out = 4'd0;
    endcase
    end

    
    
    
endmodule
