
`timescale 1ns/1ps

module timer_tb;

    // ------------------------------------------------
    // Clock and reset
    // ------------------------------------------------

    reg clk = 0;
    always #5 clk = ~clk;

    reg reset = 1;

    // ------------------------------------------------
    // Timer bus interface
    // ------------------------------------------------

    reg req = 0;
    reg mem_read = 0;
    reg mem_write = 0;

    reg [3:0] offset = 0;
    reg [31:0] write_data = 0;
    reg [2:0] funct3 = 3'b010;

    wire ready;
    wire [31:0] read_data;
    wire access_error;

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

    timer #(
        .CLK_HZ(100_000_000)
    ) dut (
        .clk(clk),
        .reset(reset),

        .req(req),
        .mem_read(mem_read),
        .mem_write(mem_write),

        .offset(offset),
        .write_data(write_data),
        .funct3(funct3),

        .ready(ready),
        .read_data(read_data),
        .access_error(access_error)
    );

    // ------------------------------------------------
    // Write register
    // Captures access_error while ready is asserted.
    // ------------------------------------------------

    task write_reg(
        input [3:0] addr,
        input [31:0] data,
        input [2:0] width
    );
        begin
            write_error = 0;

            @(negedge clk);

            offset = addr;
            write_data = data;
            funct3 = width;

            mem_read = 0;
            mem_write = 1;
            req = 1;

            timeout = 0;

            while (ready !== 1'b1 && timeout < 20) begin
                @(negedge clk);
                timeout = timeout + 1;
            end

            if (timeout >= 20) begin
                $display("ERROR: Write timeout at offset %h", addr);
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
    // Read register
    // ------------------------------------------------

    task read_reg(
        input [3:0] addr,
        output reg [31:0] data
    );
        begin
            @(negedge clk);

            offset = addr;
            funct3 = 3'b010;

            mem_read = 1;
            mem_write = 0;
            req = 1;

            timeout = 0;

            while (ready !== 1'b1 && timeout < 20) begin
                @(negedge clk);
                timeout = timeout + 1;
            end

            if (timeout >= 20) begin
                $display("ERROR: Read timeout at offset %h", addr);
                errors = errors + 1;
                data = 32'hXXXXXXXX;
            end
            else begin
                data = read_data;

                if (access_error !== 1'b0) begin
                    $display("ERROR: Read access error at offset %h", addr);
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
        $display("TIMER TESTBENCH");
        $display("----------------------------------------");

        // Reset
        repeat (5) @(negedge clk);
        reset = 0;

        repeat (2) @(negedge clk);

        // --------------------------------------------
        // TEST 1: Default prescaler
        // --------------------------------------------

        $display("\nTEST 1: Default prescaler");

        read_reg(4'h8, value);

        check_value(
            "Default prescaler",
            value,
            32'd100000
        );

        // --------------------------------------------
        // TEST 2: Initial timer state
        // --------------------------------------------

        $display("\nTEST 2: Initial timer state");

        read_reg(4'h4, value);

        check_value(
            "Initial CONTROL",
            value,
            32'd0
        );

        read_reg(4'h0, value);

        check_value(
            "Initial TIME",
            value,
            32'd0
        );

        read_reg(4'hC, value);

        check_value(
            "Initial STATUS",
            value,
            32'd0
        );

        // --------------------------------------------
        // TEST 3: Program prescaler
        // --------------------------------------------

        $display("\nTEST 3: Program prescaler");

        write_reg(4'h8, 32'd4, 3'b010);

        if (write_error !== 1'b0) begin
            $display("FAIL: Valid prescaler write rejected");
            errors = errors + 1;
        end
        else begin
            $display("PASS: Prescaler write accepted");
        end

        read_reg(4'h8, value);

        check_value(
            "Programmed prescaler",
            value,
            32'd4
        );

        // --------------------------------------------
        // TEST 4: Enable timer
        // --------------------------------------------

        $display("\nTEST 4: Enable timer");

        write_reg(4'h4, 32'd1, 3'b010);

        if (write_error !== 1'b0) begin
            $display("FAIL: Timer enable write rejected");
            errors = errors + 1;
        end
        else begin
            $display("PASS: Timer enabled");
        end

        read_reg(4'h4, value);

        check_value(
            "CONTROL after enable",
            value,
            32'd1
        );

        // --------------------------------------------
        // TEST 5: Timer counting
        // --------------------------------------------

        $display("\nTEST 5: Timer counting");

        repeat (20) @(negedge clk);

        read_reg(4'h0, value);

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
        // TEST 6: Sticky tick flag
        // --------------------------------------------

        $display("\nTEST 6: Sticky tick flag");

        read_reg(4'hC, value);

        if (value[1] === 1'b1) begin
            $display("PASS: Tick flag is set");
        end
        else begin
            $display("FAIL: Tick flag was not set");
            errors = errors + 1;
        end

        // --------------------------------------------
        // TEST 7: Clear tick flag
        // --------------------------------------------


        $display("\nTEST 7: Clear tick flag");

        // Stop the timer so another tick cannot occur.
        write_reg(4'h4, 32'd0, 3'b010);

        if (write_error !== 1'b0) begin
            $display("FAIL: Could not disable timer");
            errors = errors + 1;
        end

        // Clear the sticky tick flag.
        write_reg(4'hC, 32'd2, 3'b010);

        if (write_error !== 1'b0) begin
            $display("FAIL: STATUS write rejected");
            errors = errors + 1;
        end

        // Verify that the flag remains cleared.
        read_reg(4'hC, value);

        if (value[1] === 1'b0) begin
            $display("PASS: Tick flag cleared");
        end
        else begin
            $display("FAIL: Tick flag did not clear");
            errors = errors + 1;
        end

        // --------------------------------------------
        // TEST 8: Disable timer
        // --------------------------------------------

        $display("\nTEST 8: Disable timer");

        write_reg(4'h4, 32'd0, 3'b010);

        if (write_error !== 1'b0) begin
            $display("FAIL: Timer disable write rejected");
            errors = errors + 1;
        end

        read_reg(4'h0, before_disable);

        repeat (20) @(negedge clk);

        read_reg(4'h0, after_disable);

        check_value(
            "Timer stopped after disable",
            after_disable,
            before_disable
        );

        // --------------------------------------------
        // TEST 9: Reset timer counter
        // --------------------------------------------

        $display("\nTEST 9: Reset timer counter");

        write_reg(4'h4, 32'd2, 3'b010);

        if (write_error !== 1'b0) begin
            $display("FAIL: Timer reset write rejected");
            errors = errors + 1;
        end

        read_reg(4'h0, value);

        check_value(
            "TIME after reset",
            value,
            32'd0
        );

        read_reg(4'hC, value);

        check_value(
            "STATUS after reset",
            value,
            32'd0
        );

        // --------------------------------------------
        // TEST 10: Re-enable after reset
        // --------------------------------------------

        $display("\nTEST 10: Re-enable timer");

        write_reg(4'h4, 32'd1, 3'b010);

        repeat (10) @(negedge clk);

        write_reg(4'h4, 32'd0, 3'b010);

        read_reg(4'h0, value);

        if (value >= 32'd1) begin
            $display("PASS: Timer works after reset");
        end
        else begin
            $display("FAIL: Timer did not restart");
            errors = errors + 1;
        end

        // --------------------------------------------
        // TEST 11: TIME is read-only
        // --------------------------------------------

        $display("\nTEST 11: TIME is read-only");

        write_reg(4'h0, 32'd123, 3'b010);

        if (write_error === 1'b1) begin
            $display("PASS: TIME write rejected");
        end
        else begin
            $display("FAIL: TIME write was accepted");
            errors = errors + 1;
        end

        // --------------------------------------------
        // TEST 12: Zero prescaler rejected
        // --------------------------------------------

        $display("\nTEST 12: Zero prescaler");

        write_reg(4'h8, 32'd0, 3'b010);

        if (write_error === 1'b1) begin
            $display("PASS: Zero prescaler rejected");
        end
        else begin
            $display("FAIL: Zero prescaler was accepted");
            errors = errors + 1;
        end

        // --------------------------------------------
        // TEST 13: Invalid access width
        // --------------------------------------------

        $display("\nTEST 13: Invalid access width");

        write_reg(4'h8, 32'd8, 3'b000);

        if (write_error === 1'b1) begin
            $display("PASS: Invalid access width rejected");
        end
        else begin
            $display("FAIL: Invalid access width was accepted");
            errors = errors + 1;
        end

        // --------------------------------------------
        // TEST 14: Invalid register offset
        // --------------------------------------------

        $display("\nTEST 14: Invalid register offset");

        write_reg(4'h2, 32'd8, 3'b010);

        if (write_error === 1'b1) begin
            $display("PASS: Invalid offset rejected");
        end
        else begin
            $display("FAIL: Invalid offset was accepted");
            errors = errors + 1;
        end

        // --------------------------------------------
        // Final result
        // --------------------------------------------

        $display("\n----------------------------------------");

        if (errors == 0) begin
            $display("ALL TIMER TESTS PASSED");
        end
        else begin
            $display("TIMER TESTS FAILED: %0d errors", errors);
        end

        $display("----------------------------------------");

        $finish;
    end

endmodule
