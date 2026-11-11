module matrix_writer #(
    parameter int W        = 10, // Matrix width (number of columns)
    parameter int H        = 10, // Matrix height (number of rows)
    parameter int DATABITS = 8 // Input data word width
)( 
    input  logic                  clk,
    input  logic                  rst,

    // Data reception interface
    input  logic [DATABITS-1:0]   rx_data_out,
    input  logic                  write_data_to_matrix,

    // Output 2D matrix
    output logic [W-1:0]          init_state [H-1:0]
);

    localparam int TOTAL_BITS = W * H;

    // Internal linear shift register
    logic [TOTAL_BITS-1:0] shift_reg;

    // Shift register logic: shifts incoming data from MSB towards LSB
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            shift_reg <= '0;
        end else if (write_data_to_matrix) begin
            shift_reg <= {rx_data_out, shift_reg[TOTAL_BITS-1 : DATABITS]};
        end
    end

    // Combinational mapping: 1D flat register -> 2D array
    always_comb begin
        for (int y = 0; y < H; y++) begin
            init_state[y] = shift_reg[y * W +: W];
        end
    end

endmodule