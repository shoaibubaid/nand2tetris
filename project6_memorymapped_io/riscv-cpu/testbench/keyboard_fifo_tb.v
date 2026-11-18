
`timescale 1ns/1ps

module keyboard_fifo_tb;

    reg clk;
    reg reset;

    reg push;
    reg [8:0] data_in;

    reg pop;
    wire [8:0] data_out;

    wire empty;
    wire full;
    wire [4:0] count;
    wire overflow;

    reg clear_overflow;

    integer errors;
    integer i;

    keyboard_fifo dut (
        .clk(clk),
        .reset(reset),

        .push(push),
        .data_in(data_in),

        .pop(pop),
        .data_out(data_out),

        .empty(empty),
        .full(full),
        .count(count),
        .overflow(overflow),

        .clear_overflow(clear_overflow)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    task push_event;
        input [8:0] event_data;

        begin
            @(negedge clk);
            push = 1;
            data_in = event_data;

            @(negedge clk);
            push = 0;
        end
    endtask

    task pop_expect;
        input [8:0] expected;

        begin
            @(negedge clk);

            if (empty) begin
                $display("FAIL: FIFO unexpectedly empty");
                errors = errors + 1;
            end
            else if (data_out !== expected) begin
                $display(
                    "FAIL: expected %h, got %h",
                    expected, data_out
                );
                errors = errors + 1;
            end
            else begin
                $display("PASS: FIFO output = %h", data_out);
            end

            pop = 1;

            @(negedge clk);
            pop = 0;
        end
    endtask

    initial begin
        errors = 0;

        reset = 1;
        push = 0;
        pop = 0;
        data_in = 0;
        clear_overflow = 0;

        repeat (3) @(negedge clk);
        reset = 0;

        // Test reset state.
        #1;
        if (!empty || full || count != 0) begin
            $display("FAIL: reset state");
            errors = errors + 1;
        end
        else begin
            $display("PASS: reset state");
        end

        // Normal FIFO operation.
        push_event(9'h11A);
        push_event(9'h052);
        push_event(9'h01A);

        if (count != 3) begin
            $display("FAIL: count after three pushes");
            errors = errors + 1;
        end
        else begin
            $display("PASS: count after three pushes");
        end

        pop_expect(9'h11A);
        pop_expect(9'h052);

        push_event(9'h15A);

        pop_expect(9'h01A);
        pop_expect(9'h15A);

        if (!empty) begin
            $display("FAIL: FIFO should be empty");
            errors = errors + 1;
        end
        else begin
            $display("PASS: FIFO empty after draining");
        end

        // Fill the FIFO with 16 entries.
        for (i = 0; i < 16; i = i + 1)
            push_event(i[8:0]);

        if (!full || count != 16) begin
            $display("FAIL: FIFO full condition");
            errors = errors + 1;
        end
        else begin
            $display("PASS: FIFO full condition");
        end

        // Attempt one additional push.
        push_event(9'h1AA);

        if (!overflow || count != 16) begin
            $display("FAIL: overflow detection");
            errors = errors + 1;
        end
        else begin
            $display("PASS: overflow detection");
        end

        // Clear the sticky overflow flag.
        @(negedge clk);
        clear_overflow = 1;

        @(negedge clk);
        clear_overflow = 0;

        if (overflow) begin
            $display("FAIL: overflow clear");
            errors = errors + 1;
        end
        else begin
            $display("PASS: overflow clear");
        end

        // Simultaneous push and pop while full.
        @(negedge clk);
        push = 1;
        pop = 1;
        data_in = 9'h19A;

        @(negedge clk);
        push = 0;
        pop = 0;

        if (count != 16) begin
            $display("FAIL: count after simultaneous push/pop");
            errors = errors + 1;
        end
        else begin
            $display("PASS: simultaneous push/pop at full");
        end

        // Original first entry was removed.
        // New event should be at the end.
        for (i = 1; i < 16; i = i + 1)
            pop_expect(i[8:0]);

        pop_expect(9'h19A);

        if (!empty || count != 0) begin
            $display("FAIL: final FIFO state");
            errors = errors + 1;
        end
        else begin
            $display("PASS: final FIFO state");
        end

        if (errors == 0)
            $display("ALL KEYBOARD FIFO TESTS PASSED");
        else
            $display("KEYBOARD FIFO TESTS FAILED: %0d errors", errors);

        $finish;
    end

endmodule
