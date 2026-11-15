
`timescale 1ns/1ps

module pc_tb;

    reg clk;
    reg [15:0] in;
    reg reset, load, inc;
    wire [15:0] out;

    reg [15:0] expected;
    reg valid;

    integer tests;
    integer failures;

    pc uut (
        .clk(clk),
        .in(in),
        .reset(reset),
        .load(load),
        .inc(inc),
        .out(out)
    );

    initial begin
        $dumpfile("pc.vcd");
        $dumpvars(0, pc_tb);
    end

    // Check the current PC output.
    task check_output;
        begin
            tests = tests + 1;

            if (valid) begin
                if (out !== expected) begin
                    $display(
                        "FAIL: in=%0d reset=%b load=%b inc=%b expected=%0d got=%0d time=%0t",
                        $signed(in), reset, load, inc,
                        $signed(expected), $signed(out), $time
                    );
                    failures = failures + 1;
                end
                else begin
                    $display(
                        "PASS: in=%0d reset=%b load=%b inc=%b out=%0d time=%0t",
                        $signed(in), reset, load, inc,
                        $signed(out), $time
                    );
                end
            end
            else begin
                // Before the first load/reset, PC is uninitialized.
                if ((^out) !== 1'bx) begin
                    $display("FAIL: Expected unknown PC, got %0d", out);
                    failures = failures + 1;
                end
                else begin
                    $display("PASS: PC is uninitialized, as expected");
                end
            end
        end
    endtask

    // Equivalent to NAND2Tetris tick.
    task tick_op;
        begin
            // Allow inputs and combinational logic to settle.
            #1;
            clk = 1'b1;
            #1;

            // Update reference model using PC priority.
            if (reset) begin
                expected = 16'd0;
                valid = 1'b1;
            end
            else if (load) begin
                expected = in;
                valid = 1'b1;
            end
            else if (inc) begin
                expected = expected + 16'd1;
            end
        end
    endtask

    // Equivalent to NAND2Tetris tock.
    task tock_op;
        begin
            clk = 1'b0;
            #1;
        end
    endtask

    initial begin
        clk = 0;
        in = 0;
        reset = 0;
        load = 0;
        inc = 0;

        expected = 16'd0;
        valid = 0;
        tests = 0;
        failures = 0;

        // ------------------------------------------------
        // Original PC.tst sequence
        // ------------------------------------------------

        // set in 0, reset 0, load 0, inc 0
        tick_op;
        check_output;
        tock_op;
        check_output;

        // set inc 1
        inc = 1;
        tick_op;
        check_output;
        tock_op;
        check_output;

        // set in -32123
        in = -16'sd32123;
        tick_op;
        check_output;
        tock_op;
        check_output;

        // set load 1
        load = 1;
        tick_op;
        check_output;
        tock_op;
        check_output;

        // set load 0
        load = 0;
        tick_op;
        check_output;
        tock_op;
        check_output;

        tick_op;
        check_output;
        tock_op;
        check_output;

        // set in 12345, load 1, inc 0
        in = 16'd12345;
        load = 1;
        inc = 0;
        tick_op;
        check_output;
        tock_op;
        check_output;

        // set reset 1
        reset = 1;
        tick_op;
        check_output;
        tock_op;
        check_output;

        // set reset 0, inc 1
        reset = 0;
        inc = 1;
        tick_op;
        check_output;
        tock_op;
        check_output;

        // set reset 1
        reset = 1;
        tick_op;
        check_output;
        tock_op;
        check_output;

        // set reset 0, load 0
        reset = 0;
        load = 0;
        tick_op;
        check_output;
        tock_op;
        check_output;

        // set reset 1
        reset = 1;
        tick_op;
        check_output;
        tock_op;
        check_output;

        // set in 0, reset 0, load 1
        in = 0;
        reset = 0;
        load = 1;
        tick_op;
        check_output;
        tock_op;
        check_output;

        // set load 0, inc 1
        load = 0;
        inc = 1;
        tick_op;
        check_output;
        tock_op;
        check_output;

        // set in 22222, reset 1, inc 0
        in = 16'd22222;
        reset = 1;
        inc = 0;
        tick_op;
        check_output;
        tock_op;
        check_output;

        // ------------------------------------------------
        // Summary
        // ------------------------------------------------

        $display("\n==================================");
        $display("PC TEST SUMMARY");
        $display("Total checkpoints : %0d", tests);
        $display("Failures          : %0d", failures);
        $display("Passed            : %0d", tests - failures);
        $display("==================================");

        if (failures == 0)
            $display("ALL TESTS PASSED");
        else
            $display("SOME TESTS FAILED");

        $finish;
    end

endmodule
