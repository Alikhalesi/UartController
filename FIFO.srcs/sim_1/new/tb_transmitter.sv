`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/19/2026 11:49:46 AM
// Design Name: 
// Module Name: tb_transmitter
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


module tb_transmitter(

    );
    
    
  // --- Timing Constants ---
    localparam CLK_PERIOD = 10;            // 10ns for 100MHz clock
    localparam CLK_PER_S_TICK = 651;       // 100MHz / (9600 * 16) = 651.04

    // --- Testbench Signals ---
    logic clk;
    logic nrst;
    logic tx;
    logic [7:0] in_data;
    logic enable;
    logic finish;
    logic s_tick;
    logic tick_rst;

    // --- Clock Generation (100 MHz) ---
    always #(CLK_PERIOD/2) clk = ~clk;

    // --- Simulated Baud Rate Generator (16x oversampling) ---
    // Counts to 651 clock cycles to generate each s_tick.
    // Automatically resets when the DUT asserts tick_rst.
    integer tick_counter = 0;
    always @(posedge clk or negedge nrst) begin
        if (!nrst || tick_rst) begin
            tick_counter <= 0;
            s_tick       <= 0;
        end else begin
            if (tick_counter >= (CLK_PER_S_TICK - 1)) begin
                tick_counter <= 0;
                s_tick       <= 1;
            end else begin
                tick_counter <= tick_counter + 1;
                s_tick       <= 0;
            end
        end
    end

    // --- Device Under Treat (DUT) Instantiation ---
    transmitter dut (
        .clk(clk),
        .nrst(nrst),
        .tx(tx),
        .in_data(in_data),
        .enable(enable),
        .finish(finish),
        .s_tick(s_tick),
        .tick_rst(tick_rst)
    );

    // --- Helper Task: Monitor TX Data ---
    // Captures the serial bit stream by sampling at the midpoint of each bit interval.
    task automatic monitor_tx_byte(output [7:0] captured_byte);
        logic [7:0] data;
        
        // 1. Wait for Start Bit (tx transitions from high to low)
        @(negedge tx);
        $display("[MONITOR] Start bit detected at %0t ns", $time);
        
        // Wait 1.5 bit periods (24 s_ticks) to jump directly into the middle of Data Bit 0
        repeat (24) @(posedge s_tick); 
        
        // 2. Sample 8 Data Bits (1 bit period = 16 s_ticks)
        for (int i = 0; i < 8; i++) begin
            data[i] = tx;
            $display("[MONITOR] Bit %0d sampled: %b at %0t ns", i, tx, $time);
            repeat (16) @(posedge s_tick); 
        end
        
        // 3. Sample Stop Bit
        $display("[MONITOR] Stop bit sampled: %b at %0t ns (Expected 1)", tx, $time);
        captured_byte = data;
    endtask

    // --- Test Stimulus ---
    initial begin
        // Initialize Signals
        clk     = 0;
        nrst    = 1;
        enable  = 0;
        in_data = 8'h00;

        // Apply Reset
   #(CLK_PERIOD * 10);
        nrst = 0;
        
        // Let the system stabilize
        #(CLK_PERIOD * 5);
           nrst = 1;
        #(CLK_PERIOD * 5);
        $display("--- Reset Released ---");

        // --- Test Case 1: Send 0x55 (Alternating bits: 01010101) ---
        @(posedge clk);
        in_data = 8'h55;
        enable  = 1;
        
        @(posedge clk);
        enable  = 0; // Deassert after 1 clock cycle (typical FIFO dequeue layout)
        
        // Wait for the transmitter to flag finish
        @(posedge finish);
        $display("[TESTCASE 1] Finish flagged for 0x55 at %0t ns", $time);
        #(CLK_PERIOD * 10);

        // --- Test Case 2: Send 0xA3 (10100011) ---
        @(posedge clk);
        in_data = 8'h41;
        enable  = 1;
        
        @(posedge clk);
        enable  = 0;
        
        @(posedge finish);
        @(posedge clk);
        in_data = 8'h42;
        enable  = 1;
        
          @(posedge clk);
        enable  = 0;
        
        
        @(posedge finish);
        $display("[TESTCASE 2] Finish flagged for 0xA3 at %0t ns", $time);
        
        // End simulation safely after the final bits settle
        #(CLK_PERIOD * 100);
        $display("--- Simulation Completed Successfully ---");
        $finish;
    end

    // --- Independent Monitor Thread ---
    initial begin
        logic [7:0] rx_byte;
        
        @(posedge nrst); // Wait for reset release
        
        monitor_tx_byte(rx_byte);
        $display("[MONITOR RESULT] Captured Byte 1: 0x%h (Expected: 0x55)", rx_byte);
        
        monitor_tx_byte(rx_byte);
        $display("[MONITOR RESULT] Captured Byte 2: 0x%h (Expected: 0xA3)", rx_byte);
    end
    
endmodule
