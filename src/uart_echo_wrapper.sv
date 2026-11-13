module uart_echo_wrapper #(
    parameter CLKS_PER_BIT = 217  // Baud rate config: (clk freq) / (baud rate)
)(
    input  logic       clk,
    input  logic       rst,         // Active high reset
    input  logic       rx_data,     // Serial data input
    output logic       tx_data,     // Serial data output
    output logic       rx_done,     // 1-clock pulse when data is received
    output logic [7:0] rx_data_out, // 8-bit received data
    output logic       error_flag   // Error flag (overrun)
);

    // Internal signals
    logic rst_l;
    logic tx_active;
    logic tx_done_sig;
	 logic rx_data_sync;
    
    // Invert reset for UART modules (they use active low reset i_Rst_L)
    assign rst_l = ~rst;

    // UART Receiver Instance
    UART_RX #(
        .CLKS_PER_BIT(CLKS_PER_BIT)
    ) rx_inst (
        .i_Rst_L    (rst_l),
        .i_Clock    (clk),
        .i_RX_Serial(rx_data_sync),
        .o_RX_DV    (rx_done),
        .o_RX_Byte  (rx_data_out)
    );

    // UART Transmitter Instance
    UART_TX #(
        .CLKS_PER_BIT(CLKS_PER_BIT)
    ) tx_inst (
        .i_Rst_L    (rst_l),
        .i_Clock    (clk),
        
        // Echo implementation: tie RX done flag to TX start, 
        // and RX output data to TX input data.
        .i_TX_DV    (rx_done),
        .i_TX_Byte  (rx_data_out),
        
        .o_TX_Active(tx_active),
        .o_TX_Serial(tx_data),
        .o_TX_Done  (tx_done_sig)
    );
    // UART Synchronizer Instance
    uart_synchronizer uart_synchronizer_inst(
	 .clk (clk),
	 .rst (rst),
	 .async_in (rx_data),
	 .sync_out (rx_data_sync)
	 );
    


endmodule