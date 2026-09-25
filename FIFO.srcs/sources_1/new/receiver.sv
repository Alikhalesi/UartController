`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/16/2026 09:05:32 AM
// Design Name: 
// Module Name: receiver
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


module receiver(
input logic clk,
input logic nrst,
input logic s_tick,
input logic rx,
output logic s_tick_rst,
output logic [7:0] data_out, 
output logic data_ready
    );
    
logic [4:0] baud_count,next_baud_count;    
logic [3:0] bit_count,next_bit_count;

typedef enum logic [1:0] {IDLE=2'b00,START=2'b01,DATA=2'b10,STOP=2'b11} STATE;

STATE current_state,next_state;

logic [7:0] data,next_data;

logic r_s_tick_rst,next_s_tick_rst;
logic r_data_ready,next_data_ready;

always_ff @(posedge clk, negedge nrst)
    begin
        if (!nrst)
            begin
                current_state<=IDLE;
                baud_count<=0;
                bit_count<=0;
                data<=0;
                r_s_tick_rst<=0;
                r_data_ready<=0;
            end
         else
            begin
                current_state<=next_state;
                baud_count<=next_baud_count;
                 bit_count<=next_bit_count;
                 data<=next_data;
                 r_s_tick_rst<=next_s_tick_rst;
                 r_data_ready<=next_data_ready;
            end
    end


always_comb
    begin
        next_state=current_state;
        next_baud_count=baud_count;
        next_bit_count=bit_count;
        next_data=data;
        next_s_tick_rst=0;
        next_data_ready=0;
        case (current_state)
            IDLE:
                begin
                    if(!rx)
                        begin
                            next_state=START;
                            next_s_tick_rst=1;
                            next_bit_count=0;
                            next_baud_count=0;
                        end                       
                end
            START:
                begin
                   if(s_tick)
                            begin
                                if(baud_count==7)
                                    begin
                                        next_state=DATA;
                                        next_baud_count=0;
                                    end
                                else
                                    next_baud_count=baud_count+1;
                            end        
                end
            DATA:
                begin
                     if(s_tick)
                          begin
                                if(bit_count==8)
                                    begin
                                        next_state=STOP;
                                        next_baud_count=0;
                                        next_bit_count=0;                                      
                                    end
                                else
                                    if(baud_count==15)
                                        begin 
                                            next_bit_count=bit_count+1;
                                            next_data={rx,data[7:1]};
                                            next_baud_count=0;
                                        end
                                    else
                                     next_baud_count=baud_count+1;
                            end      
                end
            STOP:
                begin
                  if(s_tick)
                          begin
                                if(baud_count==23)
                                    begin
                                        next_state=IDLE;
                                        next_data_ready=1;                                        
                                    end
                                else
                                     next_baud_count=baud_count+1;
                            end  
                end                
         endcase
        
    end
    
    
    assign s_tick_rst=r_s_tick_rst;
    assign data_out=data;
    assign data_ready=r_data_ready;
    
endmodule
