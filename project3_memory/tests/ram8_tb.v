
`timescale 1ns/1ps

module ram8_tb;

    reg clk;
    reg [2:0] address;
    reg [15:0] in;
    reg load;
    wire [15:0] out;

    reg [15:0] expected_mem [0:7];

    integer i;
    integer tests = 0;
    integer failures = 0;

    ram8 uut (
        .clk(clk),
        .address(address),
        .in(in),
        .load(load),
        .out(out)
    );

    // Clock: period = 10 ns
    initial clk = 0;
    always #5 clk = ~clk;

    // Check output against the reference memory
    task check_output;
        input [15:0] expected;
        input [2:0] addr;
        begin
            tests = tests + 1;

            if (out !== expected) begin
                failures = failures + 1;
                $display(
                    "FAIL | addr=%0d | expected=%h | got=%h | time=%0t",
                    addr, expected, out, $time
                );
            end
        end
    endtask

    // One complete clock cycle: tick and tock
    task cycle;
        input [15:0] data;
        input write_enable;
        input [2:0] addr;

        begin
            // Drive inputs away from the rising edge
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

    // Change address and check combinational read output
    task eval_read;
        input [2:0] addr;
        begin
            address = addr;
            #1;
            check_output(expected_mem[addr], addr);
        end
    endtask

    // Read and verify all eight addresses
    task check_all;
        integer j;
        begin
            for (j = 0; j < 8; j = j + 1)
                eval_read(j);
        end
    endtask

    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, ram8_tb);
        in = 0;
        load = 0;
        address = 0;

        // Reference memory starts unknown, just like the hardware.
        for (i = 0; i < 8; i = i + 1)
            expected_mem[i] = 16'hxxxx;

        // ------------------------------------------------
        // Initialisation and basic read/write operations
        // ------------------------------------------------

        // First write a known zero to address 0.
        cycle(16'd0, 1, 3'd0);

        cycle(16'd11111, 0, 3'd0);
        cycle(16'd11111, 1, 3'd1);
        cycle(16'd11111, 0, 3'd0);

        cycle(16'd3333, 0, 3'd3);
        cycle(16'd3333, 1, 3'd3);
        cycle(16'd3333, 0, 3'd3);

        eval_read(3'd1);

        cycle(16'd7777, 0, 3'd1);
        cycle(16'd7777, 1, 3'd7);
        cycle(16'd7777, 0, 3'd7);

        eval_read(3'd3);
        eval_read(3'd7);

        cycle(16'd7777, 0, 3'd0);
        check_all();

        // ------------------------------------------------
        // Write 0101... to every address
        // ------------------------------------------------

        for (i = 0; i < 8; i = i + 1)
            cycle(16'b0101010101010101, 1, i);

        cycle(16'b0101010101010101, 0, 3'd0);
        check_all();

        // ------------------------------------------------
        // Write 1010... to address 0 only
        // ------------------------------------------------

        cycle(16'b1010101010101010, 1, 3'd0);

        cycle(16'b1010101010101010, 0, 3'd0);
        check_all();

        // ------------------------------------------------
        // Write alternating patterns to address pairs
        // ------------------------------------------------

        for (i = 0; i < 7; i = i + 1) begin
            cycle(16'b0101010101010101, 1, i);
            cycle(16'b1010101010101010, 1, i + 1);

            cycle(16'b1010101010101010, 0, 3'd0);
            check_all();
        end

        // Final write to address 7
        cycle(16'b0101010101010101, 1, 3'd7);

        cycle(16'b0101010101010101, 0, 3'd0);
        check_all();

        // ------------------------------------------------
        // Summary
        // ------------------------------------------------

        $display("\n================================");
        $display("RAM8 TEST SUMMARY");
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
