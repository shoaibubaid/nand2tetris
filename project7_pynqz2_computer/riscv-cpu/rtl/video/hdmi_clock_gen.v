
module hdmi_clock_gen (
    input  wire ref_clk_125,
    input  wire reset,

    output wire pixel_clk,
    output wire serial_clk,
    output wire locked
);

    wire clk_feedback_raw;
    wire clk_feedback;

    wire pixel_clk_raw;
    wire serial_clk_raw;

    MMCME2_BASE #(
        .BANDWIDTH("OPTIMIZED"),

        .CLKIN1_PERIOD(8.000),

        .DIVCLK_DIVIDE(1),

        .CLKFBOUT_MULT_F(8.000),
        .CLKFBOUT_PHASE(0.000),

        // 1000 MHz / 40 = 25 MHz
        .CLKOUT0_DIVIDE_F(40.000),
        .CLKOUT0_PHASE(0.000),
        .CLKOUT0_DUTY_CYCLE(0.500),

        // 1000 MHz / 8 = 125 MHz
        .CLKOUT1_DIVIDE(8),
        .CLKOUT1_PHASE(0.000),
        .CLKOUT1_DUTY_CYCLE(0.500),

        .STARTUP_WAIT("FALSE")
    ) mmcm_inst (
        .CLKIN1(ref_clk_125),

        .CLKFBIN(clk_feedback),
        .CLKFBOUT(clk_feedback_raw),

        .CLKOUT0(pixel_clk_raw),
        .CLKOUT1(serial_clk_raw),

        .CLKOUT2(),
        .CLKOUT3(),
        .CLKOUT4(),
        .CLKOUT5(),
        .CLKOUT6(),

        .LOCKED(locked),

        .PWRDWN(1'b0),
        .RST(reset)
    );

    // Global clock buffers
    BUFG feedback_buffer (
        .I(clk_feedback_raw),
        .O(clk_feedback)
    );

    BUFG pixel_buffer (
        .I(pixel_clk_raw),
        .O(pixel_clk)
    );

    BUFG serial_buffer (
        .I(serial_clk_raw),
        .O(serial_clk)
    );

endmodule
