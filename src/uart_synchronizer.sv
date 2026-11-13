module uart_synchronizer (
    input  logic clk,
    input  logic rst,
    input  logic async_in,
    output logic sync_out
);

    logic reg_1;

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            reg_1    <= 1'b1;
            sync_out <= 1'b1;
        end else begin
            reg_1    <= async_in; // Первый каскад (ловит метастабильность)
            sync_out <= reg_1;    // Второй каскад (выдает чистый сигнал)
        end
    end

endmodule