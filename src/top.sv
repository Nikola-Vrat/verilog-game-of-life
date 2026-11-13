module top (
    input  logic clk_in,
    input  logic RESET_BUTTON,
    input  logic RX_DATA,
    output logic RESET_LIGHT,
    output logic BLINK_OUT,
    output logic NEW_GEN_LIGHT,
    output logic VGA_OUT,
    output logic HSYNC,
    output logic VSYNC,
    output logic NEW_INIT_STATE_LIGHT,
    output logic TX_DATA,
    output logic RX_BLINK
);

    // --- Parameters ---
    localparam int W        = 10;
    localparam int H        = 10;
    localparam int DATABITS = 8;

    localparam int CLK_FREQ  = 25_000_000;
    localparam int BAUD_RATE = 115200;
	 
	 localparam int HEADER_1_VALUE = 8'b01010101;
    localparam int HEADER_2_VALUE = 8'b10101010;
	 localparam int DEBOUNCE_MS = 500;
	 localparam int NUMBER_OF_DATA_PACKETS = W * H / DATABITS + 1;
    // --- Internal Signals ---
    // Clock & Reset
    logic clk_pll;
    logic pll_locked;
    logic rst;
    logic restart_timer;

    // VGA & Graphics
    logic           pixel;
    logic [9:0]     pixel_x;
    logic [9:0]     pixel_y;
    logic [W*H-1:0] generation_triggers;
    logic           cr_new_gen;

    // UART & Communication
    logic [DATABITS-1:0] rx_data_out;
    logic                rx_done;
    logic                error_flag;
    logic                write_data_to_matrix;
    logic                all_data_transmitted;
    
    // Game State
    logic [W-1:0] init_state [H-1:0];

    // --- Continuous Assignments ---
    assign RESET_LIGHT = ~(rst || !pll_locked);
    assign RX_BLINK    = RX_DATA;

    // --- Clock & System Modules ---
    
    // Main PLL for system clock generation
    pll pll_inst (
        .areset (1'b0),       
        .inclk0 (clk_in),    
        .c0     (clk_pll),   
        .locked (pll_locked) 
    );

    reset_button_controller #(
        .CLK_FREQ_HZ  (CLK_FREQ), 
        .DEBOUNCE_MS  (10)
    ) reset_button_controller_inst (
        .clk      (clk_in),      
        .button_n (RESET_BUTTON), 
        .rst      (rst)       
    );

    blink blink_inst (
        .clk       (clk_pll),
        .blink_out (BLINK_OUT)
    );

    // --- VGA Controller & Scaling ---
    
    vga_controller vga_controller_inst (
        .clk_vga (clk_pll),
        .rst     (rst || !pll_locked),
        .pixel   (pixel),
        .pixel_x (pixel_x), 
        .pixel_y (pixel_y), 
        .hsync   (HSYNC),   
        .vsync   (VSYNC),   
        .vga_out (VGA_OUT)  
    ); 

    scaler scaler_inst (
        .pixel_x             (pixel_x),
        .pixel_y             (pixel_y),
        .generation_triggers (generation_triggers), 
        .pixel               (pixel)
    );

    // --- Game Logic & Timers ---

    clk_divider #(
        .COUNT_MAX (CLK_FREQ)
    ) clk_divider_inst (
        .clk        (clk_pll),
        .rst        (rst || restart_timer || !pll_locked),
        .cr_new_gen (cr_new_gen)
    );

    new_gen_light_controller #(CLK_FREQ, DEBOUNCE_MS) new_gen_light_controller_inst (
        .clk           (clk_pll),      
        .new_gen       (cr_new_gen), 
        .new_gen_light (NEW_GEN_LIGHT)       
    );
     
    new_init_state_light_controller #(CLK_FREQ, DEBOUNCE_MS) new_init_state_light_controller_inst (
        .clk                  (clk_pll),
        .all_data_transmitted (all_data_transmitted),
        .new_init_state_light (NEW_INIT_STATE_LIGHT)
    );

    game_logic #(
        .W (W),
        .H (H)
    ) game_logic_inst (
        .clk                 (clk_pll),
        .rst                 (rst || !pll_locked),
        .cr_new_gen          (cr_new_gen),
        .init_state          (init_state),
        .all_data_transmited (all_data_transmitted),
        .generation_triggers (generation_triggers),
        .restart_timer       (restart_timer)
    );

    // --- UART & State Initialization ---

    // UART Transceiver (Echo)
    uart_echo_wrapper #(
        .CLKS_PER_BIT (CLK_FREQ / BAUD_RATE)
    ) uart_echo_wrapper_inst (
        .clk         (clk_pll),
        .rst         (rst || !pll_locked),
        .rx_data     (RX_DATA),
        .tx_data     (TX_DATA),
        .rx_done     (rx_done),
        .rx_data_out (rx_data_out),
        .error_flag  (error_flag)
    );
    
    // Initial state packet reception controller
    init_state_controller #(
        .DATABITS               (DATABITS),
        .HEADER_1_VALUE         (HEADER_1_VALUE),
        .HEADER_2_VALUE         (HEADER_2_VALUE),
        .NUMBER_OF_DATA_PACKETS (13)
    ) init_state_controller_inst (
        .rst                  (rst || !pll_locked),
        .clk                  (clk_pll),
        .data_from_rx         (rx_data_out),
        .rx_done              (rx_done),
        .error_flag           (1'b0),
        .write_data_to_matrix (write_data_to_matrix),
        .all_data_transmitted (all_data_transmitted)
    );

    // Write received bytes into the internal state matrix
    matrix_writer #(
        .W        (W),
        .H        (H),
        .DATABITS (DATABITS)
    ) matrix_writer_inst (
        .clk                  (clk_pll),
        .rst                  (rst || !pll_locked),
        .rx_data_out          (rx_data_out),
        .write_data_to_matrix (write_data_to_matrix),
        .init_state           (init_state)
    );

endmodule