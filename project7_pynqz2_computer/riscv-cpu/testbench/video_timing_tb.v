
`timescale 1ns/1ps

module video_timing_tb;

    reg pixel_clk;
    reg reset;

    wire [9:0] pixel_x;
    wire [9:0] pixel_y;
    wire video_active;
    wire hsync;
    wire vsync;

    integer errors;

    video_timing dut (
        .pixel_clk(pixel_clk),
        .reset(reset),
        .pixel_x(pixel_x),
        .pixel_y(pixel_y),
        .video_active(video_active),
        .hsync(hsync),
        .vsync(vsync)
    );

    // 100 MHz test clock. Actual pixel-clock frequency
    // is provided by the FPGA clocking hardware.
    initial pixel_clk = 1'b0;
    always #5 pixel_clk = ~pixel_clk;

    task check_position;
        input integer expected_h;
        input integer expected_v;
        input expected_active;
        input expected_hsync;
        input expected_vsync;

        begin
            wait (
                dut.h_count == expected_h &&
                dut.v_count == expected_v
            );

            #1;

            if (pixel_x !== expected_h ||
                pixel_y !== expected_v ||
                video_active !== expected_active ||
                hsync !== expected_hsync ||
                vsync !== expected_vsync) begin

                $display(
                    "FAIL: expected (%0d,%0d), got (%0d,%0d), active=%b hsync=%b vsync=%b",
                    expected_h, expected_v,
                    pixel_x, pixel_y,
                    video_active, hsync, vsync
                );

                errors = errors + 1;
            end
            else begin
                $display(
                    "PASS: (%0d,%0d), active=%b hsync=%b vsync=%b",
                    expected_h, expected_v,
                    video_active, hsync, vsync
                );
            end
        end
    endtask

    initial begin
        errors = 0;
        reset = 1'b1;

        // Apply reset for several clock cycles.
        repeat (3) @(posedge pixel_clk);
        #1;

        if (dut.h_count !== 0 || dut.v_count !== 0) begin
            $display("FAIL: counter reset");
            errors = errors + 1;
        end
        else begin
            $display("PASS: counter reset");
        end

        @(negedge pixel_clk);
        reset = 1'b0;

        // Start of frame and active display.
        check_position(0,   0,   1'b1, 1'b1, 1'b1);
        check_position(639, 0,   1'b1, 1'b1, 1'b1);

        // Horizontal blanking begins at pixel 640.
        check_position(640, 0,   1'b0, 1'b1, 1'b1);

        // Horizontal sync: low from 656 through 751.
        check_position(655, 0,   1'b0, 1'b1, 1'b1);
        check_position(656, 0,   1'b0, 1'b0, 1'b1);
        check_position(751, 0,   1'b0, 1'b0, 1'b1);
        check_position(752, 0,   1'b0, 1'b1, 1'b1);

        // Last active line and first vertically blank line.
        check_position(0, 479,   1'b1, 1'b1, 1'b1);
        check_position(0, 480,   1'b0, 1'b1, 1'b1);

        // Vertical sync: low from line 490 through 491.
        check_position(0, 489,   1'b0, 1'b1, 1'b1);
        check_position(0, 490,   1'b0, 1'b1, 1'b0);
        check_position(0, 491,   1'b0, 1'b1, 1'b0);
        check_position(0, 492,   1'b0, 1'b1, 1'b1);

        // Final raster position.
        check_position(799, 524, 1'b0, 1'b1, 1'b1);

        // Next clock must wrap to the first pixel of the next frame.
        @(posedge pixel_clk);
        #1;

        if (dut.h_count !== 0 || dut.v_count !== 0) begin
            $display("FAIL: frame rollover");
            errors = errors + 1;
        end
        else begin
            $display("PASS: frame rollover");
        end

        if (errors == 0)
            $display("ALL VIDEO TIMING TESTS PASSED");
        else
            $display("VIDEO TIMING TESTS FAILED: %0d errors", errors);

        $finish;
    end

endmodule
