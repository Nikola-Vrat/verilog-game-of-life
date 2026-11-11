module init_state_controller #(
    parameter DATABITS = 8,                          // Input data width
    parameter HEADER_1_VALUE = 8'b11110000,          // First header signature
    parameter HEADER_2_VALUE = 8'b10101010,          // Second header signature
    parameter NUMBER_OF_DATA_PACKETS = 13            // Total data packets to receive
)(
    input  logic rst,
    input  logic clk,
    input  logic [DATABITS-1:0] data_from_rx,
    input  logic rx_done,
    input  logic error_flag,
    output logic write_data_to_matrix,
    output logic all_data_transmitted
);

    // Counter for received data packets
    logic [$clog2(NUMBER_OF_DATA_PACKETS):0] data_packets_counter;

    // FSM states
    typedef enum logic [1:0] {
        WAIT_HEADER_1 = 2'd0,
        WAIT_HEADER_2 = 2'd1,
        RECEIVE_DATA  = 2'd2,
        DONE          = 2'd3
    } state_e;

    state_e state, next_state;

    // State register update
    always_ff @(posedge clk or posedge rst) begin
        if (rst)
            state <= WAIT_HEADER_1;
        else
            state <= next_state;
    end

    // Next state logic
    always_comb begin
        next_state = state; // Default: hold current state
        
        case (state)
            WAIT_HEADER_1: begin
                if (!error_flag && rx_done && (data_from_rx == HEADER_1_VALUE)) begin
                    next_state = WAIT_HEADER_2;
                end
            end
            
            WAIT_HEADER_2: begin
                if (rx_done) begin
                    if (!error_flag && (data_from_rx == HEADER_2_VALUE)) begin
                        next_state = RECEIVE_DATA;
                    end else if (!error_flag && (data_from_rx == HEADER_1_VALUE)) begin
                        next_state = WAIT_HEADER_2; // Stay in state if repeated header 1
                    end else begin
                        next_state = WAIT_HEADER_1; // Invalid data, return to start
                    end
                end
            end
            
            RECEIVE_DATA: begin
                if (rx_done) begin
                    if (error_flag) begin
                        next_state = WAIT_HEADER_1; // Error resets FSM
                    end else if (data_packets_counter == (NUMBER_OF_DATA_PACKETS - 1)) begin
                        next_state = DONE;          // All packets received
                    end
                end
            end
            
            DONE: begin
                next_state = WAIT_HEADER_1;         // Restart reception cycle
            end
            
            default: begin
                next_state = WAIT_HEADER_1;
            end
        endcase
    end

    // Outputs and counter logic
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            data_packets_counter <= '0;
            write_data_to_matrix <= 1'b0;
            all_data_transmitted <= 1'b0;
        end else begin
            // Clear single-cycle outputs by default
            write_data_to_matrix <= 1'b0;
            all_data_transmitted <= 1'b0;

            if (state == WAIT_HEADER_1 || state == WAIT_HEADER_2) begin
                data_packets_counter <= '0;                   // Reset counter during header search
            end else if (state == RECEIVE_DATA && rx_done && !error_flag) begin
                write_data_to_matrix <= 1'b1;                 // Trigger data write
                data_packets_counter <= data_packets_counter + 1'b1;
            end else if (state == DONE) begin
                all_data_transmitted <= 1'b1;                 // Signal transmission complete
                data_packets_counter <= '0;
            end
        end
    end

endmodule