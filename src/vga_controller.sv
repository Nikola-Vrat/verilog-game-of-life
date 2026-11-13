module vga_controller (
    input  logic       clk_vga, 
    input  logic       rst,     
    input  logic       pixel,   
    output logic [9:0] pixel_x, 
    output logic [9:0] pixel_y, 
    output logic       hsync,   
    output logic       vsync,   
    output logic       vga_out  
);
    // Параметры экрана (по умолчанию 640х480)
    localparam h_visible     = 640;
    localparam h_front_porch = 16;
    localparam h_sync_width  = 96;   // Длительность hsync
    localparam h_back_porch  = 48;
    // "Интервал гашения" 16 + 96 + 48 = 160

    localparam v_visible     = 480;
    localparam v_front_porch = 10;
    localparam v_sync_width  = 2;    // Длительность vsync
    localparam v_back_porch  = 33;
    // Интервал гашения 10 + 2 + 33 = 45

    localparam h_total = h_visible + h_front_porch + h_sync_width + h_back_porch;    // Полная ширина
    localparam v_total = v_visible + v_front_porch + v_sync_width + v_back_porch;    // Полная высота

    localparam h_sync_begin = h_visible + h_front_porch;
    localparam h_sync_end   = h_sync_begin + h_sync_width - 1;

    localparam v_sync_begin = v_visible + v_front_porch;
    localparam v_sync_end   = v_sync_begin + v_sync_width - 1;

    logic [9:0] h_count, v_count;
    logic visible;

    always_ff @(posedge clk_vga or posedge rst) begin
        if (rst) begin
            h_count <= 0;
            v_count <= 0;
        end else begin
            if (h_count == h_total - 1) begin
                h_count <= 0;
                v_count <= (v_count == v_total - 1) ? 0 : v_count + 1;
            end else begin
                h_count <= h_count + 1;
            end
        end
    end

    assign pixel_x = h_count;
    assign pixel_y = v_count;

    assign hsync = ~(h_count >= h_sync_begin && h_count <= h_sync_end);
    assign vsync = ~(v_count >= v_sync_begin && v_count <= v_sync_end);

    assign visible = (h_count < h_visible) && (v_count < v_visible);

    always_ff @(posedge clk_vga or posedge rst) begin    // Триггер, который делает область вокруг поля игры черной
        if (rst) begin
            vga_out <= 1'b0;
        end else begin
            vga_out <= visible ? pixel : 1'b0;
        end
    end

endmodule
