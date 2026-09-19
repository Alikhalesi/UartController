`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/19/2026 09:42:33 AM
// Design Name: 
// Module Name: transmitter
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


module transmitter(
    input logic clk,
    input logic nrst,
    input logic tx,
    input logic [7:0] in_data,
    input logic enable,// means in_data is valid and should be transmitted
    output logic finish,//in_data is sent, can be used to dequeue the item from fifo   
    
    input logic s_tick,
    output logic tick_rst 
    
    );
    
    typedef enum logic [1:0] {IDLE=2'b00,START=2'b01,DATA=2'b10,STOP=2'b11} STATE;
    
    STATE r_current_state,next_state;
    logic r_tx,next_tx;
    logic r_s_tick_rst,next_s_tick_rst;
    logic r_finish,next_finish;
    logic [7:0] r_in_data,next_data;
    logic [5:0] r_over_sample_count,next_over_sample_count;
     logic [5:0] r_bit_count,next_bit_count;
     
    always_ff @(posedge clk,negedge nrst)
        begin
            if (!nrst)
                begin
                    r_current_state<=IDLE;
                    r_tx<=1;
                    r_in_data<=0;
                    r_s_tick_rst<=0;
                    r_finish<=0;
                    r_over_sample_count<=0;
                    r_bit_count<=0;
                end
             else
                r_current_state<=next_state;
                 r_tx<=next_tx;;
                 r_in_data<=next_data;
                 r_s_tick_rst<=next_s_tick_rst;
                 r_finish<=next_finish;
                 r_over_sample_count<=next_over_sample_count;
                 r_bit_count<=next_bit_count;
        end
    
    
    
    always_comb
        begin
            next_state=r_current_state;
            next_data=r_in_data;
            next_s_tick_rst=0;
            next_finish=0;
            next_tx=1;
            next_over_sample_count=r_over_sample_count;
            next_bit_count<=r_bit_count;
        case (r_current_state)
        IDLE:
            if(enable)
                begin
                    next_state=START;
                    next_data=in_data;
                    next_s_tick_rst=1;
                    next_finish=0;
                    next_over_sample_count=0;
                    next_tx=0;
                    next_bit_count<=0;
                end
        START:
            begin
                if (r_over_sample_count==16)
                    begin
                        next_over_sample_count=0;
                        next_state=DATA;
                    end
                else if (s_tick)
                    next_over_sample_count=r_over_sample_count+1;
            end
        DATA:
            begin
                if (r_bit_count<7)
                    next_tx=r_in_data[r_bit_count];
                    
                if (r_over_sample_count==16)
                    begin
                        if(r_bit_count==7)
                            begin
                                next_state=STOP;
                                next_over_sample_count=0;
                                next_bit_count=0;
                            end
                         else
                            begin
                                next_over_sample_count=0;
                                next_bit_count=r_bit_count+1;
                            end 
                     end
                          
                      if (s_tick)
                         next_over_sample_count=r_over_sample_count+1;
                     
            end
        STOP:
            begin
                next_tx=1;
                if (r_over_sample_count==16)
                    begin
                        next_state=IDLE;
                        next_finish=1;
                    end
                else if (s_tick)
                         next_over_sample_count=r_over_sample_count+1;
                    
            end
    endcase
        end
    
   
    
    
    assign tx= r_tx;
    assign finish=r_finish;
    
endmodule
