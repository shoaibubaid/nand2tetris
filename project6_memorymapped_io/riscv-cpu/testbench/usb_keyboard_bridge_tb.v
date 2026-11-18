
`timescale 1ns/1ps

module usb_keyboard_bridge_tb;

    reg ps_clk;
    reg cpu_clk;

    reg ps_reset;
    reg cpu_reset;

    reg ps_event_valid;
    wire ps_event_ready;
    reg [8:0] ps_event_data;

    wire cpu_event_valid;
    reg cpu_event_ready;
    wire [8:0] cpu_event_data;

    integer errors;

    usb_keyboard_bridge dut (
        .ps_clk(ps_clk),
        .ps_reset(ps_reset),

        .ps_event_valid(ps_event_valid),
        .ps_event_ready(ps_event_ready),
        .ps_event_data(ps_event_data),

        .cpu_clk(cpu_clk),
        .cpu_reset(cpu_reset),

        .cpu_event_valid(cpu_event_valid),
        .cpu_event_ready(cpu_event_ready),
        .cpu_event_data(cpu_event_data)
    );

    // Independent clocks:
    // PS clock period = 10 ns
    // CPU clock period = 14 ns
    initial ps_clk = 0;
    always #5 ps_clk = ~ps_clk;

    initial cpu_clk = 0;
    always #7 cpu_clk = ~cpu_clk;

    task send_event;
        input [8:0] event_data;
        begin
            // Wait until source interface is ready.
            @(negedge ps_clk);
            while (!ps_event_ready)
                @(negedge ps_clk);

            ps_event_data = event_data;
            ps_event_valid = 1'b1;

            @(negedge ps_clk);
            while (!ps_event_ready)
                @(negedge ps_clk);

            ps_event_valid = 1'b0;

            $display("PS sent event: %h", event_data);
        end
    endtask

    task receive_event;
        input [8:0] expected;
        begin
            wait (cpu_event_valid);
            #1;

            if (cpu_event_data !== expected) begin
                $display(
                    "FAIL: expected %h, received %h",
                    expected, cpu_event_data
                );
                errors = errors + 1;
            end
            else begin
                $display(
                    "PASS: received event %h",
                    cpu_event_data
                );
            end

            @(negedge cpu_clk);
            cpu_event_ready = 1'b1;

            @(negedge cpu_clk);
            cpu_event_ready = 1'b0;
        end
    endtask

    initial begin
        errors = 0;

        ps_reset = 1;
        cpu_reset = 1;

        ps_event_valid = 0;
        ps_event_data = 0;
        cpu_event_ready = 0;

        repeat (4) @(negedge ps_clk);
        ps_reset = 0;
        cpu_reset = 0;

        // Normal event transfers.
        fork
            begin
                send_event(9'h11A); // W pressed
                send_event(9'h01A); // W released
                send_event(9'h152); // Up pressed
            end

            begin
                receive_event(9'h11A);
                receive_event(9'h01A);
                receive_event(9'h152);
            end
        join

        // Test backpressure.
        // Consumer will not accept the event immediately.
        fork
            begin
                send_event(9'h11B);
            end

            begin
                wait (cpu_event_valid);
                #1;

                if (cpu_event_data !== 9'h11B) begin
                    $display("FAIL: backpressure data");
                    errors = errors + 1;
                end
                else begin
                    $display("PASS: event held during backpressure");
                end

                // Keep consumer stalled for several cycles.
                repeat (5) @(negedge cpu_clk);

                if (!cpu_event_valid ||
                    cpu_event_data !== 9'h11B) begin
                    $display("FAIL: event not held stable");
                    errors = errors + 1;
                end
                else begin
                    $display("PASS: event remains stable");
                end

                cpu_event_ready = 1;

                @(negedge cpu_clk);
                cpu_event_ready = 0;
            end
        join

        // Wait until source sees acknowledgement.
        wait (ps_event_ready);

        if (errors == 0)
            $display("ALL USB KEYBOARD BRIDGE TESTS PASSED");
        else
            $display(
                "USB KEYBOARD BRIDGE TESTS FAILED: %0d errors",
                errors
            );

        $finish;
    end

endmodule
