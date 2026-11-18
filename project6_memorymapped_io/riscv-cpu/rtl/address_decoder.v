
`timescale 1ns/1ps

module address_decoder (

    input wire [31:0] address,

    output reg select_ram,
    output reg select_framebuffer,
    output reg select_keyboard,
    output reg select_timer,

    output reg address_valid,

    // Device-relative addresses
    output wire [13:0] ram_offset,
    output wire [16:0] framebuffer_offset,
    output wire [3:0] keyboard_offset,
    output wire [3:0] timer_offset

);

    // --------------------------------------------
    // Memory map
    // --------------------------------------------

    localparam RAM_START = 32'h00000000;
    localparam RAM_END   = 32'h00003FFF;

    localparam FB_START  = 32'h10000000;
    localparam FB_END    = 32'h10012BFF;

    localparam KB_START  = 32'h20000000;
    localparam KB_END    = 32'h2000000F;

    localparam TIMER_START = 32'h20000010;
    localparam TIMER_END   = 32'h2000001F;


    // --------------------------------------------
    // Device-relative addresses
    // --------------------------------------------

    assign ram_offset = address[13:0];

    assign framebuffer_offset =
        address - FB_START;

    assign keyboard_offset =
        address[3:0];

    assign timer_offset =
        address - TIMER_START;


    // --------------------------------------------
    // Address decoding
    // --------------------------------------------

    always @(*) begin

        // Default: no device selected.
        select_ram = 1'b0;
        select_framebuffer = 1'b0;
        select_keyboard = 1'b0;
        select_timer = 1'b0;

        address_valid = 1'b0;

        if (address >= RAM_START &&
            address <= RAM_END) begin

            select_ram = 1'b1;
            address_valid = 1'b1;

        end

        else if (address >= FB_START &&
                 address <= FB_END) begin

            select_framebuffer = 1'b1;
            address_valid = 1'b1;

        end

        else if (address >= KB_START &&
                 address <= KB_END) begin

            select_keyboard = 1'b1;
            address_valid = 1'b1;

        end

        else if (address >= TIMER_START &&
                 address <= TIMER_END) begin

            select_timer = 1'b1;
            address_valid = 1'b1;

        end

    end

endmodule
