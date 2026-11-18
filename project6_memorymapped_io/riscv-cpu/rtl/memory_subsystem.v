
`timescale 1ns/1ps

module memory_subsystem #(
    parameter integer CLK_HZ = 100_000_000
)(
    input wire clk,
    input wire reset,

    // ------------------------------------------------
    // CPU memory interface
    // ------------------------------------------------

    input wire req,
    input wire mem_read,
    input wire mem_write,
    input wire [31:0] address,
    input wire [31:0] write_data,
    input wire [2:0] funct3,

    // ------------------------------------------------
    // Video interface
    // ------------------------------------------------

    input wire [16:0] video_pixel_address,
    output wire [7:0] video_pixel_data,

    // ------------------------------------------------
    // USB keyboard events from Zynq Processing System
    // ------------------------------------------------

    input wire ps_clk,
    input wire ps_reset,
    input wire ps_event_valid,
    output wire ps_event_ready,
    input wire [8:0] ps_event_data,

    // ------------------------------------------------
    // CPU memory response
    // ------------------------------------------------

    output wire ready,
    output wire [31:0] read_data,
    output wire access_error
);

    // =================================================
    // ADDRESS DECODER
    // =================================================

    wire select_ram;
    wire select_framebuffer;
    wire select_keyboard;
    wire select_timer;
    wire address_valid;

    wire [13:0] ram_offset;
    wire [16:0] framebuffer_offset;
    wire [3:0] keyboard_offset;
    wire [3:0] timer_offset;

    address_decoder decoder (
        .address(address),

        .select_ram(select_ram),
        .select_framebuffer(select_framebuffer),
        .select_keyboard(select_keyboard),
        .select_timer(select_timer),

        .address_valid(address_valid),

        .ram_offset(ram_offset),
        .framebuffer_offset(framebuffer_offset),
        .keyboard_offset(keyboard_offset),
        .timer_offset(timer_offset)
    );


    // =================================================
    // MAIN RAM CONTROLLER
    // =================================================

    wire ram_ready;
    wire [31:0] ram_read_data;
    wire ram_access_error;

    data_memory ram_controller (
        .clk(clk),
        .reset(reset),

        .req(req && select_ram),
        .mem_read(mem_read),
        .mem_write(mem_write),

        .address(address),
        .write_data(write_data),
        .funct3(funct3),

        .ready(ram_ready),
        .read_data(ram_read_data),
        .access_error(ram_access_error)
    );


    // =================================================
    // FRAMEBUFFER CONTROLLER
    // =================================================

    wire framebuffer_ready;
    wire [31:0] framebuffer_read_data;
    wire framebuffer_access_error;

    framebuffer framebuffer_controller (
        .clk(clk),
        .reset(reset),

        .req(req && select_framebuffer),
        .mem_read(mem_read),
        .mem_write(mem_write),

        .offset(framebuffer_offset),
        .write_data(write_data),
        .funct3(funct3),

        .ready(framebuffer_ready),
        .read_data(framebuffer_read_data),
        .access_error(framebuffer_access_error),

        .video_pixel_address(video_pixel_address),
        .video_pixel_data(video_pixel_data)
    );


    // =================================================
    // USB KEYBOARD CLOCK DOMAIN CROSSING
    // =================================================

    wire cpu_event_valid;
    wire cpu_event_ready;
    wire [8:0] cpu_event_data;

    usb_keyboard_bridge keyboard_bridge (
        .ps_clk(ps_clk),
        .ps_reset(ps_reset),
        .ps_event_valid(ps_event_valid),
        .ps_event_ready(ps_event_ready),
        .ps_event_data(ps_event_data),

        .cpu_clk(clk),
        .cpu_reset(reset),
        .cpu_event_valid(cpu_event_valid),
        .cpu_event_ready(cpu_event_ready),
        .cpu_event_data(cpu_event_data)
    );


    // =================================================
    // KEYBOARD MMIO CONTROLLER
    // =================================================

    wire keyboard_ready;
    wire [31:0] keyboard_read_data;
    wire keyboard_access_error;

    keyboard_controller keyboard_controller (
        .clk(clk),
        .reset(reset),

        .event_valid(cpu_event_valid),
        .event_ready(cpu_event_ready),
        .event_data(cpu_event_data),

        .req(req && select_keyboard),
        .mem_read(mem_read),
        .mem_write(mem_write),

        .offset(keyboard_offset),
        .write_data(write_data),
        .funct3(funct3),

        .ready(keyboard_ready),
        .read_data(keyboard_read_data),
        .access_error(keyboard_access_error)
    );


    // =================================================
    // TIMER CONTROLLER
    // =================================================

    wire timer_ready;
    wire [31:0] timer_read_data;
    wire timer_access_error;

    timer #(
        .CLK_HZ(CLK_HZ)
    ) timer_controller (
        .clk(clk),
        .reset(reset),

        .req(req && select_timer),
        .mem_read(mem_read),
        .mem_write(mem_write),

        .offset(timer_offset),
        .write_data(write_data),
        .funct3(funct3),

        .ready(timer_ready),
        .read_data(timer_read_data),
        .access_error(timer_access_error)
    );


    // =================================================
    // INVALID ADDRESS RESPONSE
    // =================================================

    wire invalid_ready = req && !address_valid;


    // =================================================
    // OVERALL READY RESPONSE
    // =================================================

    assign ready =
        (select_ram         && ram_ready) ||
        (select_framebuffer && framebuffer_ready) ||
        (select_keyboard    && keyboard_ready) ||
        (select_timer       && timer_ready) ||
        invalid_ready;


    // =================================================
    // READ DATA MULTIPLEXER
    // =================================================

    assign read_data =
        select_ram         ? ram_read_data :
        select_framebuffer ? framebuffer_read_data :
        select_keyboard    ? keyboard_read_data :
        select_timer       ? timer_read_data :
        32'b0;


    // =================================================
    // ACCESS ERROR MULTIPLEXER
    // =================================================

    assign access_error =
        (select_ram         && ram_access_error) ||
        (select_framebuffer && framebuffer_access_error) ||
        (select_keyboard    && keyboard_access_error) ||
        (select_timer       && timer_access_error) ||
        invalid_ready;

endmodule
