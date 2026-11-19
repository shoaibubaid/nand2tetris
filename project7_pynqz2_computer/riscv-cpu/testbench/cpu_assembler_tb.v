
`timescale 1ns/1ps

module cpu_assembler_tb;

    reg clk;
    reg reset;

    wire [31:0] pc_out;
    wire [31:0] instruction_out;
    wire instruction_valid;
    wire cpu_valid;

    integer cycles;
    integer errors;

    // -----------------------------------------
    // CPU instance
    // -----------------------------------------

    cpu #(
        .IMEM_ADDR_WIDTH(10),
        .IMEM_INIT_FILE("software/assembler/program.hex")
    ) dut (
        .clk(clk),
        .reset(reset),
        .pc_out(pc_out),
        .instruction_out(instruction_out),
        .instruction_valid(instruction_valid),
        .cpu_valid(cpu_valid)
    );

    always #5 clk = ~clk;

    // -----------------------------------------
    // Test sequence
    // -----------------------------------------

    
    initial begin
        $dumpfile("cpu_function.vcd");
        $dumpvars(0, cpu_function_tb);

        cycles = 0;

        repeat (3) @(negedge clk);
        reset = 0;

        // Wait until outer() returns to main().
        // Main's done label is at address 0x10.
        while (!(
            pc_out == 32'h00000010 &&
            dut.registers.registers[10] == 32'd12
        ) && cycles < 300) begin
            @(negedge clk);
            cycles = cycles + 1;
        end

        $display("\n========================================");
        $display("       STACK FRAME CPU TEST");
        $display("========================================");

        $display("PC       = %08h", pc_out);
        $display("a0       = %08h", dut.registers.registers[10]);
        $display("s0       = %08h", dut.registers.registers[8]);
        $display("sp       = %08h", dut.registers.registers[2]);
        $display("ra       = %08h", dut.registers.registers[1]);
        $display("Cycles   = %0d", cycles);

        if (cycles >= 300) begin
            $display("FAIL: CPU timeout");
            $fatal;
        end

        if (dut.registers.registers[10] != 32'd12) begin
            $display("FAIL: Incorrect return value");
            $fatal;
        end

        if (dut.registers.registers[8] != 32'd77) begin
            $display("FAIL: s0 was not preserved");
            $fatal;
        end

        if (dut.registers.registers[2] != 32'h00004000) begin
            $display("FAIL: Stack pointer was not restored");
            $fatal;
        end

        if (dut.registers.registers[1] != 32'h00000010) begin
            $display("FAIL: Return address was not restored");
            $fatal;
        end

        $display("\nSTACK FRAME TEST PASSED!");
        $display("========================================\n");

        $finish;
    end


    // -----------------------------------------
    // Timeout protection
    // -----------------------------------------

    initial begin
        #5000;
        $fatal(1, "Simulation timeout");
    end

endmodule
