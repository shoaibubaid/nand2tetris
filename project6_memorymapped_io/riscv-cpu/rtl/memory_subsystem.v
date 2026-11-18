
`timescale 1ns/1ps

module memory_subsystem (
    input wire clk,
    input wire reset,

    // CPU memory interface
    input wire req,
    input wire mem_read,
    input wire mem_write,
    input wire [31:0] address,
    input wire [31:0] write_data,
    input wire [2:0] funct3,

    // Video interface
    input wire [16:0] video_pixel_address,
    output wire [7:0] video_pixel_data,

    // USB keyboard events from Zynq Processing System
    input wire ps_clk,
    input wire ps_reset,
    input wire ps_event_valid,
    output wire ps_event_ready,
    input wire [8:0] ps_event_data,

    // CPU memory response
    output wire ready,
    output wire [31:0] read_data,
    output wire access_error
);

    // ------------------------------------------------
    // Address decoder
    // ------------------------------------------------

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

    // ------------------------------------------------
    // Main RAM controller
    // ------------------------------------------------

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

    // ------------------------------------------------
    // Framebuffer controller
    // ------------------------------------------------

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

    // ------------------------------------------------
    // USB keyboard clock-domain crossing
    // ------------------------------------------------

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

    // ------------------------------------------------
    // Keyboard MMIO controller
    // ------------------------------------------------

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

    // ------------------------------------------------
    // 32-bit free-running timer
    // MMIO: +0 TIME, +4 CONTROL, +8 PRESCALER, +C STATUS
    // Default prescaler = 99,999 for a 100 MHz CPU clock,
    // producing one timer tick per millisecond.
    // ------------------------------------------------

    reg [31:0] timer_count;
    reg [31:0] timer_prescaler;
    reg [31:0] timer_prescaler_count;
    reg        timer_enable;

    wire timer_ready = req && select_timer;

    always @(posedge clk) begin
        if (reset) begin
            timer_count <= 32'd0;
            timer_prescaler <= 32'd99999;
            timer_prescaler_count <= 32'd0;
            timer_enable <= 1'b0;
        end else begin
            // Timer MMIO writes
            if (timer_ready && mem_write) begin
                case (timer_offset)
                    4'h4: begin
                        if (write_data[1]) begin
                            timer_count <= 32'd0;
                            timer_prescaler_count <= 32'd0;
                        end
                        timer_enable <= write_data[0];
                    end
                    4'h8: begin
                        timer_prescaler <= write_data;
                        timer_prescaler_count <= 32'd0;
                    end
                    default: begin end
                endcase
            end

            // Timer advances independently of CPU reads.
            if (timer_enable) begin
                if (timer_prescaler_count >= timer_prescaler) begin
                    timer_prescaler_count <= 32'd0;
                    timer_count <= timer_count + 1'b1;
                end else begin
                    timer_prescaler_count <= timer_prescaler_count + 1'b1;
                end
            end
        end
    end

    // ------------------------------------------------
    // Invalid address response
    // ------------------------------------------------

    wire invalid_ready = req && !address_valid;

    // ------------------------------------------------
    // Overall ready response
    // ------------------------------------------------

    assign ready =
        (select_ram && ram_ready) ||
        (select_framebuffer && framebuffer_ready) ||
        (select_keyboard && keyboard_ready) ||
        timer_ready ||
        invalid_ready;

    // ------------------------------------------------
    // Read-data selection
    // ------------------------------------------------

    assign read_data =
        select_ram        ? ram_read_data :
        select_framebuffer ? framebuffer_read_data :
        select_keyboard   ? keyboard_read_data :
        (select_timer && timer_offset == 4'h0) ? timer_count :
        (select_timer && timer_offset == 4'h4) ? {30'b0, timer_enable, 1'b0} :
        (select_timer && timer_offset == 4'h8) ? timer_prescaler :
        (select_timer && timer_offset == 4'hC) ? {31'b0, timer_enable} :
        32'b0;

    // ------------------------------------------------
    // Access-error selection
    // ------------------------------------------------

    assign access_error =
        (select_ram && ram_access_error) ||
        (select_framebuffer && framebuffer_access_error) ||
        (select_keyboard && keyboard_access_error) ||
        invalid_ready;

endmodule
