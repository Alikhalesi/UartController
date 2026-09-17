`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/16/2026 10:46:30 AM
// Design Name: 
// Module Name: tb_receiver
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


module tb_receiver(

    );
    
    // --- Core Parameters ---
    localparam CLK_PERIOD   = 10;   // 10ns for a 100 MHz clock
    localparam OVERSAMPLING = 16;    // 16 ticks per bit period
    localparam TICK_DIVISOR = 651;    // 100MHz / (9600 * 16) = 65.1

    // --- Interface Signals ---
    logic       clk;
    logic       nrst;
    logic       s_tick;
    logic       rx;
    logic       s_tick_rst;
    logic [7:0] data_out;
    logic       data_ready;

    // --- Global Variables for Verification ---
    logic [7:0] expected_data;
    logic       expect_done;
    integer     data_ready_pulse_count;

    // --- UUT Instantiation ---
    receiver uut (
        .clk(clk),
        .nrst(nrst),
        .s_tick(s_tick),
        .rx(rx),
        .s_tick_rst(s_tick_rst),
        .data_out(data_out),
        .data_ready(data_ready)
    );

    // --- Free-running 10 MHz Clock Generation ---
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end

    // --- Bulletproof 9600 Baud Tick Generator ---
    logic s_tick_en;
    integer uut_tick_counter;

    always @(posedge clk or negedge nrst) begin
        if (!nrst) begin
            s_tick           <= 0;
            uut_tick_counter <= 0;
        end else if (s_tick_en) begin
            // Safeguard against UUT locking up the testbench tick generator
            if (s_tick_rst === 1'b1) begin
                s_tick           <= 0;
                uut_tick_counter <= 0;
            end else if (uut_tick_counter >= (TICK_DIVISOR - 1)) begin
                s_tick           <= 1;
                uut_tick_counter <= 0;
            end else begin
                s_tick           <= 0;
                uut_tick_counter <= uut_tick_counter + 1;
            end
        end else begin
            s_tick           <= 0;
            uut_tick_counter <= 0;
        end
    end

    // --- Time-Based Task: Send a UART Byte ---
    // This task relies entirely on explicit physical time delays calculated for 9600 baud.
    // 1 bit duration at 9600 baud = 1 / 9600 ≈ 104.16 microseconds = 104166 ns
    localparam BIT_DURATION_NS = 104166; 

    task automatic send_uart_byte(input [7:0] tx_data);
        integer i;
        begin
            expected_data = tx_data;
            expect_done   = 1;
            $display("[TB] Sending Byte: 8'h%h at time %0t", tx_data, $time);
            
            // 1. Start Bit (Logic 0)
            rx = 0; 
            #(BIT_DURATION_NS);

            // 2. Data Bits (LSB First)
            for (i = 0; i < 8; i++) begin
                rx = tx_data[i];
                #(BIT_DURATION_NS);
            end

            // 3. Stop Bit (Logic 1)
            rx = 1;
            #(BIT_DURATION_NS);
            
            // Allow processing buffer time for receiver state machine logic
            #(BIT_DURATION_NS * 2);
            
            if (expect_done) begin
                $error("[TB ERROR] Timeout: data_ready was never asserted for 8'h%h", tx_data);
            end
        end
    endtask

    // --- Automated Verification Block ---
    always @(posedge clk or negedge nrst) begin
        if (!nrst) begin
            data_ready_pulse_count <= 0;
        end else begin
            if (data_ready) begin
                data_ready_pulse_count <= data_ready_pulse_count + 1;
                
                if (data_ready_pulse_count == 0 && expect_done) begin
                    if (data_out === expected_data) begin
                        $display("[TB PASS] Verified Data Match! Received: 8'h%h", data_out);
                    end else begin
                        $error("[TB ERROR] Data Mismatch! Expected: 8'h%h, Received: 8'h%h", expected_data, data_out);
                    end
                    expect_done = 0; 
                end
                
                if (data_ready_pulse_count >= 1) begin
                    $error("[TB ERROR] Protocol Violation: data_ready asserted for more than 1 clock tick!");
                end
            end else begin
                data_ready_pulse_count <= 0; 
            end
        end
    end

    // --- Stimulus Setup ---
    initial begin
        // Force state parameters safely at time 0
        rx          = 1; 
        nrst        = 1;
        s_tick_en   = 0;
        expect_done = 0;
        uut_tick_counter = 0;
        
        // Assert reset for 1000 ns (10 clock cycles)
        #(CLK_PERIOD * 10);
        nrst = 0;
        
        // Let the system stabilize
        #(CLK_PERIOD * 5);
           nrst = 1;
             #(CLK_PERIOD * 5);
        s_tick_en = 1;
        #(CLK_PERIOD * 5);

        // --- Run Tests ---
           
        send_uart_byte(8'b01010101); // Alternating bits
        send_uart_byte(8'hA5); // Mixed pattern
     send_uart_byte(8'hFF); // All ones

        // Final hold time before closing
        #(BIT_DURATION_NS * 5);
        $display("[TB] Test Bench Execution Complete.");
        $finish;
    end
    
    
    
    
endmodule
