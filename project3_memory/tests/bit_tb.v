
module bit_tb;

    reg clk;
    reg in;
    reg load;
    wire out;

    integer test_count;
    integer fail_count;
    integer i;

    reg expected;

    bit_gate uut(
        .clk(clk),
        .in(in),
        .load(load),
        .out(out)
    );

    // Clock generation
    always #5 clk = ~clk;

    // Check output
    task check_output;
        input expected_value;
        input [8*50-1:0] description;

        begin
            test_count = test_count + 1;

            if (out !== expected_value) begin
                fail_count = fail_count + 1;

                $display("FAIL Test %0d: %0s",
                         test_count, description);

                $display("Expected: %b | Actual: %b",
                         expected_value, out);
            end
            else begin
                $display("PASS Test %0d: %0s",
                         test_count, description);
            end
        end
    endtask

    // Apply input, wait for rising edge, and check output
    task run_test;
        input data;
        input load_value;
        input expected_value;

        begin
            @(negedge clk);

            in = data;
            load = load_value;

            @(posedge clk);
            #1;

            check_output(expected_value,
                         "Output after rising clock edge");

            // Check that output remains stable through falling edge
            @(negedge clk);
            #1;

            check_output(expected_value,
                         "Output retained after falling edge");
        end
    endtask

    initial begin

        $dumpfile("dump.vcd");
        $dumpvars(0, bit_tb);

        test_count = 0;
        fail_count = 0;

        clk = 0;
        in = 0;
        load = 0;

        // =====================================
        // INITIALIZE STORAGE
        // =====================================

        // First write a known value because DFF has no reset
        run_test(0, 1, 0);

        // =====================================
        // BASIC LOAD TESTS
        // =====================================

        run_test(0, 0, 0);
        run_test(1, 0, 0);
        run_test(1, 1, 1);
        run_test(0, 0, 1);
        run_test(0, 1, 0);
        run_test(1, 1, 1);
        run_test(0, 0, 1);

        // =====================================
        // HOLD VALUE FOR MANY CLOCK CYCLES
        // =====================================

        // Stored value = 1
        // Input = 0, Load = 0
        for (i = 0; i < 50; i = i + 1) begin
            run_test(0, 0, 1);
        end

        // =====================================
        // CHANGE STORED VALUE
        // =====================================

        run_test(0, 1, 0);

        // =====================================
        // CHANGE INPUT WITHOUT LOADING
        // =====================================

        // Stored value = 0
        // Input = 1, Load = 0
        for (i = 0; i < 50; i = i + 1) begin
            run_test(1, 0, 0);
        end

        // =====================================
        // FINAL SUMMARY
        // =====================================

        $display("");
        $display("================================");
        $display("         BIT TEST SUMMARY");
        $display("================================");

        $display("Total tests : %0d", test_count);
        $display("Passed tests: %0d", test_count - fail_count);
        $display("Failed tests: %0d", fail_count);

        if (fail_count == 0)
            $display("ALL TESTS PASSED!");
        else
            $display("SOME TESTS FAILED!");

        $display("================================");

        $finish;
    end

endmodule
