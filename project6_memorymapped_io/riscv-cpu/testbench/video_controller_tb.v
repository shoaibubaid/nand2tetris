
`timescale 1ns/1ps

module video_controller_tb;

    reg pixel_clk;
    reg reset;

    wire [16:0] video_pixel_address;
    reg [7:0] video_pixel_data;

    wire [7:0] red, green, blue;
    wire video_active, hsync, vsync;

    integer errors;

    video_controller dut (
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

    initial pixel_clk = 0;
    always #5 pixel_clk = ~pixel_clk;

    task check_address;
        input integer expected_x;
        input integer expected_y;
        input integer expected_address;

        begin
            wait (
                dut.timing.h_count == expected_x &&
                dut.timing.v_count == expected_y
            );
            #1;

            if (video_pixel_address !== expected_address) begin
                $display(
                    "FAIL: (%0d,%0d) expected address %0d, got %0d",
                    expected_x, expected_y,
                    expected_address, video_pixel_address
                );
                errors = errors + 1;
            end
            else begin
                $display(
                    "PASS: (%0d,%0d) -> framebuffer address %0d",
                    expected_x, expected_y, video_pixel_address
                );
            end
        end
    endtask

    initial begin
        errors = 0;
        reset = 1;
        video_pixel_data = 8'hE3;

        repeat (3) @(negedge pixel_clk);
        reset = 0;

        // Verify 2x scaling and address calculation.
        check_address(0,   0,   0);
        check_address(2,   0,   1);
        check_address(0,   2,   320);
        check_address(2,   2,   321);
        check_address(100, 200, 100*320 + 50);
        check_address(638, 478, 239*320 + 319);

        // Move to a known active pixel, then sample its
        // registered timing and fixed RGB input.
        wait (
            dut.timing.h_count == 10 &&
            dut.timing.v_count == 10
        );

        @(posedge pixel_clk);
        #1;

        if (video_active !== 1'b1) begin
            $display("FAIL: active-video alignment");
            errors = errors + 1;
        end
        else begin
            $display("PASS: active-video alignment");
        end

        // E3 = RGB332:
        // R=111, G=000, B=11
        if (red !== 8'hFF ||
            green !== 8'h00 ||
            blue !== 8'hFF) begin

            $display(
                "FAIL: RGB conversion R=%h G=%h B=%h",
                red, green, blue
            );
            errors = errors + 1;
        end
        else begin
            $display("PASS: RGB332 to RGB888 conversion");
        end

        // Wait for horizontal blanking.
        wait (dut.timing.h_count == 640);
        @(posedge pixel_clk);
        #1;

        if (video_active !== 1'b0 ||
            red !== 8'd0 ||
            green !== 8'd0 ||
            blue !== 8'd0) begin

            $display("FAIL: blanking output");
            errors = errors + 1;
        end
        else begin
            $display("PASS: blanking output");
        end

        if (errors == 0)
            $display("ALL VIDEO CONTROLLER TESTS PASSED");
        else
            $display("VIDEO CONTROLLER TESTS FAILED: %0d errors", errors);

        $finish;
    end

endmodule
