module blink(
    input clk,
    output blink_out
);

// Счетчик для деления частоты 25 МГц до частоты мигания 1 Гц (период 1 секунда: 0.5 сек вкл, 0.5 сек выкл)
// 25,000,000 / 2 = 12,500,000 тактов на полупериод
logic [23:0] counter = 24'd0;

    always @(posedge clk) begin
        if (counter == 24'd12499999) begin
            counter <= 24'd0;
            blink_out <= ~blink_out;
        end else begin
            counter <= counter + 1'b1;
        end
    end

endmodule







