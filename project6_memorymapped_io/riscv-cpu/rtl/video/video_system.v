
module video_system (
    input wire pixel_clk,
    input wire serial_clk,
    input wire reset,

    // Framebuffer video read interface
    output wire [16:0] video_pixel_address,
    input wire [7:0] video_pixel_data,

    // HDMI differential outputs
    output wire [2:0] hdmi_data_p,
    output wire [2:0] hdmi_data_n,
    output wire hdmi_clk_p,
    output wire hdmi_clk_n
);

    // Video controller outputs
    wire [7:0] red;
    wire [7:0] green;
    wire [7:0] blue;

    wire video_active;
    wire hsync;
    wire vsync;

    // Encoded TMDS symbols
    wire [9:0] tmds_red;
    wire [9:0] tmds_green;
    wire [9:0] tmds_blue;

    // ------------------------------------------------
    // 1. Video controller
    // ------------------------------------------------

    video_controller video (
        .pixel_clk(pixel_clk),
        .reset(reset),

        .video_pixel_address(video_pixel_address),
        .video_pixel_data(video_pixel_data),

        .red(red),
        .green(green),
        .blue(blue),

        .video_active(video_active),
        .hsync(hsync),
        .vsync(vsync)
    );

    // ------------------------------------------------
    // 2. Red TMDS encoder
    // ------------------------------------------------

    tmds_encoder red_encoder (
        .pixel_clk(pixel_clk),
        .reset(reset),

        .video_enable(video_active),
        .video_data(red),

        .control_0(1'b0),
        .control_1(1'b0),

        .tmds_symbol(tmds_red)
    );

    // ------------------------------------------------
    // 3. Green TMDS encoder
    // ------------------------------------------------

    tmds_encoder green_encoder (
        .pixel_clk(pixel_clk),
        .reset(reset),

        .video_enable(video_active),
        .video_data(green),

        .control_0(1'b0),
        .control_1(1'b0),

        .tmds_symbol(tmds_green)
    );

    // ------------------------------------------------
    // 4. Blue TMDS encoder
    // ------------------------------------------------

    // Blue channel carries synchronization controls
    // during the blanking interval.

    tmds_encoder blue_encoder (
        .pixel_clk(pixel_clk),
        .reset(reset),

        .video_enable(video_active),
        .video_data(blue),

        .control_0(hsync),
        .control_1(vsync),

        .tmds_symbol(tmds_blue)
    );

    // ------------------------------------------------
    // 5. HDMI physical interface
    // ------------------------------------------------

    hdmi_phy phy (
        .pixel_clk(pixel_clk),
        .serial_clk(serial_clk),
        .reset(reset),

        .tmds_red(tmds_red),
        .tmds_green(tmds_green),
        .tmds_blue(tmds_blue),

        .hdmi_data_p(hdmi_data_p),
        .hdmi_data_n(hdmi_data_n),

        .hdmi_clk_p(hdmi_clk_p),
        .hdmi_clk_n(hdmi_clk_n)
    );

endmodule
