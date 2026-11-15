
module dff_tb;

    reg clk;
    reg in;
    wire out;

    integer test_count;
    integer fail_count;

    dff uut(
        .clk(clk),
        .in(in),
        .out(out)
    );

    // Clock period = 10 time units
    always #5 clk = ~clk;

    // Output checking task
    task check_output;
        input expected;
        input [8*50-1:0] description;

        begin
            test_count = test_count + 1;

            if (out !== expected) begin
                fail_count = fail_count + 1;

                $display("FAIL Test %0d: %0s", test_count, description);
                $display("Expected: %b | Actual: %b", expected, out);
            end
            else begin
                $display("PASS Test %0d: %0s", test_count, description);
            end
        end
    endtask

    initial begin

        $dumpfile("dump.vcd");
        $dumpvars(0, dff_tb);

        test_count = 0;
        fail_count = 0;

        clk = 0;
        in = 0;

        // Test 1: Capture 0 at time 5
        #6;
        check_output(1'b0, "Input 0 captured at rising edge");

        // Test 2: Change input without rising edge
        in = 1;
        #2;
        check_output(1'b0, "Output unchanged without rising edge");

        // Test 3: Capture 1 at time 15
        #8;
        check_output(1'b1, "Input 1 captured at rising edge");

        // Test 4: Change input without rising edge
        in = 0;
        #2;
        check_output(1'b1, "Output retains previous value");

        // Test 5: Capture 0 at time 25
        #8;
        check_output(1'b0, "Input 0 captured at rising edge");

        // Test 6: Capture 1 at time 35
        in = 1;
        #10;
        check_output(1'b1, "Input 1 captured at rising edge");

        // Test 7: Capture 0 at time 45
        in = 0;
        #10;
        check_output(1'b0, "Input 0 captured at rising edge");

        // Final summary
        $display("");
        $display("================================");
        $display("         DFF TEST SUMMARY");
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
