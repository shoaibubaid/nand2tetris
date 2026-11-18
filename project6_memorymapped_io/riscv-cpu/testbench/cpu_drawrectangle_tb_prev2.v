
`timescale 1ns/1ps

module cpu_drawrectangle_tb;

    // =================================
    // Clock and reset
    // =================================

    reg clk = 0;
    reg reset = 1;

    always #5 clk = ~clk;

    // =================================
    // CPU signals
    // =================================

    wire [31:0] pc_out;
    wire [31:0] instruction_out;

    wire instruction_valid;
    wire cpu_valid;

    // USB keyboard bridge signals
    reg ps_event_valid = 0;
    wire ps_event_ready;
    reg [8:0] ps_event_data = 0;

    wire ps_clk = clk;
    wire ps_reset = reset;

    integer frame_fd;
    integer cycles;

    // =================================
    // CPU instance
    // =================================

    cpu #(
        .IMEM_ADDR_WIDTH(10),
        .IMEM_INIT_FILE("software/assembler/program.hex")
    ) dut (
        .clk(clk),
        .reset(reset),

        .pc_out(pc_out),
        .instruction_out(instruction_out),
        .instruction_valid(instruction_valid),
        .cpu_valid(cpu_valid),

        .ps_clk(ps_clk),
        .ps_reset(ps_reset),
        .ps_event_valid(ps_event_valid),
        .ps_event_ready(ps_event_ready),
        .ps_event_data(ps_event_data)
    );

    // =================================
    // Export framebuffer as RGB332
    // =================================

    task dump_framebuffer_stream;

        integer x, y;
        integer pixel_offset;
        integer word_index;
        integer byte_lane;

        reg [31:0] word_data;
        reg [7:0] pixel;

        begin
            for (y = 0; y < 240; y = y + 1) begin
                for (x = 0; x < 320; x = x + 1) begin

                    pixel_offset = y * 320 + x;
                    word_index = pixel_offset / 4;
                    byte_lane = pixel_offset % 4;

                    word_data =
                        dut.dmem.framebuffer_controller.memory[word_index];

                    pixel = word_data[byte_lane * 8 +: 8];

                    $fwrite(frame_fd, "%c", pixel);

                end
            end
        end

    endtask

    // =================================
    // Export one PPM snapshot
    // =================================

    task dump_framebuffer;

        integer fd;
        integer x, y;
        integer pixel_offset;
        integer word_index;
        integer byte_lane;

        reg [31:0] word_data;
        reg [7:0] pixel;

        reg [7:0] red;
        reg [7:0] green;
        reg [7:0] blue;

        begin

            fd = $fopen("framebuffer.ppm", "wb");

            if (fd == 0) begin

                $display("ERROR: Cannot open framebuffer.ppm");

            end
            else begin

                $fwrite(fd, "P6\n320 240\n255\n");

                for (y = 0; y < 240; y = y + 1) begin
                    for (x = 0; x < 320; x = x + 1) begin

                        pixel_offset = y * 320 + x;
                        word_index = pixel_offset / 4;
                        byte_lane = pixel_offset % 4;

                        word_data =
                            dut.dmem.framebuffer_controller.memory[word_index];

                        pixel = word_data[byte_lane * 8 +: 8];

                        // RGB332 -> RGB888

                        red = {
                            pixel[7:5],
                            pixel[7:5],
                            pixel[7:6]
                        };

                        green = {
                            pixel[4:2],
                            pixel[4:2],
                            pixel[4:3]
                        };

                        blue = {
                            pixel[1:0],
                            pixel[1:0],
                            pixel[1:0],
                            pixel[1:0]
                        };

                        $fwrite(fd, "%c%c%c", red, green, blue);

                    end
                end

                $fclose(fd);

                $display("Framebuffer exported!");

            end

        end

    endtask

    // =================================
    // Reset sequence
    // =================================

    initial begin

        repeat (3) @(negedge clk);

        reset = 0;

        $display("CPU reset released!");

    end

    // =================================
    // Continuous framebuffer streaming
    // =================================

    initial begin

        // Wait until CPU reset is released
        wait(reset === 1'b0);

        frame_fd = $fopen("framebuffer_stream.rgb332", "wb");

        if (frame_fd == 0) begin

            $display("ERROR: Cannot open framebuffer stream");

            $fatal;

        end

        $display("Framebuffer streaming started!");

        cycles = 0;

        forever begin

            // Wait 10,000 CPU clock cycles
            repeat (100000) @(posedge clk);

            // Capture framebuffer
            dump_framebuffer_stream();

            // Flush output so Python can read it
            $fflush(frame_fd);

            cycles = cycles + 10000;

            $display(
                "Framebuffer snapshot exported. Cycles = %0d",
                cycles
            );

        end

    end

endmodule
