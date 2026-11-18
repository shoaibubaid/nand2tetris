
`timescale 1ns/1ps

module memory_subsystem_tb;

    reg clk;
    reg reset;

    reg req;
    reg mem_read;
    reg mem_write;

    reg [31:0] address;
    reg [31:0] write_data;
    reg [2:0] funct3;

    wire ready;
    wire [31:0] read_data;
    wire access_error;

    integer errors = 0;
    integer tests = 0;

    memory_subsystem dut (
        .clk(clk),
        .reset(reset),

        .req(req),
        .mem_read(mem_read),
        .mem_write(mem_write),

        .address(address),
        .write_data(write_data),
        .funct3(funct3),

        .ready(ready),
        .read_data(read_data),
        .access_error(access_error)
    );

    // 10 ns clock
    initial clk = 0;
    always #5 clk = ~clk;


    // ------------------------------------------------
    // Memory transaction task
    // ------------------------------------------------

    task transact;
        input [31:0] addr;
        input read_en;
        input write_en;
        input [31:0] wdata;
        input [2:0] operation;
        input [31:0] expected_data;
        input expected_error;

        integer cycles;
        integer transaction_errors;

        begin
            tests = tests + 1;
            cycles = 0;
            transaction_errors = 0;

            // Present request
            @(negedge clk);

            address = addr;
            mem_read = read_en;
            mem_write = write_en;
            write_data = wdata;
            funct3 = operation;
            req = 1;

            // Wait for response
            while (!ready && cycles < 20) begin
                @(posedge clk);
                #1;
                cycles = cycles + 1;
            end

            if (!ready) begin
                $display("FAIL: Timeout at address %h", addr);
                transaction_errors = transaction_errors + 1;
            end
            else begin

                // Check error status
                if (access_error !== expected_error) begin
                    $display(
                        "FAIL: Error at %h. Expected=%b Got=%b",
                        addr, expected_error, access_error
                    );

                    transaction_errors = transaction_errors + 1;
                end

                // Check read result
                if (read_en && !expected_error) begin
                    if (read_data !== expected_data) begin
                        $display(
                            "FAIL: Read at %h. Expected=%h Got=%h",
                            addr, expected_data, read_data
                        );

                        transaction_errors = transaction_errors + 1;
                    end
                end
            end

            if (transaction_errors == 0)
                $display("PASS: Address %h", addr);
            else
                errors = errors + transaction_errors;

            // Release request
            @(negedge clk);

            req = 0;
            mem_read = 0;
            mem_write = 0;

            // Allow controller to return to IDLE
            @(posedge clk);
            #1;
        end
    endtask


    // ------------------------------------------------
    // Main test sequence
    // ------------------------------------------------

    initial begin

        reset = 1;

        req = 0;
        mem_read = 0;
        mem_write = 0;

        address = 0;
        write_data = 0;
        funct3 = 3'b010;

        repeat (3) @(posedge clk);
        #1;

        reset = 0;


        // ============================================
        // 1. MAIN RAM TESTS
        // ============================================

        $display("\n--- MAIN RAM TESTS ---");

        // Write word
        transact(
            32'h00000000,
            0, 1,
            32'h12345678,
            3'b010,
            32'b0,
            0
        );

        // Read word
        transact(
            32'h00000000,
            1, 0,
            32'b0,
            3'b010,
            32'h12345678,
            0
        );


        // ============================================
        // 2. FRAMEBUFFER TESTS
        // ============================================

        $display("\n--- FRAMEBUFFER TESTS ---");

        // Initialize framebuffer word 0
        transact(
            32'h10000000,
            0, 1,
            32'h44332211,
            3'b010,
            32'b0,
            0
        );

        // Read initialized word
        transact(
            32'h10000000,
            1, 0,
            32'b0,
            3'b010,
            32'h44332211,
            0
        );

        // Modify pixel at byte offset 1
        transact(
            32'h10000001,
            0, 1,
            32'h000000AA,
            3'b000,
            32'b0,
            0
        );

        // Verify neighboring pixels are preserved
        transact(
            32'h10000000,
            1, 0,
            32'b0,
            3'b010,
            32'h4433AA11,
            0
        );

        // Read modified pixel as unsigned byte
        transact(
            32'h10000001,
            1, 0,
            32'b0,
            3'b100,
            32'h000000AA,
            0
        );

        // Last valid framebuffer byte
        transact(
            32'h10012BFF,
            0, 1,
            32'h000000FE,
            3'b000,
            32'b0,
            0
        );

        // Read last valid byte
        transact(
            32'h10012BFF,
            1, 0,
            32'b0,
            3'b100,
            32'h000000FE,
            0
        );

        // First invalid framebuffer address
        transact(
            32'h10012C00,
            1, 0,
            32'b0,
            3'b000,
            32'b0,
            1
        );

        // Misaligned halfword access
        transact(
            32'h10000001,
            1, 0,
            32'b0,
            3'b001,
            32'b0,
            1
        );

        // Misaligned word access
        transact(
            32'h10000002,
            0, 1,
            32'h12345678,
            3'b010,
            32'b0,
            1
        );


        // ============================================
        // 3. KEYBOARD TEST
        // ============================================

        $display("\n--- KEYBOARD TEST ---");

        transact(
            32'h20000000,
            1, 0,
            32'b0,
            3'b010,
            32'b0,
            0
        );


        // ============================================
        // 4. TIMER TEST
        // ============================================

        $display("\n--- TIMER TEST ---");

        transact(
            32'h20000010,
            1, 0,
            32'b0,
            3'b010,
            32'b0,
            0
        );


        // ============================================
        // 5. INVALID ADDRESS TEST
        // ============================================

        $display("\n--- INVALID ADDRESS TEST ---");

        transact(
            32'h30000000,
            1, 0,
            32'b0,
            3'b010,
            32'b0,
            1
        );


        // ============================================
        // 6. RAM AFTER PERIPHERAL ACCESS
        // ============================================

        $display("\n--- RAM RECHECK ---");

        transact(
            32'h00000004,
            0, 1,
            32'hDEADBEEF,
            3'b010,
            32'b0,
            0
        );

        transact(
            32'h00000004,
            1, 0,
            32'b0,
            3'b010,
            32'hDEADBEEF,
            0
        );


        // ============================================
        // RESULTS
        // ============================================

        $display("\n================================");
        $display("Tests  : %0d", tests);
        $display("Errors : %0d", errors);
        $display("================================");

        if (errors == 0)
            $display("ALL MEMORY SUBSYSTEM TESTS PASSED");
        else
            $display("MEMORY SUBSYSTEM TESTS FAILED");

        $finish;

    end

endmodule
