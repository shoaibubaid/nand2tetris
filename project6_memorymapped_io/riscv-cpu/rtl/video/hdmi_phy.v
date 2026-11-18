
module hdmi_phy (
    input wire pixel_clk,
    input wire serial_clk,
    input wire reset,

    // 10-bit TMDS symbols
    input wire [9:0] tmds_red,
    input wire [9:0] tmds_green,
    input wire [9:0] tmds_blue,

    // HDMI differential data lanes
    // Lane 0 = Blue
    // Lane 1 = Green
    // Lane 2 = Red
    output wire [2:0] hdmi_data_p,
    output wire [2:0] hdmi_data_n,

    // HDMI differential clock lane
    output wire hdmi_clk_p,
    output wire hdmi_clk_n
);

    // ------------------------------------------------
    // Serialized TMDS signals
    // ------------------------------------------------

    wire serial_red;
    wire serial_green;
    wire serial_blue;

    // ------------------------------------------------
    // Red serializer - HDMI lane 2
    // ------------------------------------------------

    tmds_serializer serializer_red (
        .pixel_clk(pixel_clk),
        .serial_clk(serial_clk),
        .reset(reset),
        .parallel_data(tmds_red),
        .serial_data(serial_red)
    );

    // ------------------------------------------------
    // Green serializer - HDMI lane 1
    // ------------------------------------------------

    tmds_serializer serializer_green (
        .pixel_clk(pixel_clk),
        .serial_clk(serial_clk),
        .reset(reset),
        .parallel_data(tmds_green),
        .serial_data(serial_green)
    );

    // ------------------------------------------------
    // Blue serializer - HDMI lane 0
    // ------------------------------------------------

    tmds_serializer serializer_blue (
        .pixel_clk(pixel_clk),
        .serial_clk(serial_clk),
        .reset(reset),
        .parallel_data(tmds_blue),
        .serial_data(serial_blue)
    );

    // ------------------------------------------------
    // Physical differential output buffers
    // ------------------------------------------------

`ifdef XILINX

    // Blue data lane
    OBUFDS #(
        .IOSTANDARD("TMDS_33")
    ) data_buffer_0 (
        .I(serial_blue),
        .O(hdmi_data_p[0]),
        .OB(hdmi_data_n[0])
    );

    // Green data lane
    OBUFDS #(
        .IOSTANDARD("TMDS_33")
    ) data_buffer_1 (
        .I(serial_green),
        .O(hdmi_data_p[1]),
        .OB(hdmi_data_n[1])
    );

    // Red data lane
    OBUFDS #(
        .IOSTANDARD("TMDS_33")
    ) data_buffer_2 (
        .I(serial_red),
        .O(hdmi_data_p[2]),
        .OB(hdmi_data_n[2])
    );

    // Differential pixel clock
    OBUFDS #(
        .IOSTANDARD("TMDS_33")
    ) clock_buffer (
        .I(pixel_clk),
        .O(hdmi_clk_p),
        .OB(hdmi_clk_n)
    );

`else

    // ------------------------------------------------
    // Behavioral differential outputs for simulation
    // ------------------------------------------------

    assign hdmi_data_p[0] = serial_blue;
    assign hdmi_data_n[0] = ~serial_blue;

    assign hdmi_data_p[1] = serial_green;
    assign hdmi_data_n[1] = ~serial_green;

    assign hdmi_data_p[2] = serial_red;
    assign hdmi_data_n[2] = ~serial_red;

    assign hdmi_clk_p = pixel_clk;
    assign hdmi_clk_n = ~pixel_clk;

`endif

endmodule
