module reset_button_controller #(
    parameter integer CLK_FREQ_HZ = 25_000_000, // Частота тактового генератора (например, 50 МГц)
    parameter integer DEBOUNCE_MS  = 10           // Время фильтрации дребезга в миллисекундах (10 мс)
)(
    input  wire clk,      // Тактовый сигнал
    input  wire button_n, // Сигнал с кнопки K3 (активный низкий: 0 - нажата, 1 - отпущена)
    output reg  rst       // Выходной сброс: активный высокий (1 - сброс активен, 0 - работа)
);

    // Вычисляем максимальное значение счетчика для заданной частоты
    localparam integer MAX_CNT = (CLK_FREQ_HZ / 1000) * DEBOUNCE_MS;
    localparam integer CNT_WIDTH = $clog2(MAX_CNT);

    reg [CNT_WIDTH-1:0] cnt;

    // Асинхронное срабатывание по нажатию (!button_n) 
    // и синхронное фильтрование дребезга при отпускании
    always @(posedge clk or negedge button_n) begin
        if (!button_n) begin
            rst <= 1'b1;               // Мгновенный асинхронный сброс при нажатии (активный высокий)
            cnt <= {CNT_WIDTH{1'b0}};  // Сбрасываем счетчик фильтра
        end else begin
            if (cnt < MAX_CNT) begin
                cnt <= cnt + 1'b1;
                rst <= 1'b1;           // Удерживаем сброс активным во время переходных процессов (дребезга)
            end else begin
                rst <= 1'b0;           // Снимаем сброс, когда кнопка стабильно отпущена
            end
        end
    end

endmodule