
`timescale 1ns/1ps

module data_memory_tb;

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

    integer errors;

    data_memory dut (
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

    // 10 ns clock period
    always #5 clk = ~clk;

    // ---------------------------------------------
    // Send one memory request and wait for response
    // ---------------------------------------------

    task transact;
        input is_read;
        input is_write;
        input [31:0] addr;
        input [31:0] data;
        input [2:0] operation;

        output reg [31:0] result;
        output reg error;

        integer cycles;

        begin
            @(negedge clk);

            req        = 1'b1;
            mem_read   = is_read;
            mem_write  = is_write;
            address    = addr;
            write_data = data;
            funct3     = operation;

            cycles = 0;

            while ((ready !== 1'b1) && (cycles < 10)) begin
                @(posedge clk);
                cycles = cycles + 1;
            end

            #1;

            if (ready !== 1'b1) begin
                $display("TIMEOUT: address=%h", addr);
                $fatal(1, "Memory controller did not respond");
            end

            result = read_data;
            error  = access_error;

            // Release request.
            @(negedge clk);
            req = 1'b0;

            // Allow controller to return to IDLE.
            @(posedge clk);
            #1;
        end
    endtask

    // ---------------------------------------------
    // Check store
    // ---------------------------------------------

    task check_store;
        input [31:0] addr;
        input [31:0] data;
        input [2:0] operation;
        input expected_error;

        reg [31:0] result;
        reg error;

        begin
            transact(
                1'b0, 1'b1, addr, data, operation,
                result, error
            );

            if (error !== expected_error) begin
                $display(
                    "STORE ERROR: addr=%h funct3=%b expected_error=%b actual=%b",
                    addr, operation, expected_error, error
                );
                errors = errors + 1;
            end
            else begin
                $display(
                    "STORE PASS: addr=%h funct3=%b",
                    addr, operation
                );
            end
        end
    endtask

    // ---------------------------------------------
    // Check load
    // ---------------------------------------------

    task check_load;
        input [31:0] addr;
        input [2:0] operation;
        input [31:0] expected_data;
        input expected_error;

        reg [31:0] result;
        reg error;

        begin
            transact(
                1'b1, 1'b0, addr, 32'b0, operation,
                result, error
            );

            if ((error !== expected_error) ||
                (!expected_error && result !== expected_data)) begin

                $display(
                    "LOAD FAIL: addr=%h funct3=%b expected=%h actual=%h error=%b",
                    addr, operation, expected_data, result, error
                );

                errors = errors + 1;
            end
            else begin
                $display(
                    "LOAD PASS: addr=%h funct3=%b data=%h",
                    addr, operation, result
                );
            end
        end
    endtask

    // ---------------------------------------------
    // Test sequence
    // ---------------------------------------------

    reg [31:0] unused_result;
    reg unused_error;

    initial begin

        clk = 0;
        reset = 1;

        req = 0;
        mem_read = 0;
        mem_write = 0;
        address = 0;
        write_data = 0;
        funct3 = 0;

        errors = 0;

        repeat (3) @(posedge clk);
        @(negedge clk);
        reset = 0;

        // -----------------------------------------
        // 1. Full-word store and load
        // -----------------------------------------

        check_store(32'h00000000, 32'h11223344, 3'b010, 0);
        check_load (32'h00000000, 3'b010, 32'h11223344, 0);

        // -----------------------------------------
        // 2. Byte loads
        // Little-endian byte order
        // -----------------------------------------

        check_load(32'h00000000, 3'b000, 32'h00000044, 0); // LB
        check_load(32'h00000001, 3'b000, 32'h00000033, 0); // LB
        check_load(32'h00000002, 3'b000, 32'h00000022, 0); // LB
        check_load(32'h00000003, 3'b000, 32'h00000011, 0); // LB

        check_load(32'h00000003, 3'b100, 32'h00000011, 0); // LBU

        // -----------------------------------------
        // 3. Halfword loads
        // -----------------------------------------

        check_load(32'h00000000, 3'b001, 32'h00003344, 0); // LH
        check_load(32'h00000002, 3'b001, 32'h00001122, 0); // LH

        check_load(32'h00000002, 3'b101, 32'h00001122, 0); // LHU

        // -----------------------------------------
        // 4. Partial byte store
        // -----------------------------------------

        check_store(32'h00000001, 32'h000000AA, 3'b000, 0);

        check_load(
            32'h00000000, 3'b010,
            32'h1122AA44, 0
        );

        // -----------------------------------------
        // 5. Partial halfword store
        // -----------------------------------------

        check_store(32'h00000002, 32'h0000BEEF, 3'b001, 0);

        check_load(
            32'h00000000, 3'b010,
            32'hBEEFAA44, 0
        );

        // -----------------------------------------
        // 6. Signed load checks
        // -----------------------------------------

        check_store(32'h00000004, 32'h00000080, 3'b000, 0);

        check_load(
            32'h00000004, 3'b000,
            32'hFFFFFF80, 0
        );

        check_load(
            32'h00000004, 3'b100,
            32'h00000080, 0
        );

        check_store(32'h00000006, 32'h00008001, 3'b001, 0);

        check_load(
            32'h00000006, 3'b001,
            32'hFFFF8001, 0
        );

        check_load(
            32'h00000006, 3'b101,
            32'h00008001, 0
        );

        // -----------------------------------------
        // 7. Invalid alignment
        // -----------------------------------------

        check_load(32'h00000001, 3'b001, 32'b0, 1); // Misaligned LH
        check_load(32'h00000002, 3'b010, 32'b0, 1); // Misaligned LW

        check_store(32'h00000001, 32'h12345678, 3'b001, 1);
        check_store(32'h00000002, 32'h12345678, 3'b010, 1);

        // -----------------------------------------
        // 8. Out-of-range address
        // -----------------------------------------

        check_load(32'h00004000, 3'b010, 32'b0, 1);
        check_store(32'h00004000, 32'h12345678, 3'b010, 1);

        // -----------------------------------------
        // Final result
        // -----------------------------------------

        if (errors == 0) begin
            $display("");
            $display("==================================");
            $display(" ALL DATA MEMORY TESTS PASSED");
            $display("==================================");
        end
        else begin
            $display("");
            $display("==================================");
            $display(" TESTS FAILED: %0d errors", errors);
            $display("==================================");
            $fatal(1, "Data memory verification failed");
        end

        $finish;
    end

endmodule
