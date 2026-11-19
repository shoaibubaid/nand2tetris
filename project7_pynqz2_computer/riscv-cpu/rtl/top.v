`timescale 1ns/1ps

module top #(
    parameter IMEM_ADDR_WIDTH = 10,
    parameter IMEM_INIT_FILE = "../software/assembler/pong.hex",
    parameter DMEM_BYTES = 4096
)(
    // FPGA board clock and reset
    input wire ref_clk_125,
    input wire reset,

    // HDMI outputs
    output wire [2:0] hdmi_data_p,
    output wire [2:0] hdmi_data_n,
    output wire hdmi_clk_p,
    output wire hdmi_clk_n
);

    // CPU debug signals
    wire [31:0] pc;
    wire [31:0] instruction;
    wire instruction_valid;
    wire cpu_valid;

    // Clock generation
    wire pixel_clk;
    wire serial_clk;
    wire clock_locked;

    hdmi_clock_gen clock_generator (
        .ref_clk_125(ref_clk_125),
        .reset(reset),
        .pixel_clk(pixel_clk),
        .serial_clk(serial_clk),
        .locked(clock_locked)
    );

    wire video_reset;
    assign video_reset = reset | ~clock_locked;

    // Framebuffer interface
    wire [16:0] video_pixel_address;
    wire [7:0] video_pixel_data;

    // Temporarily disabled keyboard event interface
    wire ps_event_ready_unused;

    // CPU
    cpu #(
        .IMEM_ADDR_WIDTH(IMEM_ADDR_WIDTH),
        .IMEM_INIT_FILE(IMEM_INIT_FILE),
        .DMEM_BYTES(DMEM_BYTES)
    ) processor (
        .clk(ref_clk_125),
        .reset(reset),

        .ps_clk(ref_clk_125),
        .ps_reset(reset),
        .ps_event_valid(1'b0),
        .ps_event_ready(ps_event_ready_unused),
        .ps_event_data(9'b0),

        .video_pixel_address(video_pixel_address),
        .video_pixel_data(video_pixel_data),

        .pc_out(pc),
        .instruction_out(instruction),
        .instruction_valid(instruction_valid),
        .cpu_valid(cpu_valid)
    );

    // Video system
    video_system display_system (
        .pixel_clk(pixel_clk),
        .serial_clk(serial_clk),
        .reset(video_reset),

        .video_pixel_address(video_pixel_address),
        .video_pixel_data(video_pixel_data),

        .hdmi_data_p(hdmi_data_p),
        .hdmi_data_n(hdmi_data_n),
        .hdmi_clk_p(hdmi_clk_p),
        .hdmi_clk_n(hdmi_clk_n)
    );

endmodule
