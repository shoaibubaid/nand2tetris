
`timescale 1ns/1ps

module tmds_encoder_tb;

    reg pixel_clk;
    reg reset;
    reg video_enable;
    reg [7:0] video_data;
    reg control_0;
    reg control_1;

    wire [9:0] tmds_symbol;

    integer errors;
    integer value;
    integer control_index;

    tmds_encoder dut (
        .pixel_clk(pixel_clk),
        .reset(reset),
        .video_enable(video_enable),
        .video_data(video_data),
        .control_0(control_0),
        .control_1(control_1),
        .tmds_symbol(tmds_symbol)
    );

    initial pixel_clk = 0;
    always #5 pixel_clk = ~pixel_clk;

    task check_control;
        input [1:0] control;
        input [9:0] expected;

        begin
            @(negedge pixel_clk);
            video_enable = 0;
            control_1 = control[1];
            control_0 = control[0];

            @(posedge pixel_clk);
            #1;

            if (tmds_symbol !== expected) begin
                $display(
                    "FAIL: control=%b expected=%b got=%b",
                    control, expected, tmds_symbol
                );
                errors = errors + 1;
            end
            else begin
                $display(
                    "PASS: control=%b symbol=%b",
                    control, tmds_symbol
                );
            end
        end
    endtask

    initial begin
        errors = 0;
        reset = 1;
        video_enable = 0;
        video_data = 0;
        control_0 = 0;
        control_1 = 0;

        repeat (3) @(negedge pixel_clk);
        reset = 0;

        // Four HDMI control symbols.
        check_control(2'b00, 10'b1101010100);
        check_control(2'b01, 10'b0010101011);
        check_control(2'b10, 10'b0101010100);
        check_control(2'b11, 10'b1010101011);

        $display("Testing all 256 video input values...");

        // Exercise every possible 8-bit video value.
        for (value = 0; value < 256; value = value + 1) begin

            @(negedge pixel_clk);
            video_enable = 1;
            video_data = value[7:0];

            @(posedge pixel_clk);
            #1;

            if ((^tmds_symbol) === 1'bx) begin
                $display("FAIL: unknown symbol for data %h", value);
                errors = errors + 1;
            end

            if ((dut.disparity > 16) ||
                (dut.disparity < -16)) begin
                $display(
                    "FAIL: disparity out of range: %0d",
                    dut.disparity
                );
                errors = errors + 1;
            end
        end

        // Check that blanking resets running disparity.
        @(negedge pixel_clk);
        video_enable = 0;
        control_0 = 0;
        control_1 = 0;

        @(posedge pixel_clk);
        #1;

        if (dut.disparity !== 0) begin
            $display("FAIL: disparity did not reset during control period");
            errors = errors + 1;
        end
        else begin
            $display("PASS: running disparity reset");
        end

        if (errors == 0)
            $display("ALL TMDS ENCODER TESTS PASSED");
        else
            $display("TMDS ENCODER TESTS FAILED: %0d errors", errors);

        $finish;
    end

endmodule
