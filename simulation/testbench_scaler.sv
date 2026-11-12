module testbench_scaler;

  localparam int ROWS = 320;
  localparam int COLS = 320;

  // 320x320 bit matrix
  logic [COLS-1:0] screen_matrix [0:ROWS-1];
  logic [99:0]     life_golden_line;
  int              fd;
  logic            expected_pixel;

  // DUT signals
  logic [9:0]  tb_pixel_x;
  logic [9:0]  tb_pixel_y;
  logic [99:0] tb_generation_triggers;
  logic        tb_pixel;

  // Scaler module instance
  scaler dut (
    .pixel_x             (tb_pixel_x),
    .pixel_y             (tb_pixel_y),
    .generation_triggers (tb_generation_triggers),
    .pixel               (tb_pixel)
  );

  initial begin
    // Initialize signals
    tb_pixel_x = 0;
    tb_pixel_y = 0;
    tb_generation_triggers = '0;

    // Load screen matrix from file
    $readmemb("screen_matrix_bin.mem", screen_matrix);

    // Read golden reference line
    fd = $fopen("life_golden_bin.mem", "r");
    if (fd == 0) begin
      $fatal(1, "Error: Failed to open life_golden_bin.mem");
    end
    $fscanf(fd, "%b\n", life_golden_line);
    $fclose(fd);

    // Display 100-bit golden line
    $display("life_golden_line:");
    $display("%0100b", life_golden_line);

    // Display first row of the screen matrix (320 bits)
    $display("screen_matrix[0]:");
    $display("%0320b", screen_matrix[0]);

    #10;
    
    // Assign generation triggers from golden line (bit-reversed)
    for (int i = 0; i < 100; i++) begin
      tb_generation_triggers[i] = life_golden_line[99 - i];
    end

    // Pixel verification loop
    for (int y = 0; y < ROWS; y++) begin
      for (int x = 0; x < COLS; x++) begin
        tb_pixel_x = 10'(160 + x);
        tb_pixel_y = 10'(80 + y);

        // Wait for combinational logic propagation
        #1;

        // Fetch expected pixel (assuming X=0 is at MSB)
        expected_pixel = screen_matrix[y][COLS - 1 - x];

        // Check for mismatch
        if (tb_pixel !== expected_pixel) begin
          $error("[MISMATCH] at (X=%0d, Y=%0d): DUT pixel = %b, Expected = %b", 
                 tb_pixel_x, tb_pixel_y, tb_pixel, expected_pixel);
          $finish; // Stop simulation on first error
        end
      end
    end

    $display("[SUCCESS] All %0d pixels matched successfully!", ROWS * COLS);
    $finish;
  end

endmodule