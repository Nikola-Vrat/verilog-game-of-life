module new_init_state_light_controller #(
    parameter integer CLK_FREQ_HZ = 25_000_000, // Частота тактового генератора (например, 50 МГц)
    parameter integer DEBOUNCE_MS  = 10           
)(
    input  wire clk,      // Тактовый сигнал
    input  wire all_data_transmitted,
    output reg  new_init_state_light      
);

    // Вычисляем максимальное значение счетчика для заданной частоты
    localparam integer MAX_CNT = (CLK_FREQ_HZ / 1000) * DEBOUNCE_MS;
    localparam integer CNT_WIDTH = $clog2(MAX_CNT);

    reg [CNT_WIDTH-1:0] cnt;


    always @(posedge clk) begin
        if (all_data_transmitted) begin
            new_init_state_light <= 1'b0;         
            cnt <= {CNT_WIDTH{1'b0}};  
        end else begin
            if (cnt < MAX_CNT) begin
                cnt <= cnt + 1'b1;
                new_init_state_light <= 1'b0;         
            end else begin
                new_init_state_light <= 1'b1;        
            end
        end
    end

endmodule