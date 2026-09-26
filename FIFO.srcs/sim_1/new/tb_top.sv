`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/25/2026 08:05:52 AM
// Design Name: 
// Module Name: tb_top
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


module tb_top(

    );
    
    
     // ----------------------------------------------------
    // 1. Clock and Reset Configuration
    // ----------------------------------------------------
    localparam CLK_PERIOD  = 10;                // 10ns for a 100MHz clock
    localparam BIT_PERIOD  = 104166; // Example: ~9600 baud (adjust as needed for your design)

    // ----------------------------------------------------
    // 2. Testbench Signals
    // ----------------------------------------------------
    logic rx;
    logic clk;
    logic nsrt;
    
    logic tx;
    logic led;

    // ----------------------------------------------------
    // 3. Device Under Test (DUT) Instantiation
    // ----------------------------------------------------
    top dut (
        .rx   (rx),
        .clk  (clk),
        .nsrt (nsrt),
        .tx   (tx),
        .led  (led)
    );

    // ----------------------------------------------------
    // 4. Clock Generation
    // ----------------------------------------------------
    initial begin
        clk = 0;
        forever #(CLK_PERIOD / 2) clk = ~clk;
    end

    // ----------------------------------------------------
    // 5. Test Tasks
    // ----------------------------------------------------
    
    // Task to simulate driving a UART frame onto the RX line
    task automatic send_uart_byte(input logic [7:0] data);
        integer i;
        begin
            $display("[TB] Sending UART Byte: 0x%h (%c) at time %0t", data, data, $time);
            
            // Start Bit (Low)
            rx = 1'b0;
            #(BIT_PERIOD);
            
            // 8 Data Bits (LSB first)
            for (i = 0; i < 8; i = i + 1) begin
                rx = data[i];
                #(BIT_PERIOD);
            end
            
            // Stop Bit (High)
            rx = 1'b1;
            #(BIT_PERIOD);
            
            // Extra padding between bytes
            #(BIT_PERIOD * 2);
        end
    endtask

    // ----------------------------------------------------
    // 6. Stimulus Process
    // ----------------------------------------------------
    initial begin
        // Initialize Inputs
        rx   = 1'b1; // UART idle state is High
        nsrt = 1'b0; // Start in reset

        // Hold reset for a few clock cycles
        #(CLK_PERIOD * 5);
        nsrt = 1'b1; // Release reset
        $display("[TB] Reset released.");

        // Wait for system stability
        #(CLK_PERIOD * 10);

        // --- Test Case 1: Send a single character 'A' (0x41) ---
        send_uart_byte(8'h48);

        // Wait enough time for the receiver to push to FIFO and transmitter to finish echoing it out
        #(BIT_PERIOD * 12);

        // --- Test Case 2: Send a secondary character 'B' (0x42) ---
        send_uart_byte(8'h53);
        
        // Wait for final transmission finish
        #(BIT_PERIOD * 15);

        $display("[TB] Simulation completed successfully.");
        $finish;
    end

    // ----------------------------------------------------
    // 7. Monitor (Optional)
    // ----------------------------------------------------
    initial begin
        $monitor("Time: %0t | nsrt: %b | rx: %b | tx: %b | led: %b", $time, nsrt, rx, tx, led);
    end
    
    
endmodule
