`timescale 1ns/1ps

module testbench;

    // Parameters
    localparam int W             = 10;
    localparam int H             = 10;
    localparam int DATABITS      = 8;
    localparam int CLK_PERIOD    = 10;
    localparam int TOTAL_BITS    = W * H;                                  // 100 bits
    localparam int NUM_TRANSFERS = (TOTAL_BITS + DATABITS - 1) / DATABITS; // 13 transfers
    localparam int TOTAL_STREAM  = NUM_TRANSFERS * DATABITS;               // 104 bits
    localparam int PADDING_BITS  = TOTAL_STREAM - TOTAL_BITS;              // 4 bits

    // Interface signals
    logic                clk;
    logic                rst;
    logic [DATABITS-1:0] rx_data_out;
    logic                write_data_to_matrix;
    logic [W-1:0]        init_state [H-1:0];

    // DUT instantiation
    matrix_writer #(
        .W        ( W        ),
        .H        ( H        ),
        .DATABITS ( DATABITS )
    ) DUT (
        .clk                  ( clk                  ),
        .rst                  ( rst                  ),
        .rx_data_out          ( rx_data_out          ),
        .write_data_to_matrix ( write_data_to_matrix ),
        .init_state           ( init_state           )
    );

    // Reference data
    logic [W-1:0]            expected_matrix [H-1:0];
    logic [TOTAL_BITS-1:0]   linear_expected;
    logic [TOTAL_STREAM-1:0] stream_buffer; // 104 bits
    logic [DATABITS-1:0]     packets [NUM_TRANSFERS-1:0];

    // Clock generation
    initial begin
        clk = 0;
        forever #(CLK_PERIOD / 2) clk = ~clk;
    end

    // Test procedure
    initial begin
        // 1. Initialize inputs
        rst                  <= 1'b1; // Active-High reset
        rx_data_out          <= '0;
        write_data_to_matrix <= 1'b0;

        // 2. Synchronous reset release
        repeat (3) @(posedge clk);
        rst <= 1'b0;
        @(posedge clk);

        // 3. Generate random 10x10 reference matrix
        for (int y = 0; y < H; y++) begin
            for (int x = 0; x < W; x++) begin
                expected_matrix[y][x]      = $urandom_range(0, 1);
                linear_expected[y * W + x] = expected_matrix[y][x];
            end
        end

        // 4. Prepare byte stream with right shift consideration:
        // shift_reg <= {rx_data_out, shift_reg[TOTAL_BITS-1 : DATABITS]};
        // First bits shift to LSB (0..3 get dropped).
        // Put 4 padding bits in stream_buffer[3:0],
        // and target data in stream_buffer[103:4].
        stream_buffer = '0;
        stream_buffer[PADDING_BITS-1 : 0]            = $urandom(); // 4 dummy bits
        stream_buffer[TOTAL_STREAM-1 : PADDING_BITS] = linear_expected;

        // Slice 104 bits into 13 bytes:
        // packets[0] goes first, packets[12] goes last
        for (int i = 0; i < NUM_TRANSFERS; i++) begin
            packets[i] = stream_buffer[i * DATABITS +: DATABITS];
        end

        // 5. Send 13 8-bit transactions
        $display("[TB] Start sending %0d data packets...", NUM_TRANSFERS);
        for (int i = 0; i < NUM_TRANSFERS; i++) begin
            @(posedge clk);
            rx_data_out          <= packets[i];
            write_data_to_matrix <= 1'b1;

            @(posedge clk);
            write_data_to_matrix <= 1'b0;
            rx_data_out          <= 'x; // Prevent false sampling

            // Random pause between transfers
            repeat ($urandom_range(1, 3)) @(posedge clk);
        end

        // 6. Check results
        @(posedge clk);
        check_matrix();

        #(CLK_PERIOD * 5);
        $finish();
    end

    // Task to check and print matrices
    task check_matrix();
        int mismatches;
        mismatches = 0;
        $display("\n===================== CHECK RESULT =====================");
        for (int y = 0; y < H; y++) begin
            for (int x = 0; x < W; x++) begin
                if (init_state[y][x] !== expected_matrix[y][x]) begin
                    $error("[MISMATCH] at [%0d][%0d]: Got %b, Expected %b", 
                           y, x, init_state[y][x], expected_matrix[y][x]);
                    mismatches++;
                end
            end
        end

        if (mismatches == 0) begin
            $display("[TEST PASSED] Output matrix matches expected state perfectly!");
        end else begin
            $display("[TEST FAILED] Total bit errors: %0d / %0d", mismatches, TOTAL_BITS);
        end

        // Print matrices for visual check
        $display("\nExpected Matrix:             Received Matrix (init_state):");
        for (int y = 0; y < H; y++) begin
            $write("Row %2d: %b  |  ", y, expected_matrix[y]);
            $write("Row %2d: %b\n", y, init_state[y]);
        end
        $display("========================================================\n");
    endtask

endmodule