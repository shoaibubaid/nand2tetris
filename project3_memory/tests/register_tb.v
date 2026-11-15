
module register_tb;

    reg clk;
    reg [15:0] in;
    reg load;

    wire [15:0] out;

    reg [15:0] expected;

    integer test_count;
    integer fail_count;
    integer i;

    register uut(
        .clk(clk),
        .in(in),
        .load(load),
        .out(out)
    );

    // Clock generation: period = 10 time units
    always #5 clk = ~clk;


    // =========================================
    // OUTPUT CHECKING TASK
    // =========================================

    task check_output;
        input [15:0] expected_value;
        input [8*50-1:0] description;

        begin
            test_count = test_count + 1;

            if (out !== expected_value) begin

                fail_count = fail_count + 1;

                $display("FAIL Test %0d: %0s",
                         test_count, description);

                $display("Expected: %016b (%0d)",
                         expected_value, $signed(expected_value));

                $display("Actual:   %016b (%0d)",
                         out, $signed(out));

                $display("----------------------------------------");

            end
            else begin
                $display("PASS Test %0d: %0s",
                         test_count, description);
            end
        end
    endtask


    // =========================================
    // RUN ONE COMPLETE CLOCK CYCLE
    // =========================================

    task run_test;
        input [15:0] data;
        input load_value;
        input [15:0] expected_value;

        begin

            // Set inputs before the rising edge
            in = data;
            load = load_value;

            // TICK: Rising edge
            @(posedge clk);
            #1;

            check_output(expected_value,
                         "After TICK (posedge)");

            // TOCK: Falling edge
            @(negedge clk);
            #1;

            check_output(expected_value,
                         "After TOCK (negedge)");

        end
    endtask


    // =========================================
    // MAIN TEST SEQUENCE
    // =========================================

    initial begin

        $dumpfile("dump.vcd");
        $dumpvars(0, register_tb);

        test_count = 0;
        fail_count = 0;

        clk = 0;
        in = 0;
        load = 0;


        // =====================================
        // INITIAL TESTS
        // =====================================

        // Initial value is unknown
        run_test(16'd0, 0, 16'hxxxx);

        // Load zero
        run_test(16'd0, 1, 16'd0);

        // Hold zero
        run_test(-16'sd32123, 0, 16'd0);

        run_test(16'd11111, 0, 16'd0);

        // Load -32123
        run_test(-16'sd32123, 1, -16'sd32123);

        // Load same value again
        run_test(-16'sd32123, 1, -16'sd32123);

        // Hold -32123
        run_test(-16'sd32123, 0, -16'sd32123);

        // Load 12345
        run_test(16'd12345, 1, 16'd12345);

        // Hold 12345
        run_test(16'd0, 0, 16'd12345);

        // Load zero
        run_test(16'd0, 1, 16'd0);


        // =====================================
        // LONG HOLD TEST: INPUT = 0
        // =====================================

        expected = 16'd0;

        for (i = 0; i < 50; i = i + 1) begin
            run_test(16'd0, 0, expected);
        end


        // Load zero once again
        run_test(16'd0, 1, 16'd0);


        // =====================================
        // LONG HOLD TEST: INPUT = 1
        // =====================================

        // Stored value must remain zero
        for (i = 0; i < 50; i = i + 1) begin
            run_test(16'd1, 0, 16'd0);
        end


        // =====================================
        // TEST EACH INDIVIDUAL BIT
        // =====================================

        expected = 16'd0;

        for (i = 0; i < 16; i = i + 1) begin

            // Load disabled: retain previous value
            run_test(16'h0001 << i,
                     0,
                     expected);

            // Load enabled: store the new value
            run_test(16'h0001 << i,
                     1,
                     16'h0001 << i);

            // Update expected stored value
            expected = 16'h0001 << i;

        end


        // =====================================
        // TEST INVERTED BIT PATTERNS
        // =====================================

        for (i = 0; i < 16; i = i + 1) begin

            // Load disabled: retain previous value
            run_test(~(16'h0001 << i),
                     0,
                     expected);

            // Load enabled: store inverted pattern
            run_test(~(16'h0001 << i),
                     1,
                     ~(16'h0001 << i));

            // Update expected stored value
            expected = ~(16'h0001 << i);

        end


        // =====================================
        // FINAL SUMMARY
        // =====================================

        $display("");
        $display("====================================");
        $display("       REGISTER TEST SUMMARY");
        $display("====================================");

        $display("Total tests : %0d", test_count);
        $display("Passed tests: %0d", test_count - fail_count);
        $display("Failed tests: %0d", fail_count);

        if (fail_count == 0)
            $display("ALL TESTS PASSED!");
        else
            $display("SOME TESTS FAILED!");

        $display("====================================");

        $finish;

    end

endmodule
