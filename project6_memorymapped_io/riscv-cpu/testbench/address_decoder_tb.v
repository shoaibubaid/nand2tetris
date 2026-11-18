
`timescale 1ns/1ps

module address_decoder_tb;

    // --------------------------------------------
    // Inputs
    // --------------------------------------------

    reg [31:0] address;

    // --------------------------------------------
    // Outputs
    // --------------------------------------------

    wire select_ram;
    wire select_framebuffer;
    wire select_keyboard;
    wire select_timer;
    wire address_valid;

    wire [13:0] ram_offset;
    wire [16:0] framebuffer_offset;
    wire [3:0] keyboard_offset;
    wire [3:0] timer_offset;

    integer errors;
    integer tests;

    reg [3:0] actual_select;

    // --------------------------------------------
    // DUT
    // --------------------------------------------

    address_decoder dut (
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

    // --------------------------------------------
    // Test task
    // --------------------------------------------

    task check_address;

        input [31:0] test_address;
        input [3:0] expected_select;
        input expected_valid;

        begin

            address = test_address;
            #5;

            actual_select = {
                select_timer,
                select_keyboard,
                select_framebuffer,
                select_ram
            };

            tests = tests + 1;

            if ((actual_select !== expected_select) ||
                (address_valid !== expected_valid)) begin

                $display("FAIL: Address = 0x%08h", test_address);

                $display("  Expected select = %b, valid = %b",
                         expected_select, expected_valid);

                $display("  Actual   select = %b, valid = %b",
                         actual_select, address_valid);

                errors = errors + 1;

            end
            else begin

                $display("PASS: Address = 0x%08h, select = %b, valid = %b",
                         test_address, actual_select, address_valid);

            end

        end

    endtask

    // --------------------------------------------
    // Offset checking task
    // --------------------------------------------

    task check_offsets;

        input [31:0] test_address;
        input [13:0] expected_ram_offset;
        input [16:0] expected_fb_offset;
        input [3:0] expected_keyboard_offset;
        input [3:0] expected_timer_offset;

        begin

            address = test_address;
            #5;

            tests = tests + 1;

            if ((ram_offset !== expected_ram_offset) ||
                (framebuffer_offset !== expected_fb_offset) ||
                (keyboard_offset !== expected_keyboard_offset) ||
                (timer_offset !== expected_timer_offset)) begin

                $display("OFFSET FAIL: Address = 0x%08h", test_address);

                $display("  RAM: expected=%h actual=%h",
                         expected_ram_offset, ram_offset);

                $display("  FB: expected=%h actual=%h",
                         expected_fb_offset, framebuffer_offset);

                $display("  Keyboard: expected=%h actual=%h",
                         expected_keyboard_offset, keyboard_offset);

                $display("  Timer: expected=%h actual=%h",
                         expected_timer_offset, timer_offset);

                errors = errors + 1;

            end
            else begin

                $display("OFFSET PASS: Address = 0x%08h", test_address);

            end

        end

    endtask

    // --------------------------------------------
    // Main test sequence
    // --------------------------------------------

    initial begin

        address = 32'b0;
        errors = 0;
        tests = 0;

        $display("");
        $display("========================================");
        $display("       ADDRESS DECODER TESTBENCH");
        $display("========================================");
        $display("");

        // ----------------------------------------
        // 1. Main RAM region
        // ----------------------------------------

        $display("--- MAIN RAM TESTS ---");

        check_address(32'h00000000, 4'b0001, 1'b1);
        check_address(32'h00000004, 4'b0001, 1'b1);
        check_address(32'h00001000, 4'b0001, 1'b1);
        check_address(32'h00003FFC, 4'b0001, 1'b1);
        check_address(32'h00003FFF, 4'b0001, 1'b1);

        // ----------------------------------------
        // 2. Framebuffer region
        // ----------------------------------------

        $display("");
        $display("--- FRAMEBUFFER TESTS ---");

        check_address(32'h10000000, 4'b0010, 1'b1);
        check_address(32'h10000001, 4'b0010, 1'b1);
        check_address(32'h10000100, 4'b0010, 1'b1);
        check_address(32'h10010000, 4'b0010, 1'b1);
        check_address(32'h10012BFF, 4'b0010, 1'b1);

        // ----------------------------------------
        // 3. Keyboard region
        // ----------------------------------------

        $display("");
        $display("--- KEYBOARD TESTS ---");

        check_address(32'h20000000, 4'b0100, 1'b1);
        check_address(32'h20000004, 4'b0100, 1'b1);
        check_address(32'h20000008, 4'b0100, 1'b1);
        check_address(32'h2000000C, 4'b0100, 1'b1);
        check_address(32'h2000000F, 4'b0100, 1'b1);

        // ----------------------------------------
        // 4. Timer region
        // ----------------------------------------

        $display("");
        $display("--- TIMER TESTS ---");

        check_address(32'h20000010, 4'b1000, 1'b1);
        check_address(32'h20000014, 4'b1000, 1'b1);
        check_address(32'h20000018, 4'b1000, 1'b1);
        check_address(32'h2000001C, 4'b1000, 1'b1);
        check_address(32'h2000001F, 4'b1000, 1'b1);

        // ----------------------------------------
        // 5. Invalid addresses
        // ----------------------------------------

        $display("");
        $display("--- INVALID ADDRESS TESTS ---");

        check_address(32'h00004000, 4'b0000, 1'b0);
        check_address(32'h00005000, 4'b0000, 1'b0);
        check_address(32'h10012C00, 4'b0000, 1'b0);
        check_address(32'h20000020, 4'b0000, 1'b0);
        check_address(32'h30000000, 4'b0000, 1'b0);
        check_address(32'hFFFFFFFF, 4'b0000, 1'b0);

        // ----------------------------------------
        // 6. Device-relative offset tests
        // ----------------------------------------

        $display("");
        $display("--- OFFSET TESTS ---");

        // RAM offset = address - RAM_START
        check_offsets(
            32'h00000020,
            14'h0020,
            17'h00020,
            4'h0,
            4'h0
        );

        // Framebuffer offset = address - FB_START
        check_offsets(
            32'h10000123,
            14'h0123,
            17'h00123,
            4'h3,
            4'h3
        );

        // Keyboard offset = address[3:0]
        check_offsets(
            32'h2000000A,
            14'h000A,
            17'h0000A,
            4'hA,
            4'hA
        );

        // Timer offset = address - TIMER_START
        check_offsets(
            32'h2000001C,
            14'h001C,
            17'h0001C,
            4'hC,
            4'hC
        );

        // ----------------------------------------
        // Final result
        // ----------------------------------------

        $display("");
        $display("========================================");
        $display("Tests executed : %0d", tests);
        $display("Errors         : %0d", errors);
        $display("========================================");

        if (errors == 0) begin
            $display("");
            $display("ALL ADDRESS DECODER TESTS PASSED");
        end
        else begin
            $display("");
            $display("ADDRESS DECODER TESTS FAILED");
            $fatal(1);
        end

        $finish;

    end

endmodule
