
`timescale 1ns/1ps

module keyboard_controller_tb;

    reg clk, reset;

    reg event_valid;
    wire event_ready;
    reg [8:0] event_data;

    reg req, mem_read, mem_write;
    reg [3:0] offset;
    reg [31:0] write_data;
    reg [2:0] funct3;

    wire ready;
    wire [31:0] read_data;
    wire access_error;

    integer errors;
    integer i;

    keyboard_controller dut (
        .clk(clk),
        .reset(reset),

        .event_valid(event_valid),
        .event_ready(event_ready),
        .event_data(event_data),

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

    initial clk = 0;
    always #5 clk = ~clk;

    // Prevent a broken handshake from hanging forever.
    initial begin
        #100000;
        $display("FAIL: simulation timeout");
        $finish;
    end

    task push_event;
        input [8:0] data;
        begin
            @(negedge clk);
            while (!event_ready)
                @(negedge clk);

            event_data = data;
            event_valid = 1'b1;

            @(negedge clk);
            event_valid = 1'b0;
        end
    endtask

    task read_expect;
        input [3:0] address;
        input [2:0] size;
        input [31:0] expected_data;
        input expected_error;

        begin
            @(negedge clk);
            req = 1'b1;
            mem_read = 1'b1;
            mem_write = 1'b0;
            offset = address;
            funct3 = size;

            wait (ready);
            #1;

            if (read_data !== expected_data ||
                access_error !== expected_error) begin
                $display(
                    "FAIL: read offset=%h expected=%h err=%b got=%h err=%b",
                    address, expected_data, expected_error,
                    read_data, access_error
                );
                errors = errors + 1;
            end
            else begin
                $display(
                    "PASS: read offset=%h data=%h err=%b",
                    address, read_data, access_error
                );
            end

            @(negedge clk);
            req = 1'b0;
            mem_read = 1'b0;

            // Allow DONE -> IDLE.
            @(negedge clk);
        end
    endtask

    task write_expect;
        input [3:0] address;
        input [31:0] data;
        input expected_error;

        begin
            @(negedge clk);
            req = 1'b1;
            mem_read = 1'b0;
            mem_write = 1'b1;
            offset = address;
            write_data = data;
            funct3 = 3'b010;

            wait (ready);
            #1;

            if (access_error !== expected_error) begin
                $display("FAIL: write offset=%h", address);
                errors = errors + 1;
            end
            else begin
                $display("PASS: write offset=%h", address);
            end

            @(negedge clk);
            req = 1'b0;
            mem_write = 1'b0;

            @(negedge clk);
        end
    endtask

    initial begin
        errors = 0;

        reset = 1;
        event_valid = 0;
        event_data = 0;

        req = 0;
        mem_read = 0;
        mem_write = 0;
        offset = 0;
        write_data = 0;
        funct3 = 3'b010;

        repeat (3) @(negedge clk);
        reset = 0;

        // Empty FIFO.
        read_expect(4'h4, 3'b010, 32'h00000000, 0);
        read_expect(4'h0, 3'b010, 32'h00000000, 0);

        // Three USB HID events.
        push_event(9'h11A); // W pressed
        push_event(9'h052); // Up released
        push_event(9'h152); // Up pressed

        // Count=3, not_empty=1 -> 0x0D
        read_expect(4'h4, 3'b010, 32'h0000000D, 0);

        // Read events in FIFO order.
        read_expect(4'h0, 3'b010, 32'h0000011A, 0);
        read_expect(4'h0, 3'b010, 32'h00000052, 0);
        read_expect(4'h0, 3'b010, 32'h00000152, 0);

        read_expect(4'h4, 3'b010, 32'h00000000, 0);

        // Verify request held high does not pop twice.
        push_event(9'h11B);
        push_event(9'h01B);

        @(negedge clk);
        req = 1;
        mem_read = 1;
        mem_write = 0;
        offset = 4'h0;
        funct3 = 3'b010;

        wait (ready);
        #1;

        if (read_data !== 32'h0000011B) begin
            $display("FAIL: held request first event");
            errors = errors + 1;
        end

        repeat (5) @(posedge clk);
        #1;

        if (dut.fifo_count !== 1 ||
            read_data !== 32'h0000011B) begin
            $display("FAIL: repeated FIFO pop");
            errors = errors + 1;
        end
        else begin
            $display("PASS: no repeated pop while req held");
        end

        @(negedge clk);
        req = 0;
        mem_read = 0;
        @(negedge clk);

        read_expect(4'h0, 3'b010, 32'h0000001B, 0);

        // Invalid address and access width.
        read_expect(4'h8, 3'b010, 32'h0, 1);
        read_expect(4'h0, 3'b000, 32'h0, 1);

        // KEY_DATA is read-only.
        write_expect(4'h0, 32'h12345678, 1);

        // KEY_STATUS permits clearing overflow.
        write_expect(4'h4, 32'h00000002, 0);

        // Fill FIFO.
        for (i = 0; i < 16; i = i + 1)
            push_event(i[8:0]);

        if (event_ready !== 1'b0) begin
            $display("FAIL: FIFO backpressure");
            errors = errors + 1;
        end
        else begin
            $display("PASS: FIFO backpressure");
        end

        // Count=16, not_empty=1 -> 0x41
        read_expect(4'h4, 3'b010, 32'h00000041, 0);

        // Pop one entry, allowing another event.
        read_expect(4'h0, 3'b010, 32'h00000000, 0);

        if (event_ready !== 1'b1) begin
            $display("FAIL: FIFO did not release backpressure");
            errors = errors + 1;
        end
        else begin
            $display("PASS: backpressure released");
        end

        // Drain remaining entries.
        for (i = 1; i < 16; i = i + 1)
            read_expect(4'h0, 3'b010, i, 0);

        read_expect(4'h4, 3'b010, 32'h0, 0);

        if (errors == 0)
            $display("ALL KEYBOARD CONTROLLER TESTS PASSED");
        else
            $display(
                "KEYBOARD CONTROLLER TESTS FAILED: %0d errors",
                errors
            );

        $finish;
    end

endmodule
