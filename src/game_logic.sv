module game_logic #(
    parameter W = 10,
    parameter H = 10
)(
    input wire clk,
    input wire rst,
    input wire cr_new_gen,

    // Получаем готовую матрицу от matrix_writer
    input wire [W-1:0] init_state [H-1:0],

    // Получаем сигнал завершения от init_state_controller
    input wire all_data_transmited,

    output wire [W*H-1:0] generation_triggers,

    // Команда перезапуска таймера
    output wire restart_timer
);

reg load_state_pending;
reg  [W-1:0] current_grid [0:H-1];
wire [W-1:0] next_grid    [0:H-1]; 

// Хранит последнюю успешно загруженную матрицу
reg [W-1:0] saved_state [0:H-1];
always @(posedge clk or posedge rst) begin
    if (rst)
        load_state_pending <= 1'b0;
    else
        load_state_pending <= all_data_transmited;
end

assign restart_timer = load_state_pending;
                               
genvar y, x;
generate
    for (y = 0; y < H; y = y + 1) begin : gen_y
        for (x = 0; x < W; x = x + 1) begin : gen_x
            localparam ym = (y == 0)     ? H - 1 : y - 1; // Строка сверху (тор)
            localparam yp = (y == H - 1) ? 0     : y + 1; // Строка снизу (тор)
            localparam xm = (x == 0)     ? W - 1 : x - 1; // Столбец слева (тор)
            localparam xp = (x == W - 1) ? 0     : x + 1; // Столбец справа (тор)

            // Подсчет 8 живых соседей
            wire [3:0] neighbors = 
                current_grid[ym][xm] + current_grid[ym][x] + current_grid[ym][xp] +
                current_grid[y ][xm]                       + current_grid[y ][xp] +
                current_grid[yp][xm] + current_grid[yp][x] + current_grid[yp][xp];

            // Логика перехода
            assign next_grid[y][x] = (current_grid[y][x]) 
                ? (neighbors == 4'd2 || neighbors == 4'd3) 
                : (neighbors == 4'd3);

            // Вывод на выходную шину: index = y * 10 + x
            assign generation_triggers[(H - 1 - y) * W + x] = current_grid[y][x];
        end
    end
endgenerate

integer r_idx;

always @(posedge clk) begin
    if (rst) begin

        for (r_idx = 0; r_idx < H; r_idx = r_idx + 1) begin
            current_grid[r_idx] <= saved_state[r_idx];
        end
    end else if (load_state_pending) begin

        // Заменяем старое игровое поле новым
        for (r_idx = 0; r_idx < H; r_idx = r_idx + 1) begin

            current_grid[r_idx] <=
                init_state[H-1-r_idx];
            saved_state[r_idx] <=
                init_state[H-1-r_idx];
        end
    end else if (cr_new_gen) begin

        for (r_idx = 0; r_idx < H; r_idx = r_idx + 1) begin
            current_grid[r_idx] <= next_grid[r_idx];
        end
    end 
end
    
endmodule



