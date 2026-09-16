`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/12/2026 11:18:42 AM
// Design Name: 
// Module Name: tb_fifo
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


module tb_fifo(

    );
    logic clk,nrst,w_en,r_en,empty,full;
    logic [31:0] r_data,w_data;    
    fifo fifo_dut
(
.clk(clk),
.nrst(nrst),
 .w_en(w_en),
.r_en(r_en),// read operation is asynchronous, this signal just pop the data from FIFO.
 .r_data(r_data),
.w_data(w_data),
.empty(empty),.full(full)
    );
    
      localparam real CLK_PERIOD = 10.0; 
      initial begin
        clk = 1'b0;
        forever begin
            #(CLK_PERIOD / 2.0) clk = ~clk;
        end
    end
    
      initial begin
        // Initialize inputs to default safe states
        nrst   = 1'b1;
        w_data = '0;
        w_en   = 1'b0;
        r_en=1'b0;

        // 2. Assert Reset immediately on the first falling edge
        @(negedge clk);
        nrst = 1'b0;
        $display("[STATUS] Reset asserted.");

        // 3. Hold reset active for 2 full clock cycles
        repeat (2) @(posedge clk);
        
        // 4. Release reset on a falling edge so it is stable before the next rise
        @(negedge clk);
        nrst = 1'b1;
        $display("[STATUS] Reset released. Beginning test operations...");

        // Hold reset/idle state for 2 clock cycles
        repeat (5) @(posedge clk);
        
   

        // --- Operation 1: Write 32'hDEADBEEF to Register 5 ---
        @(negedge clk); // Drive inputs on negative edge to prevent setup/hold races
        w_data = 32'h0000000A;
        w_en   = 1'b1;
        
        @(negedge clk);
        w_en   = 1'b0;
         
        @(negedge clk);
        w_data = 32'h0000000B;
        w_en   = 1'b1;
        @(negedge clk);
        w_en   = 1'b0;

                 
        @(negedge clk);
        r_en=1'b1;
        @(negedge clk);
         // Hold reset/idle state for 2 clock cycles
        repeat (5) @(posedge clk);
          $finish;
    end
    
    
    
    
endmodule
