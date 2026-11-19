
`timescale 1ns/1ps

module cpu_memory_full_tb;

    reg clk;
    reg reset;

    wire [31:0] pc_out;
    wire [31:0] instruction_out;
    wire instruction_valid;
    wire cpu_valid;

    integer errors;
    integer cycles;

    reg stall_active;
    reg [31:0] stalled_pc;

    cpu #(
        .IMEM_ADDR_WIDTH(10),
        .IMEM_INIT_FILE("testbench/cpu_memory_full.hex")
    ) dut (
        .clk(clk),
        .reset(reset),
        .pc_out(pc_out),
        .instruction_out(instruction_out),
        .instruction_valid(instruction_valid),
        .cpu_valid(cpu_valid)
    );

    always #5 clk = ~clk;

    // ---------------------------------------------
    // Verify PC remains stable during memory wait
    // ---------------------------------------------

    always @(posedge clk) begin

        if (reset) begin
            stall_active = 0;
        end
        else if (dut.cpu_state == 2'b01) begin

            if (!stall_active) begin
                stalled_pc = pc_out;
                stall_active = 1;
            end
            else if (pc_out !== stalled_pc) begin
                $display("FAIL: PC changed during memory wait");
                errors = errors + 1;
            end

        end
        else begin
            stall_active = 0;
        end

    end

    // ---------------------------------------------
    // Test sequence
    // ---------------------------------------------

    initial begin

        clk = 0;
        reset = 1;

        errors = 0;
        cycles = 0;
        stall_active = 0;
        stalled_pc = 0;

        repeat (3) @(negedge clk);
        reset = 0;

        // Last instruction is at address 0x40.
        // Wait until the CPU reaches it.
        while (pc_out != 32'h00000044 && cycles < 200) begin
            @(posedge clk);
            cycles = cycles + 1;
        end

        if (cycles >= 200)
            $fatal(1, "CPU execution timeout");

        // Allow the final instruction to execute.
        repeat (5) @(posedge clk);
        #1;

        $display("");
        $display("========== CPU MEMORY TEST ==========");

        $display("PC       = %h", pc_out);

        $display("");
        $display("REGISTERS:");

        $display("t0 (x5)  = %h", dut.registers.registers[5]);
        $display("t1 (x6)  = %h", dut.registers.registers[6]);
        $display("t2 (x7)  = %h", dut.registers.registers[7]);
        $display("t3 (x28) = %h", dut.registers.registers[28]);
        $display("t4 (x29) = %h", dut.registers.registers[29]);
        $display("t5 (x30) = %h", dut.registers.registers[30]);
        $display("t6 (x31) = %h", dut.registers.registers[31]);

        $display("");
        $display("MEMORY:");

        $display("RAM[0] = %h",
            dut.dmem.main_ram_inst.memory[0]);

        $display("RAM[1] = %h",
            dut.dmem.main_ram_inst.memory[1]);

        // -----------------------------------------
        // Register checks
        // -----------------------------------------

        if (dut.registers.registers[5] !== 32'hFFFFFF80) begin
            $display("FAIL: t0");
            errors = errors + 1;
        end

        if (dut.registers.registers[6] !== 32'hFFFFFF80) begin
            $display("FAIL: LB sign extension");
            errors = errors + 1;
        end

        if (dut.registers.registers[7] !== 32'h00000080) begin
            $display("FAIL: LBU zero extension");
            errors = errors + 1;
        end

        if (dut.registers.registers[28] !== 32'hFFFFFF80) begin
            $display("FAIL: LH sign extension");
            errors = errors + 1;
        end

        if (dut.registers.registers[29] !== 32'h01232323) begin
            $display("FAIL: LW from address 0");
            errors = errors + 1;
        end

        if (dut.registers.registers[30] !== 32'h0000FF80) begin
            $display("FAIL: LHU zero extension");
            errors = errors + 1;
        end

        if (dut.registers.registers[31] !== 32'hFF800080) begin
            $display("FAIL: LW from address 4");
            errors = errors + 1;
        end

        // -----------------------------------------
        // Memory integrity checks
        // -----------------------------------------

        if (dut.dmem.main_ram_inst.memory[0] !==
            32'h01232323) begin

            $display("FAIL: RAM word 0 corrupted");
            errors = errors + 1;
        end

        if (dut.dmem.main_ram_inst.memory[1] !==
            32'hFF800080) begin

            $display("FAIL: RAM word 1 corrupted");
            errors = errors + 1;
        end

        // -----------------------------------------
        // Final PC check
        // -----------------------------------------

        if (pc_out !== 32'h00000044) begin
            $display("FAIL: CPU did not reach stop loop");
            errors = errors + 1;
        end

        // -----------------------------------------
        // Final result
        // -----------------------------------------

        if (errors == 0) begin
            $display("");
            $display("==================================");
            $display(" ALL CPU MEMORY TESTS PASSED");
            $display("==================================");
        end
        else begin
            $display("");
            $display("TEST FAILED: %0d errors", errors);
            $fatal(1);
        end

        $finish;

    end

    initial begin
        #5000;
        $fatal(1, "Simulation timeout");
    end

endmodule
