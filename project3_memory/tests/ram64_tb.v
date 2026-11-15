
`timescale 1ns/1ps

module ram64_tb;

    reg clk;
    reg [5:0] address;
    reg [15:0] in;
    reg load;
    wire [15:0] out;

    reg [15:0] expected_mem [0:63];

    integer i;
    integer tests = 0;
    integer failures = 0;

    ram64 uut (
        .clk(clk),
        .address(address),
        .in(in),
        .load(load),
        .out(out)
    );

    // Clock: 10 ns period
    initial clk = 0;
    always #5 clk = ~clk;

    // VCD waveform
    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, ram64_tb);
    end

    // Compare output with expected value
    task check_output;
        input [15:0] expected;
        input [5:0] addr;
        begin
            // Skip checks when expected value is unknown
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
        input [5:0] addr;

        begin
            @(negedge clk);

            in = data;
            load = write_enable;
            address = addr;

            // TICK
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
        input [5:0] addr;
        begin
            address = addr;
            #1;
            check_output(expected_mem[addr], addr);
        end
    endtask

    // Check a consecutive range of addresses
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

        // Initially, memory contents are unknown
        for (i = 0; i < 64; i = i + 1)
            expected_mem[i] = 16'hxxxx;

        // ============================================
        // Basic tests: addresses 0, 13, 47 and 63
        // ============================================

        cycle(16'd0, 0, 6'd0);
        cycle(16'd0, 1, 6'd0);

        cycle(16'd1313, 0, 6'd0);
        cycle(16'd1313, 1, 6'd13);

        cycle(16'd1313, 0, 6'd0);

        cycle(16'd4747, 0, 6'd47);
        cycle(16'd4747, 1, 6'd47);
        cycle(16'd4747, 0, 6'd47);

        eval_read(6'd13);

        cycle(16'd6363, 0, 6'd13);
        cycle(16'd6363, 1, 6'd63);
        cycle(16'd6363, 0, 6'd63);

        eval_read(6'd47);
        eval_read(6'd63);

        // ============================================
        // Test addresses 40 to 47
        // ============================================

        cycle(16'd6363, 0, 6'd40);
        check_range(41, 47);

        // Write 0101... to addresses 40 through 47
        for (i = 40; i <= 47; i = i + 1)
            cycle(16'b0101010101010101, 1, i);

        cycle(16'b0101010101010101, 0, 6'd40);
        check_range(40, 47);

        // Overwrite address 40 with 1010...
        cycle(16'b1010101010101010, 1, 6'd40);

        cycle(16'b1010101010101010, 0, 6'd40);
        check_range(40, 47);

        // Alternating writes to consecutive addresses
        for (i = 40; i < 47; i = i + 1) begin
            cycle(16'b0101010101010101, 1, i);
            cycle(16'b1010101010101010, 1, i + 1);
        end

        // Final write to address 47
        cycle(16'b0101010101010101, 1, 6'd47);

        cycle(16'b0101010101010101, 0, 6'd40);
        check_range(40, 47);

        // ============================================
        // Test addresses:
        // 5, 13, 21, 29, 37, 45, 53, 61
        // ============================================

        cycle(16'b0101010101010101, 0, 6'd5);

        // Initially check all eight locations
        for (i = 13; i <= 61; i = i + 8)
            eval_read(i);

        // Write 0101... to all eight addresses
        for (i = 5; i <= 61; i = i + 8)
            cycle(16'b0101010101010101, 1, i);

        cycle(16'b0101010101010101, 0, 6'd5);
        check_range(5, 61);

        // Overwrite address 5 with 1010...
        cycle(16'b1010101010101010, 1, 6'd5);

        cycle(16'b1010101010101010, 0, 6'd5);

        // Check all eight selected addresses
        for (i = 5; i <= 61; i = i + 8)
            eval_read(i);

        // Alternating writes to consecutive locations
        // separated by 8 addresses
        for (i = 5; i < 61; i = i + 8) begin
            cycle(16'b0101010101010101, 1, i);
            cycle(16'b1010101010101010, 1, i + 8);
        end

        // Final write to address 61
        cycle(16'b0101010101010101, 1, 6'd61);

        cycle(16'b0101010101010101, 0, 6'd5);

        // Verify all eight locations
        for (i = 5; i <= 61; i = i + 8)
            eval_read(i);

        // ============================================
        // Final summary
        // ============================================

        $display("\n================================");
        $display("RAM64 TEST SUMMARY");
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
