`timescale 1ns / 1ps

module tb_init_state_controller;

    // Configuration parameters
    localparam int                  DATABITS               = 8;
    localparam logic [DATABITS-1:0] HEADER_1_VALUE         = 8'h55; // 01010101
    localparam logic [DATABITS-1:0] HEADER_2_VALUE         = 8'hAA; // 10101010
    localparam int                  NUMBER_OF_DATA_PACKETS = 13;
    localparam time                 CLK_PERIOD             = 40ns;       

    // DUT interface signals
    logic                  clk;
    logic                  rst;
    logic [DATABITS-1:0]   data_from_rx;
    logic                  rx_done;
    logic                  error_flag;
    logic                  write_data_to_matrix;
    logic                  all_data_transmitted;

    // Strobe verification counters
    int write_strobes_count;
    int all_transmitted_strobes_count;

    // Device Under Test (DUT) instantiation
    init_state_controller #(
        .DATABITS               (DATABITS),
        .HEADER_1_VALUE         (HEADER_1_VALUE),
        .HEADER_2_VALUE         (HEADER_2_VALUE),
        .NUMBER_OF_DATA_PACKETS (NUMBER_OF_DATA_PACKETS)
    ) dut (
        .clk                    (clk),
        .rst                    (rst),
        .data_from_rx           (data_from_rx),
        .rx_done                (rx_done),
        .error_flag             (error_flag),
        .write_data_to_matrix   (write_data_to_matrix),
        .all_data_transmitted   (all_data_transmitted)
    );

    // Clock generation 
    initial begin
        clk = 1'b0;
        forever #(CLK_PERIOD / 2) clk = ~clk;
    end

    // Task to transmit a single byte (emulates rx_done for 1 clock cycle)
    task automatic send_rx_byte(
        input logic [DATABITS-1:0] byte_data, 
        input int                  idle_clks = 3
    );
        @(posedge clk);
        data_from_rx <= byte_data;
        rx_done      <= 1'b1;
        error_flag   <= 1'b0;
        
        @(posedge clk);
        rx_done      <= 1'b0;
        data_from_rx <= '0;

        // Idle delay between packet transmissions
        repeat (idle_clks) @(posedge clk);
    endtask

    // Monitor write_data_to_matrix strobe
    always @(posedge clk) begin
        if (!rst && write_data_to_matrix) begin
            write_strobes_count++;
            $display("[T=%0t ns] STROBE: write_data_to_matrix #%0d received", $time, write_strobes_count);
        end
    end

    // Monitor all_data_transmitted strobe
    always @(posedge clk) begin
        if (!rst && all_data_transmitted) begin
            all_transmitted_strobes_count++;
            $display("[T=%0t ns] STROBE: all_data_transmitted detected!", $time);
        end
    end

    // Main test sequence
    initial begin
        // Signal and variable initialization
        rst                           = 1'b1;
        rx_done                       = 1'b0;
        error_flag                    = 1'b0;
        data_from_rx                  = '0;
        write_strobes_count           = 0;
        all_transmitted_strobes_count = 0;

        // Reset sequence (asserted for 3 clock cycles)
        repeat (3) @(posedge clk);
        rst = 1'b0;
        repeat (2) @(posedge clk);

        $display("--- Start Transmission: Headers ---");
        
        // Transmit initialization headers
        send_rx_byte(HEADER_1_VALUE);
        send_rx_byte(HEADER_2_VALUE);

        $display("--- Start Transmission: %0d Data Bytes ---", NUMBER_OF_DATA_PACKETS);
        
        // Transmit payload data
        for (int i = 0; i < NUMBER_OF_DATA_PACKETS; i++) begin
            send_rx_byte(8'h10 + i[7:0]);
        end

        // Wait for the Finite State Machine (FSM) to transition to the DONE state
        repeat (5) @(posedge clk);

        // Verification and result reporting
        $display("\n--- Verification Results ---");
        
        assert (write_strobes_count == NUMBER_OF_DATA_PACKETS) else 
            $error("FAIL: Expected %0d write strobes, but got %0d", 
                    NUMBER_OF_DATA_PACKETS, write_strobes_count);
        assert (all_transmitted_strobes_count == 1) else 
            $error("FAIL: Expected exactly 1 all_data_transmitted strobe, but got %0d", 
                    all_transmitted_strobes_count);

        if ((write_strobes_count == NUMBER_OF_DATA_PACKETS) && (all_transmitted_strobes_count == 1)) begin
            $display("TEST PASSED: 2 headers and %0d bytes transferred successfully with correct strobes.", NUMBER_OF_DATA_PACKETS);
        end else begin
            $display("TEST FAILED!");
        end

        $finish;
    end

endmodule
