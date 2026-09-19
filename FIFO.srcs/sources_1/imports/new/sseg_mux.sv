`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06/27/2026 03:59:22 PM
// Design Name: 
// Module Name: sseg_mux
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


module sseg_mux(
input logic [15:0] number,
output logic [3:0] ctrl,
output logic [7:0] data,
 input logic start_signal,
 output logic finished_signal, 
input logic clk,
input logic nRst
    );
    
    
    logic [1:0] current_segment;
    logic [3:0] current_value;
    
    logic [19:0] dec_value;
    logic start_binary_decoding;
    logic binary_decode_finished;  
    logic [15:0] registered_number;
   
    
    
    
    typedef enum logic[1:0] { IDLE=2'b0,DECODING=2'b01,RENDERING=2'b10} state;
    state current_state,next_state;
    
    
    
        always_ff @(posedge clk or negedge nRst) begin
        if (!nRst) 
            current_state <= IDLE;
        else 
            current_state <= next_state;
     
    end
    
    
    
    binary_to_decimal_16bit bintodec(.clk(clk),.rst_n(nRst),.start(start_binary_decoding),
    .binary_in(registered_number),.bcd_out(dec_value),.ready(binary_decode_finished));


    logic [15:0] delay;
    always_ff @(posedge clk, negedge nRst)  begin
    if (!nRst)
        begin
            start_binary_decoding<=1'b0;
            registered_number<=16'b0;
            current_segment<=2'b0;
            delay<=16'h0000;
            next_state<=IDLE;
            finished_signal<=1'b1;
        end
    else
    
    case (current_state)
    IDLE:
        begin
        if(start_signal)
            begin
                finished_signal<=1'b0;
                registered_number<=number;
                start_binary_decoding<=1'b1;
                next_state<=DECODING;
            end
        end
    DECODING:
        begin
            if(binary_decode_finished)
                next_state<=RENDERING;      
        end
    RENDERING:
        begin
                  if (delay<16'hFFFF)
                          delay<=delay+1'b1;
                  else
                     begin    
                         current_segment<=current_segment+1;
                          delay<=16'h0000;
                          next_state<=IDLE;
                          finished_signal<=1'b1;  
                     end
        end
        
    endcase
     
    end
    
    
    
    
    
    //Output logic
    
    always_comb begin
//    current_value=dec_value[3:0];
    case (current_segment)
    2'b01: current_value=dec_value[7:4];
    2'b10: current_value=dec_value[11:8];
    2'b11: current_value=dec_value[15:12];
    default:  current_value=dec_value[3:0];
    endcase
    ctrl=4'b1111;
    ctrl[current_segment]=1'b0;
    
    
    end
    
    assign data[7]=1'b1;
    
    sseg seg(.number(current_value),.segments(data[6:0]));

endmodule