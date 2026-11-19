
`timescale 1ns/1ps

module framebuffer_tb;

    reg clk, reset;
    reg req, mem_read, mem_write;

    reg [16:0] offset;
    reg [31:0] write_data;
    reg [2:0] funct3;

    wire ready;
    wire [31:0] read_data;
    wire access_error;

    integer tests = 0;
    integer errors = 0;
    integer cycles;

    framebuffer dut (
        .clk(clk),
        .reset(reset),
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

    task transact;
        input [16:0] addr;
        input read_en;
        input write_en;
        input [31:0] wdata;
        input [2:0] operation;
        input [31:0] expected_data;
        input expected_error;

        begin
            tests = tests + 1;

            @(negedge clk);
            offset = addr;
            mem_read = read_en;
            mem_write = write_en;
            write_data = wdata;
            funct3 = operation;
            req = 1;

            cycles = 0;

            while (!ready && cycles < 10) begin
                @(posedge clk);
                #1;
                cycles = cycles + 1;
            end

            if (!ready) begin
                $display("FAIL: Timeout at offset %0d", addr);
                errors = errors + 1;
            end
            else begin
                if (access_error !== expected_error) begin
                    $display("FAIL: Error at offset %0d", addr);
                    $display("Expected error=%b, got=%b",
                             expected_error, access_error);
                    errors = errors + 1;
                end

                if (read_en && !expected_error &&
                    read_data !== expected_data) begin
                    $display("FAIL: Read at offset %0d", addr);
                    $display("Expected=%h, got=%h",
                             expected_data, read_data);
                    errors = errors + 1;
                end

                if (errors == 0)
                    $display("PASS: Offset %0d", addr);
            end

            @(negedge clk);
            req = 0;
            mem_read = 0;
            mem_write = 0;

            @(posedge clk);
            #1;
        end
    endtask

    initial begin
        reset = 1;
        req = 0;
        mem_read = 0;
        mem_write = 0;
        offset = 0;
        write_data = 0;
        funct3 = 0;

        repeat (3) @(posedge clk);
        #1;
        reset = 0;

        // 1. Initialize first word
        transact(0, 0, 1,
                 32'h44332211, 3'b010, 0, 0);

        // 2. Read full word
        transact(0, 1, 0,
                 0, 3'b010, 32'h44332211, 0);

        // 3. Change pixel at byte offset 1
        transact(1, 0, 1,
                 32'h000000AA, 3'b000, 0, 0);

        // 4. Verify neighboring pixels are preserved
        transact(0, 1, 0,
                 0, 3'b010, 32'h4433AA11, 0);

        // 5. Unsigned byte load
        transact(1, 1, 0,
                 0, 3'b100, 32'h000000AA, 0);

        // 6. Store a byte with its sign bit set
        transact(2, 0, 1,
                 32'h00000080, 3'b000, 0, 0);

        // 7. Signed byte load
        transact(2, 1, 0,
                 0, 3'b000, 32'hFFFFFF80, 0);

        // 8. Initialize halfword
        transact(4, 0, 1,
                 32'h00008001, 3'b001, 0, 0);

        // 9. Signed halfword load
        transact(4, 1, 0,
                 0, 3'b001, 32'hFFFF8001, 0);

        // 10. Unsigned halfword load
        transact(4, 1, 0,
                 0, 3'b101, 32'h00008001, 0);

        // 11. Last valid framebuffer byte
        transact(76799, 0, 1,
                 32'h000000FE, 3'b000, 0, 0);

        // 12. Read last valid byte
        transact(76799, 1, 0,
                 0, 3'b100, 32'h000000FE, 0);

        // 13. Out-of-range address
        transact(76800, 1, 0,
                 0, 3'b000, 0, 1);

        // 14. Misaligned halfword
        transact(1, 1, 0,
                 0, 3'b001, 0, 1);

        // 15. Misaligned word
        transact(2, 0, 1,
                 32'h12345678, 3'b010, 0, 1);

        $display("--------------------------------");
        $display("Tests: %0d", tests);
        $display("Errors: %0d", errors);

        if (errors == 0)
            $display("ALL FRAMEBUFFER TESTS PASSED");
        else
            $display("FRAMEBUFFER TESTS FAILED");

        $finish;
    end

endmodule
