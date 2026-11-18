
module video_controller (
    input  wire       pixel_clk,
    input  wire       reset,

    // Framebuffer video read interface
    output reg  [16:0] video_pixel_address,
    input  wire [7:0]  video_pixel_data,

    // Display outputs
    output wire [7:0] red,
    output wire [7:0] green,
    output wire [7:0] blue,

    output reg        video_active,
    output reg        hsync,
    output reg        vsync
);

    wire [9:0] pixel_x;
    wire [9:0] pixel_y;

    wire timing_active;
    wire timing_hsync;
    wire timing_vsync;

    // Timing generator
    video_timing timing (
        .pixel_clk(pixel_clk),
        .reset(reset),
        .pixel_x(pixel_x),
        .pixel_y(pixel_y),
        .video_active(timing_active),
        .hsync(timing_hsync),
        .vsync(timing_vsync)
    );

    // Source framebuffer coordinates.
    // Each source pixel occupies a 2x2 display area.
    wire [8:0] source_x;
    wire [8:0] source_y;

    assign source_x = {1'b0, pixel_x[9:1]};
    assign source_y = {1'b0, pixel_y[9:1]};

    // 320 * source_y = (source_y << 8) + (source_y << 6)
    wire [16:0] row_offset;

    assign row_offset =
        ({8'd0, source_y} << 8) +
        ({8'd0, source_y} << 6);

    wire [16:0] calculated_address;

    assign calculated_address =
        row_offset + source_x;

    // Address for the synchronous framebuffer read port.
    always @(*) begin
        if (timing_active)
            video_pixel_address = calculated_address;
        else
            video_pixel_address = 17'd0;
    end

    // Align timing signals with the one-cycle framebuffer read.
    always @(posedge pixel_clk) begin
        if (reset) begin
            video_active <= 1'b0;
            hsync        <= 1'b1;
            vsync        <= 1'b1;
        end
        else begin
            video_active <= timing_active;
            hsync        <= timing_hsync;
            vsync        <= timing_vsync;
        end
    end

    // RGB332 to RGB888 conversion.
    wire [2:0] red_3;
    wire [2:0] green_3;
    wire [1:0] blue_2;

    assign red_3   = video_pixel_data[7:5];
    assign green_3 = video_pixel_data[4:2];
    assign blue_2  = video_pixel_data[1:0];

    wire [7:0] expanded_red;
    wire [7:0] expanded_green;
    wire [7:0] expanded_blue;

    assign expanded_red =
        {red_3, red_3, red_3[2:1]};

    assign expanded_green =
        {green_3, green_3, green_3[2:1]};

    assign expanded_blue =
        {blue_2, blue_2, blue_2, blue_2};

    // Output black during blanking.
    assign red   = video_active ? expanded_red   : 8'd0;
    assign green = video_active ? expanded_green : 8'd0;
    assign blue  = video_active ? expanded_blue  : 8'd0;

endmodule
