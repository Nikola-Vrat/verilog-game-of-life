`timescale 1ns / 1ps

module testbench_vga_controller();

    // Input signals
    logic clk_vga;
    logic rst;
    logic pixel;

    // Output signals
    logic [9:0] pixel_x;
    logic [9:0] pixel_y;
    logic hsync;
    logic vsync;
    logic vga_out;

    // Instantiate the DUT
    vga_controller uut (
        .clk_vga(clk_vga),
        .rst(rst),
        .pixel(pixel),
        .pixel_x(pixel_x),
        .pixel_y(pixel_y),
        .hsync(hsync),
        .vsync(vsync),
        .vga_out(vga_out)
    );

    localparam int SCREEN_WIDTH   = 800;
    localparam int SCREEN_HEIGHT  = 525;
    localparam int SCREEN_GAME_ZONE = 320;

    localparam int FIRST_HORIZONTAL_EDGE_PLAY_FIELD  = 160;
    localparam int SECOND_HORIZONTAL_EDGE_PLAY_FIELD = 480;
    localparam int FIRST_VERTICAL_EDGE_PLAY_FIELD    = 80;
    localparam int SECOND_VERTICAL_EDGE_PLAY_FIELD   = 400;

    localparam int VISIBLE_SCREEN_WIDTH  = 640;
    localparam int VISIBLE_SCREEN_HEIGHT = 480;

    localparam int HORIZONTAL_FRONT_PORCH = 16;
    localparam int HORIZONTAL_SYNC_PULSE  = 96;   
    localparam int HORIZONTAL_BACK_PORCH  = 48;
    localparam int VERTICAL_FRONT_PORCH   = 10;
    localparam int VERTICAL_SYNC_PULSE    = 2;   
    localparam int VERTICAL_BACK_PORCH    = 33;

    // Memory arrays
    logic [0:SCREEN_GAME_ZONE-1] screen_matrix [0:SCREEN_GAME_ZONE-1];
    logic [0:SCREEN_WIDTH-1] extended_matrix [0:SCREEN_HEIGHT-1];

    // 25 MHz clock generation
    initial begin
        clk_vga = 0;
        forever #20 clk_vga = ~clk_vga;
    end

    // Delay coordinates by 1 clock to align with registered vga_out
    logic [9:0] pixel_x_d, pixel_y_d;
    always_ff @(posedge clk_vga) begin
        if (rst) begin
            pixel_x_d <= 0;
            pixel_y_d <= 0;
        end else begin
            pixel_x_d <= pixel_x;
            pixel_y_d <= pixel_y;
        end
    end


    always_comb begin
        if (pixel_x >= FIRST_HORIZONTAL_EDGE_PLAY_FIELD-1 && pixel_x <= SECOND_HORIZONTAL_EDGE_PLAY_FIELD-2 && pixel_y >= FIRST_VERTICAL_EDGE_PLAY_FIELD-1 && pixel_y <= SECOND_VERTICAL_EDGE_PLAY_FIELD-2) begin
            pixel = screen_matrix[pixel_y - (FIRST_VERTICAL_EDGE_PLAY_FIELD-1)][pixel_x - (FIRST_HORIZONTAL_EDGE_PLAY_FIELD-1)];
        end else begin
            pixel = 1'b0;
        end
    end

    // Main checker
    integer errors = 0;
    integer frames = 0;
    logic exp_hsync, exp_vsync;

    initial begin
        // Load reference files
        $readmemb("screen_matrix_random_bin.mem", screen_matrix);
        $readmemb("screen_matrix_random_extended_bin.mem", extended_matrix);

        // Reset
        rst = 1;
        #100;
        @(negedge clk_vga);
        rst = 0;

        // Check for 2 full frames
        while (frames < 2) begin
            @(negedge clk_vga);

            if (!rst) begin
                // Check registered video output
                if (vga_out !== extended_matrix[pixel_y_d][pixel_x_d]) begin
                    $display("ERROR vga_out at (%0d, %0d): got=%b, expected=%b",
                             pixel_x_d, pixel_y_d, vga_out, extended_matrix[pixel_y_d][pixel_x_d]);
                    errors++;
                end

                // Check sync signals
                exp_hsync = ~(pixel_x >= (VISIBLE_SCREEN_WIDTH + HORIZONTAL_FRONT_PORCH) && pixel_x <= (VISIBLE_SCREEN_WIDTH + HORIZONTAL_FRONT_PORCH + HORIZONTAL_SYNC_PULSE - 1));
                exp_vsync = ~(pixel_y >= (VISIBLE_SCREEN_HEIGHT + VERTICAL_FRONT_PORCH) && pixel_y <= (VISIBLE_SCREEN_HEIGHT + VERTICAL_FRONT_PORCH + VERTICAL_SYNC_PULSE - 1));

                if (hsync !== exp_hsync) begin
                    $display("ERROR HSYNC at (%0d, %0d): got=%b, expected=%b",
                             pixel_x, pixel_y, hsync, exp_hsync);
                    errors++;
                end

                if (vsync !== exp_vsync) begin
                    $display("ERROR VSYNC at (%0d, %0d): got=%b, expected=%b",
                             pixel_x, pixel_y, vsync, exp_vsync);
                    errors++;
                end

                // Count completed frames
                if (pixel_x == SCREEN_WIDTH-1 && pixel_y == SCREEN_HEIGHT-1) begin
                    frames++;
                    $display("Frame %0d checked successfully.", frames);
                end
            end
        end

        if (errors == 0) begin
            $display("TEST PASSED: All pixels and sync signals match the reference matrices!");
        end else begin
            $display("TEST FAILED: Found %0d errors.", errors);
        end

        $finish;
    end
endmodule