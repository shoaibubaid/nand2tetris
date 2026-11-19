
`timescale 1ns/1ps

module memory_subsystem_timer_tb;

    // ------------------------------------------------
    // Clock and reset
    // ------------------------------------------------

    reg clk = 0;
    always #5 clk = ~clk;

    reg ps_clk = 0;
    always #7 ps_clk = ~ps_clk;

    reg reset = 1;
    reg ps_reset = 1;

    // ------------------------------------------------
    // CPU memory interface
    // ------------------------------------------------

    reg req = 0;
    reg mem_read = 0;
    reg mem_write = 0;

    reg [31:0] address = 0;
    reg [31:0] write_data = 0;
    reg [2:0] funct3 = 3'b010;

    wire ready;
    wire [31:0] read_data;
    wire access_error;

    // ------------------------------------------------
    // Video interface
    // ------------------------------------------------

    reg [16:0] video_pixel_address = 0;
    wire [7:0] video_pixel_data;

    // ------------------------------------------------
    // USB keyboard interface (unused in this test)
    // ------------------------------------------------

    reg ps_event_valid = 0;
    wire ps_event_ready;
    reg [8:0] ps_event_data = 0;

    // ------------------------------------------------
    // Test bookkeeping
    // ------------------------------------------------

    integer errors = 0;
    integer timeout;

    reg write_error;
    reg [31:0] value;
    reg [31:0] before_disable;
    reg [31:0] after_disable;

    // ------------------------------------------------
    // DUT
    // ------------------------------------------------

    memory_subsystem #(
        .CLK_HZ(4000)
    ) dut (
        .clk(clk),
        .reset(reset),

        .req(req),
        .mem_read(mem_read),
        .mem_write(mem_write),

        .address(address),
        .write_data(write_data),
        .funct3(funct3),

        .video_pixel_address(video_pixel_address),
        .video_pixel_data(video_pixel_data),

        .ps_clk(ps_clk),
        .ps_reset(ps_reset),
        .ps_event_valid(ps_event_valid),
        .ps_event_ready(ps_event_ready),
        .ps_event_data(ps_event_data),

        .ready(ready),
        .read_data(read_data),
        .access_error(access_error)
    );

    // ------------------------------------------------
    // Write a memory-mapped register
    // ------------------------------------------------

    task write_word(
        input [31:0] addr,
        input [31:0] data,
        input [2:0] width
    );
        begin
            write_error = 0;

            @(negedge clk);

            address = addr;
            write_data = data;
            funct3 = width;

            mem_read = 0;
            mem_write = 1;
            req = 1;

            timeout = 0;

            while (ready !== 1'b1 && timeout < 100) begin
                @(negedge clk);
                timeout = timeout + 1;
            end

            if (timeout >= 100) begin
                $display("ERROR: Write timeout at address %h", addr);
                errors = errors + 1;
            end
            else begin
                write_error = access_error;
            end

            @(negedge clk);

            req = 0;
            mem_write = 0;

            repeat (2) @(negedge clk);
        end
    endtask

    // ------------------------------------------------
    // Read a memory-mapped register
    // ------------------------------------------------

    task read_word(
        input [31:0] addr,
        output reg [31:0] data
    );
        begin
            @(negedge clk);

            address = addr;
            funct3 = 3'b010;

            mem_read = 1;
            mem_write = 0;
            req = 1;

            timeout = 0;

            while (ready !== 1'b1 && timeout < 100) begin
                @(negedge clk);
                timeout = timeout + 1;
            end

            if (timeout >= 100) begin
                $display("ERROR: Read timeout at address %h", addr);
                errors = errors + 1;
                data = 32'hXXXXXXXX;
            end
            else begin
                data = read_data;

                if (access_error !== 1'b0) begin
                    $display("ERROR: Read access error at address %h", addr);
                    errors = errors + 1;
                end
            end

            @(negedge clk);

            req = 0;
            mem_read = 0;

            repeat (2) @(negedge clk);
        end
    endtask

    // ------------------------------------------------
    // Wait until timer has generated at least one tick
    // ------------------------------------------------

    task wait_for_timer_tick;
        integer poll_count;
        reg [31:0] status_value;

        begin
            poll_count = 0;
            status_value = 0;

            while (status_value[1] !== 1'b1 &&
                   poll_count < 50) begin

                read_word(32'h2000001C, status_value);
                poll_count = poll_count + 1;
            end

            if (status_value[1] !== 1'b1) begin
                $display("ERROR: Timer tick was not observed");
                errors = errors + 1;
            end
        end
    endtask

    // ------------------------------------------------
    // Value checking helper
    // ------------------------------------------------

    task check_value(
        input [255:0] description,
        input [31:0] actual,
        input [31:0] expected
    );
        begin
            if (actual !== expected) begin
                $display(
                    "FAIL: %0s | Expected: %h | Actual: %h",
                    description, expected, actual
                );
                errors = errors + 1;
            end
            else begin
                $display(
                    "PASS: %0s = %h",
                    description, actual
                );
            end
        end
    endtask

    // ------------------------------------------------
    // Main test sequence
    // ------------------------------------------------

    initial begin

        $display("----------------------------------------");
        $display("MEMORY SUBSYSTEM TIMER INTEGRATION TEST");
        $display("----------------------------------------");

        // Reset both clock domains.
        repeat (5) @(negedge clk);

        reset = 0;
        ps_reset = 0;

        repeat (5) @(negedge clk);

        // --------------------------------------------
        // TEST 1: Default prescaler through MMIO
        // --------------------------------------------

        $display("\nTEST 1: Default prescaler");

        read_word(32'h20000018, value);

        check_value(
            "Default prescaler through MMIO",
            value,
            32'd4
        );

        // --------------------------------------------
        // TEST 2: Initial TIME register
        // --------------------------------------------

        $display("\nTEST 2: Initial timer value");

        read_word(32'h20000010, value);

        check_value(
            "Initial TIME",
            value,
            32'd0
        );

        // --------------------------------------------
        // TEST 3: Program prescaler
        // --------------------------------------------

        $display("\nTEST 3: Program prescaler");

        write_word(
            32'h20000018,
            32'd4,
            3'b010
        );

        if (write_error === 1'b0) begin
            $display("PASS: Prescaler write accepted");
        end
        else begin
            $display("FAIL: Prescaler write rejected");
            errors = errors + 1;
        end

        read_word(32'h20000018, value);

        check_value(
            "Updated prescaler",
            value,
            32'd4
        );

        // --------------------------------------------
        // TEST 4: Enable timer
        // --------------------------------------------

        $display("\nTEST 4: Enable timer");

        write_word(
            32'h20000014,
            32'd1,
            3'b010
        );

        if (write_error === 1'b0) begin
            $display("PASS: Timer enable accepted");
        end
        else begin
            $display("FAIL: Timer enable rejected");
            errors = errors + 1;
        end

        read_word(32'h20000014, value);

        check_value(
            "CONTROL after enable",
            value,
            32'd1
        );

        // --------------------------------------------
        // TEST 5: Timer counting
        // --------------------------------------------

        $display("\nTEST 5: Timer counting");

        repeat (30) @(negedge clk);

        read_word(32'h20000010, value);

        if (value >= 32'd2) begin
            $display(
                "PASS: Timer advanced to %0d milliseconds",
                value
            );
        end
        else begin
            $display(
                "FAIL: Timer did not advance sufficiently: %0d",
                value
            );
            errors = errors + 1;
        end

        // --------------------------------------------
        // TEST 6: Status tick flag
        // --------------------------------------------

        $display("\nTEST 6: Timer status");

        read_word(32'h2000001C, value);

        if (value[0] === 1'b1) begin
            $display("PASS: Timer enabled status");
        end
        else begin
            $display("FAIL: Timer enabled bit not set");
            errors = errors + 1;
        end

        if (value[1] === 1'b1) begin
            $display("PASS: Timer tick flag set");
        end
        else begin
            $display("FAIL: Timer tick flag not set");
            errors = errors + 1;
        end

        // --------------------------------------------
        // TEST 7: Clear tick flag
        // --------------------------------------------

        $display("\nTEST 7: Clear tick flag");

        // Disable timer to prevent another tick.
        write_word(
            32'h20000014,
            32'd0,
            3'b010
        );

        if (write_error !== 1'b0) begin
            $display("FAIL: Timer disable rejected");
            errors = errors + 1;
        end

        // Clear STATUS[1].
        write_word(
            32'h2000001C,
            32'd2,
            3'b010
        );

        if (write_error !== 1'b0) begin
            $display("FAIL: STATUS write rejected");
            errors = errors + 1;
        end

        read_word(32'h2000001C, value);

        if (value[1] === 1'b0) begin
            $display("PASS: Tick flag cleared");
        end
        else begin
            $display("FAIL: Tick flag did not clear");
            errors = errors + 1;
        end

        // --------------------------------------------
        // TEST 8: Timer disabled
        // --------------------------------------------

        $display("\nTEST 8: Timer disabled");

        read_word(32'h20000010, before_disable);

        repeat (20) @(negedge clk);

        read_word(32'h20000010, after_disable);

        check_value(
            "Timer stopped after disable",
            after_disable,
            before_disable
        );

        // --------------------------------------------
        // TEST 9: Reset counter
        // --------------------------------------------

        $display("\nTEST 9: Reset timer counter");

        write_word(
            32'h20000014,
            32'd2,
            3'b010
        );

        read_word(32'h20000010, value);

        check_value(
            "TIME after reset",
            value,
            32'd0
        );

        read_word(32'h2000001C, value);

        check_value(
            "STATUS after reset",
            value,
            32'd0
        );

        // --------------------------------------------
        // TEST 10: Restart timer
        // --------------------------------------------

        $display("\nTEST 10: Restart timer");

        write_word(
            32'h20000014,
            32'd1,
            3'b010
        );

        repeat (12) @(negedge clk);

        read_word(32'h20000010, value);

        if (value >= 32'd1) begin
            $display("PASS: Timer restarted successfully");
        end
        else begin
            $display("FAIL: Timer did not restart");
            errors = errors + 1;
        end

        // --------------------------------------------
        // TEST 11: Invalid timer write
        // --------------------------------------------

        $display("\nTEST 11: Write to read-only TIME");

        write_word(
            32'h20000010,
            32'd123,
            3'b010
        );

        if (write_error === 1'b1) begin
            $display("PASS: TIME write rejected");
        end
        else begin
            $display("FAIL: TIME write accepted");
            errors = errors + 1;
        end

        
        // --------------------------------------------
        // TEST 12: Invalid address
        // --------------------------------------------

        $display("\nTEST 12: Invalid address");

        @(negedge clk);

        address = 32'h30000000;
        mem_read = 1;
        mem_write = 0;
        funct3 = 3'b010;
        req = 1;

        timeout = 0;

        while (ready !== 1'b1 && timeout < 20) begin
            @(negedge clk);
            timeout = timeout + 1;
        end

        if (timeout >= 20) begin
            $display("FAIL: Invalid address response timeout");
            errors = errors + 1;
        end
        else if (access_error === 1'b1) begin
            $display("PASS: Invalid address rejected");
        end
        else begin
            $display("FAIL: Invalid address not rejected");
            errors = errors + 1;
        end

        @(negedge clk);

        req = 0;
        mem_read = 0;

        repeat (2) @(negedge clk);


        // --------------------------------------------
        // Final result
        // --------------------------------------------

        $display("\n----------------------------------------");

        if (errors == 0) begin
            $display("ALL TIMER INTEGRATION TESTS PASSED");
        end
        else begin
            $display(
                "TIMER INTEGRATION FAILED: %0d errors",
                errors
            );
        end

        $display("----------------------------------------");

        $finish;
    end

endmodule
