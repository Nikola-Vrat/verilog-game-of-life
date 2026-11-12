`timescale 1ns/1ps

module testbench_game_logic;


  logic clk;
  logic rst;
  logic cr_new_gen;                 // Pulse to request computation of the next generation
  logic all_data_transmited;        // Flag indicating that the initial state has been fully loaded
  logic [9:0] init_state [9:0];     // 10x10 initial state grid
  logic [99:0] generation_triggers; // Flattened 100-bit output representing the current generation
  logic restart_timer;              // Output pulse indicating the timer should restart

  // Golden reference vector read from file for each generation
  logic [99:0] life_golden_line;

  // Clock period in nanoseconds
  localparam real CLK_PERIOD = 20.0;

  // Device under test: Game of Life logic
  game_logic #(.W(10), .H(10)) dut (
    .clk                 (clk),
    .rst                 (rst),
    .cr_new_gen          (cr_new_gen),
    .init_state          (init_state),
    .all_data_transmited (all_data_transmited),
    .generation_triggers (generation_triggers),
    .restart_timer       (restart_timer)
  );


  initial begin
    clk = 0;
    forever #(CLK_PERIOD / 2.0) clk = ~clk;
  end

  // Applies a reset pulse to the DUT
  task automatic apply_reset();
    rst                 <= 1'b1;
    cr_new_gen          <= 1'b0;
    all_data_transmited <= 1'b0;
    #(CLK_PERIOD * 2);
    @(negedge clk);
    rst                 <= 1'b0;
  endtask

  // Loads a 100-bit vector into the DUT's init_state grid,
  // asserts all_data_transmited, and verifies that:
  //   - restart_timer pulses high when data is transmitted
  //   - the DUT latches the initial state correctly
  task automatic load_initial_state(input logic [99:0] state_vec);
    // Unpack the flat vector into the 2D init_state array
    for (int Y = 0; Y < 10; Y++) begin
      for (int x = 0; x < 10; x++) begin
        init_state[Y][x] = state_vec[Y*10 + x];
      end
    end

    // Assert all_data_transmited for one clock cycle
    @(negedge clk);
    all_data_transmited <= 1'b1;
    @(posedge clk);
    @(negedge clk);
    all_data_transmited <= 1'b0;

    // restart_timer should be high right after transmission
    if (restart_timer !== 1'b1) $error("[FAIL] restart_timer should be high");

    // restart_timer should deassert on the next clock edge
    @(posedge clk);
    #1;
    if (restart_timer !== 1'b0) $error("[FAIL] restart_timer should be low");

    // Verify that the DUT latched the expected initial state
    if (generation_triggers === state_vec) begin
      $display("[PASS] Initial state loaded");
    end else begin
      $error("[FAIL] Initial state mismatch!\n  Got     : %0b\n  Expected: %0b",
             generation_triggers, state_vec);
    end
  endtask


  task automatic step_and_check(
    input int step_num,
    input logic [99:0] expected_val
  );
    // Pulse cr_new_gen to trigger one generation step
    @(negedge clk);
    cr_new_gen <= 1'b1;
    @(posedge clk);
    @(negedge clk);
    cr_new_gen <= 1'b0;

    // Wait for the result to propagate, then compare
    @(posedge clk);
    #1;
    if (generation_triggers === expected_val) begin
      $display("[PASS] Step %0d", step_num);
    end else begin
      $error("[FAIL] Step %0d\n  Got     : %0b\n  Expected: %0b",
             step_num, generation_triggers, expected_val);
    end
  endtask

  int fd;
  logic [99:0] expected_vector;

  // Main test sequence
  initial begin
    $dumpfile("dump.vcd");
    $dumpvars(0, test_bench_game_logic);

    cr_new_gen = 0;
    all_data_transmited = 0;
    for (int y = 0; y < 10; y++) init_state[y] = 10'b0;

    // Reset the DUT
    apply_reset();

    // Open the golden reference file (first line = initial state)
    fd = $fopen("life_golden_bin.mem", "r");
    if (fd == 0) $fatal(1, "Failed to open life_golden_bin.mem!");

    if ($fscanf(fd, "%b\n", life_golden_line) != 1)
      $fatal(1, "Failed to read initial line");

    $display("life_golden_reset_line:");
    $display("%0100b", life_golden_line);

    // Reverse bit order: file stores MSB-first, DUT expects LSB-first
    for (int i = 0; i < 100; i++) expected_vector[i] = life_golden_line[99 - i];

    #1;
    load_initial_state(expected_vector);

    // Step through 20 generations, comparing against golden data
    for (int step_counter = 1; step_counter <= 20; step_counter++) begin
      if ($fscanf(fd, "%b\n", life_golden_line) != 1)
        $fatal(1, "Failed to read line %0d", step_counter);
      for (int i = 0; i < 100; i++) expected_vector[i] = life_golden_line[99 - i];
      step_and_check(step_counter, expected_vector);
    end

    $fclose(fd);
    #(CLK_PERIOD * 10);
    $display("Simulation finished");
    $finish;
  end

endmodule