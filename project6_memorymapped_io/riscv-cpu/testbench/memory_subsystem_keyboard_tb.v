
`timescale 1ns/1ps

module memory_subsystem_keyboard_tb;

    // ------------------------------------------------
    // Clock and reset
    // ------------------------------------------------

    reg clk = 0;
    reg ps_clk = 0;

    always #5 clk = ~clk;       // 100 MHz CPU clock
    always #7 ps_clk = ~ps_clk; // Different PS clock

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
    // PS USB event interface
    // ------------------------------------------------

    reg ps_event_valid = 0;
    wire ps_event_ready;
    reg [8:0] ps_event_data = 0;

    // ------------------------------------------------
    // DUT
    // ------------------------------------------------

    memory_subsystem dut (
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

    integer errors = 0;
    integer timeout;

    // ------------------------------------------------
    // Send one event from the PS clock domain
    // ------------------------------------------------

    task send_event(input [8:0] key_event);
        begin
            @(negedge ps_clk);
            ps_event_data = key_event;
            ps_event_valid = 1;

            timeout = 0;

            // Wait for the bridge to accept the event.
            while (ps_event_ready !== 1'b1 && timeout < 100) begin
                @(negedge ps_clk);
                timeout = timeout + 1;
            end

            if (timeout >= 100) begin
                $display("ERROR: PS event was not accepted");
                errors = errors + 1;
            end
            else begin
                // Allow the accepting clock edge to occur.
                @(negedge ps_clk);
            end

            ps_event_valid = 0;
            ps_event_data = 0;
        end
    endtask

    // ------------------------------------------------
    // Read a memory-mapped register from the CPU bus
    // ------------------------------------------------

    task read_word(
        input [31:0] addr,
        output [31:0] value
    );
        begin
            @(negedge clk);

            address = addr;
            mem_read = 1;
            mem_write = 0;
            funct3 = 3'b010;
            req = 1;

            timeout = 0;

            while (ready !== 1'b1 && timeout < 100) begin
                @(negedge clk);
                timeout = timeout + 1;
            end

            if (timeout >= 100) begin
                $display("ERROR: Read timeout at address %h", addr);
                errors = errors + 1;
                value = 32'hXXXXXXXX;
            end
            else begin
                value = read_data;

                if (access_error) begin
                    $display("ERROR: Access error at address %h", addr);
                    errors = errors + 1;
                end
            end

            // Release the request so the controller can return to IDLE.
            @(negedge clk);
            req = 0;
            mem_read = 0;

            repeat (2) @(negedge clk);
        end
    endtask


    // ------------------------------------------------
    // Wait until an event crosses the CDC bridge
    // and reaches the keyboard FIFO.
    // ------------------------------------------------

    task wait_for_keyboard_event(output reg [31:0] status);
        integer poll_count;
        begin
            poll_count = 0;
            status = 0;

            while (status[0] !== 1'b1 && poll_count < 50) begin
                read_word(32'h20000004, status);
                poll_count = poll_count + 1;
            end

            if (status[0] !== 1'b1) begin
                $display("ERROR: Keyboard event did not reach FIFO");
                errors = errors + 1;
            end
        end
    endtask


    // ------------------------------------------------
    // Test variables
    // ------------------------------------------------

    reg [31:0] status;
    reg [31:0] key_data;

    // ------------------------------------------------
    // Main test sequence
    // ------------------------------------------------

    initial begin

        $display("----------------------------------------");
        $display("MEMORY SUBSYSTEM KEYBOARD TEST");
        $display("----------------------------------------");

        // Reset both clock domains.
        repeat (5) @(negedge clk);
        reset = 0;
        ps_reset = 0;

        repeat (5) @(negedge clk);

        // --------------------------------------------
        // TEST 1: Send W key press
        // --------------------------------------------

        $display("TEST 1: W key press");

        send_event(9'h11A);

        // Wait for the event to cross into the CPU domain.
        wait_for_keyboard_event(status);

        if (status[0] !== 1'b1) begin
            $display("FAIL: FIFO should be non-empty");
            errors = errors + 1;
        end
        else begin
            $display("PASS: FIFO reports non-empty");
        end

        if (status[6:2] !== 5'd1) begin
            $display("FAIL: Expected FIFO count 1, got %0d",
                    status[6:2]);
            errors = errors + 1;
        end
        else begin
            $display("PASS: FIFO count is 1");
        end

        // --------------------------------------------
        // TEST 2: Read W key press
        // --------------------------------------------

        $display("TEST 2: Read W key press");

        read_word(32'h20000000, key_data);

        if (key_data[8:0] !== 9'h11A) begin
            $display("FAIL: Expected 0x11A, got %h", key_data);
            errors = errors + 1;
        end
        else begin
            $display("PASS: Correct W press event: %h", key_data[8:0]);
        end

        // --------------------------------------------
        // TEST 3: FIFO should now be empty
        // --------------------------------------------

        $display("TEST 3: FIFO empty after pop");

        read_word(32'h20000004, status);

        if (status[0] !== 1'b0) begin
            $display("FAIL: FIFO should be empty");
            errors = errors + 1;
        end
        else begin
            $display("PASS: FIFO is empty");
        end

        // --------------------------------------------
        // TEST 4: Send W key release
        // --------------------------------------------

        $display("TEST 4: W key release");

        send_event(9'h01A);

        // Wait until the release event reaches the FIFO.
        wait_for_keyboard_event(status);

        read_word(32'h20000000, key_data);

        if (key_data[8:0] !== 9'h01A) begin
            $display("FAIL: Expected 0x01A, got %h", key_data);
            errors = errors + 1;
        end
        else begin
            $display("PASS: Correct W release event: %h",
                    key_data[8:0]);
        end
        // --------------------------------------------
        // TEST 5: Empty FIFO read
        // --------------------------------------------

        $display("TEST 5: Read from empty FIFO");

        read_word(32'h20000000, key_data);

        if (key_data !== 32'd0) begin
            $display("FAIL: Empty FIFO should return zero, got %h",
                     key_data);
            errors = errors + 1;
        end
        else begin
            $display("PASS: Empty FIFO returns zero");
        end

        // --------------------------------------------
        // Final result
        // --------------------------------------------

        $display("----------------------------------------");

        if (errors == 0)
            $display("ALL KEYBOARD INTEGRATION TESTS PASSED");
        else
            $display("KEYBOARD INTEGRATION FAILED: %0d errors",
                     errors);

        $display("----------------------------------------");

        $finish;
    end

endmodule
