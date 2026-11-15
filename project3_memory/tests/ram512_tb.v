
`timescale 1ns/1ps

module ram512_tb;

    reg clk;
    reg [8:0] address;
    reg [15:0] in;
    reg load;
    wire [15:0] out;

    reg [15:0] expected_mem [0:511];

    integer i;
    integer tests = 0;
    integer failures = 0;

    ram512 uut (
        .clk(clk),
        .address(address),
        .in(in),
        .load(load),
        .out(out)
    );

    // Clock: 10 ns period
    initial clk = 0;
    always #5 clk = ~clk;

    // Waveform dump
    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, ram512_tb);
    end

    // Compare output with expected memory value
    task check_output;
        input [15:0] expected;
        input [8:0] addr;
        begin
            // Skip checks for uninitialized memory
            if ((^expected) !== 1'bx) begin
                tests = tests + 1;

                if (out !== expected) begin
                    failures = failures + 1;
                    $display(
                        "FAIL | addr=%0d | expected=%h | got=%h | time=%0t",
                        addr, expected, out, $time
                    );
                end
            end
        end
    endtask

    // One complete clock cycle: tick and tock
    task cycle;
        input [15:0] data;
        input write_enable;
        input [8:0] addr;

        begin
            @(negedge clk);

            in = data;
            load = write_enable;
            address = addr;

            // TICK: write occurs on rising edge
            @(posedge clk);

            if (write_enable)
                expected_mem[addr] = data;

            #1;
            check_output(expected_mem[addr], addr);

            // TOCK
            @(negedge clk);
            #1;
            check_output(expected_mem[addr], addr);
        end
    endtask

    // Combinational read: change address without clock
    task eval_read;
        input [8:0] addr;
        begin
            address = addr;
            #1;
            check_output(expected_mem[addr], addr);
        end
    endtask

    // Check a range of consecutive addresses
    task check_range;
        input integer first;
        input integer last;
        integer j;
        begin
            for (j = first; j <= last; j = j + 1)
                eval_read(j);
        end
    endtask

    initial begin

        in = 0;
        load = 0;
        address = 0;

        // Memory starts uninitialized
        for (i = 0; i < 512; i = i + 1)
            expected_mem[i] = 16'hxxxx;

        // ============================================
        // Basic tests: addresses 0, 130, 472 and 511
        // ============================================

        cycle(16'd0, 0, 9'd0);
        cycle(16'd0, 1, 9'd0);

        cycle(16'd13099, 0, 9'd0);
        cycle(16'd13099, 1, 9'd130);

        cycle(16'd13099, 0, 9'd0);

        cycle(16'd4729, 0, 9'd472);
        cycle(16'd4729, 1, 9'd472);
        cycle(16'd4729, 0, 9'd472);

        eval_read(9'd130);

        cycle(16'd5119, 0, 9'd130);
        cycle(16'd5119, 1, 9'd511);
        cycle(16'd5119, 0, 9'd511);

        eval_read(9'd472);
        eval_read(9'd511);

        // ============================================
        // Test addresses 168 through 175
        // ============================================

        cycle(16'd5119, 0, 9'd168);
        check_range(169, 175);

        // Write 0101... to addresses 168 through 175
        for (i = 168; i <= 175; i = i + 1)
            cycle(16'b0101010101010101, 1, i);

        cycle(16'b0101010101010101, 0, 9'd168);
        check_range(168, 175);

        // Overwrite address 168 with 1010...
        cycle(16'b1010101010101010, 1, 9'd168);

        cycle(16'b1010101010101010, 0, 9'd168);
        check_range(168, 175);

        // Alternating writes to consecutive addresses
        for (i = 168; i < 175; i = i + 1) begin
            cycle(16'b0101010101010101, 1, i);
            cycle(16'b1010101010101010, 1, i + 1);
        end

        // Final write to address 175
        cycle(16'b0101010101010101, 1, 9'd175);

        cycle(16'b0101010101010101, 0, 9'd168);
        check_range(168, 175);

        // ============================================
        // Test addresses:
        // 42, 170, 298, 426, 554, 682, 810, 938
        // ============================================

        cycle(16'b0101010101010101, 0, 9'd42);

        for (i = 170; i <= 938; i = i + 128)
            eval_read(i);

        // Write 0101... to all eight addresses
        for (i = 42; i <= 490; i = i + 64)
            cycle(16'b0101010101010101, 1, i);

        cycle(16'b0101010101010101, 0, 9'd42);

        for (i = 170; i <= 938; i = i + 128)
            eval_read(i);

        // Overwrite address 42 with 1010...
        cycle(16'b1010101010101010, 1, 9'd42);

        cycle(16'b1010101010101010, 0, 9'd42);

        for (i = 170; i <= 938; i = i + 128)
            eval_read(i);

        // Alternating writes to consecutive locations
        // separated by 128 addresses
        for (i = 42; i < 938; i = i + 128) begin
            cycle(16'b0101010101010101, 1, i);
            cycle(16'b1010101010101010, 1, i + 128);
        end

        // Final write to address 938
        cycle(16'b0101010101010101, 1, 9'd490);

        cycle(16'b0101010101010101, 0, 9'd42);

        // Verify all eight locations
        for (i = 170; i <= 938; i = i + 128)
            eval_read(i);

        // ============================================
        // Final summary
        // ============================================

        $display("\n================================");
        $display("RAM512 TEST SUMMARY");
        $display("Total checks : %0d", tests);
        $display("Failures     : %0d", failures);

        if (failures == 0)
            $display("RESULT       : ALL TESTS PASSED");
        else
            $display("RESULT       : TESTS FAILED");

        $display("================================\n");

        $finish;
    end

endmodule
