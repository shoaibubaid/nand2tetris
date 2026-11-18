
`timescale 1ns/1ps

module memory_subsystem (
    input wire clk,
    input wire reset,

    input wire req,
    input wire mem_read,
    input wire mem_write,

    input wire [31:0] address,
    input wire [31:0] write_data,
    input wire [2:0] funct3,

    output wire ready,
    output wire [31:0] read_data,
    output wire access_error
);

    // Address decoder outputs
    wire select_ram;
    wire select_framebuffer;
    wire select_keyboard;
    wire select_timer;
    wire address_valid;

    wire [13:0] ram_offset;
    wire [16:0] framebuffer_offset;
    wire [3:0] keyboard_offset;
    wire [3:0] timer_offset;

    // RAM controller outputs
    wire ram_ready;
    wire [31:0] ram_read_data;
    wire ram_access_error;

    // Framebuffer controller outputs
    wire framebuffer_ready;
    wire [31:0] framebuffer_read_data;
    wire framebuffer_access_error;

    // Decoder
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

    // Main RAM controller
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


    // Framebuffer controller
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
        .access_error(framebuffer_access_error)
    );
    

    // Keyboard and timer remain temporary endpoints.
    wire other_peripheral_selected =
        select_keyboard || select_timer;

    wire other_peripheral_ready =
        req && other_peripheral_selected;

    // Invalid address response
    wire invalid_ready = req && !address_valid;

    // Overall ready response
    assign ready =
        (select_ram && ram_ready) ||
        (select_framebuffer && framebuffer_ready) ||
        other_peripheral_ready ||
        invalid_ready;

    // Read-data selection
    assign read_data =
        select_ram ? ram_read_data :
        select_framebuffer ? framebuffer_read_data :
        32'b0;

    // Error selection
    assign access_error =
        (select_ram && ram_access_error) ||
        (select_framebuffer && framebuffer_access_error) ||
        invalid_ready;

endmodule
