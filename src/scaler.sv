module scaler (
    input logic [9:0] pixel_x,
    input logic [9:0] pixel_y,
    input logic [99:0] generation_triggers,
    output logic pixel
);

    // Проверка местоположения
    // По X: от 160 до 160 + 320 - 1 = 479
    // По Y: от 80 до 80 + 320 - 1 = 399
    logic in_field;
    assign in_field = (pixel_x >= 10'd160) && (pixel_x < 10'd480) && 
                      (pixel_y >= 10'd80)  && (pixel_y < 10'd400);

    // Сдвиг к левому верхнему углу поля
    logic [9:0] field_x, field_y;
    assign field_x = pixel_x - 10'd160;
    assign field_y = pixel_y - 10'd80;

    // Вычисление клетки. Отбрасываем младшие 5 бит, оставляем 4 бита (от 0 до 9)
    logic [3:0] cell_x, cell_y;
    assign cell_x = field_x[8:5];
    assign cell_y = field_y[8:5];

    // Умножение на 10
    logic [6:0] index;
    assign index = (cell_y * 10) + cell_x;

    always_comb begin
        if (in_field) begin
            pixel = generation_triggers[index];
        end else begin
            pixel = 1'b0; // Черное вокруг поля
        end
    end
endmodule