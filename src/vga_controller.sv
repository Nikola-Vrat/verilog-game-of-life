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

    logic [9:0] h_count, v_count;
    logic visible;

    always_ff @(posedge clk_vga or posedge rst) begin
        if (rst) begin
            h_count <= 0;
            v_count <= 0;
        end else begin
            if (h_count == 799) begin
                h_count <= 0;
                v_count <= (v_count == 524) ? 0 : v_count + 1;
            end else begin
                h_count <= h_count + 1;
            end
        end
    end

    // 1. Выдаем координаты без мультиплексоров
    assign pixel_x = h_count;
    assign pixel_y = v_count;

    assign hsync = ~(h_count >= 656 && h_count <= 751);
    assign vsync = ~(v_count >= 490 && v_count <= 491);

    assign visible = (h_count < 640) && (v_count < 480);

    always_ff @(posedge clk_vga or posedge rst) begin
        if (rst) begin
            vga_out <= 1'b0;
        end else begin
            vga_out <= visible ? pixel : 1'b0;
        end
    end
endmodule