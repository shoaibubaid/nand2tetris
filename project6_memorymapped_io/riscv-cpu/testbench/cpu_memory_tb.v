
`timescale 1ns/1ps

module cpu_memory_tb;

    reg clk;
    reg reset;

    wire [31:0] pc_out;
    wire [31:0] instruction_out;
    wire instruction_valid;
    wire cpu_valid;

    integer errors;
    integer wait_cycles;
    reg [31:0] previous_pc;

    cpu #(
        .IMEM_ADDR_WIDTH(10),
        .IMEM_INIT_FILE("testbench/cpu_memory.hex")
    ) dut (
        .clk(clk),
        .reset(reset),
        .pc_out(pc_out),
        .instruction_out(instruction_out),
        .instruction_valid(instruction_valid),
        .cpu_valid(cpu_valid)
    );

    always #5 clk = ~clk;

    // Check that PC remains unchanged during memory wait.
    always @(posedge clk) begin
        if (!reset && dut.cpu_state == 2'b01) begin
            previous_pc = pc_out;

            @(negedge clk);

            if (dut.cpu_state == 2'b01 &&
                pc_out !== previous_pc) begin

                $display("FAIL: PC changed during memory wait");
                errors = errors + 1;
            end
        end
    end

    initial begin

        clk = 0;
        reset = 1;

        errors = 0;
        wait_cycles = 0;
        previous_pc = 0;

        repeat (3) @(negedge clk);
        reset = 0;

        // Wait for the CPU to execute the program.
        // It should reach the infinite loop at address 0x18.
        while (pc_out != 32'h00000018 &&
               wait_cycles < 100) begin

            @(posedge clk);
            wait_cycles = wait_cycles + 1;

        end

        repeat (5) @(posedge clk);
        #1;

        $display("");
        $display("========== CPU MEMORY TEST ==========");

        $display("PC             = %h", pc_out);

        $display("RAM[0]         = %h",
            dut.dmem.main_ram_inst.memory[0]);

        $display("RAM[1]         = %h",
            dut.dmem.main_ram_inst.memory[1]);

        $display("t0             = %h", dut.registers.registers[5]);
        $display("t1             = %h", dut.registers.registers[6]);
        $display("t2             = %h", dut.registers.registers[7]);
        $display("t3             = %h", dut.registers.registers[28]);

        // Verify memory contents.
        if (dut.dmem.main_ram_inst.memory[0] !== 32'd100) begin
            $display("FAIL: RAM[0] should be 100");
            errors = errors + 1;
        end

        if (dut.dmem.main_ram_inst.memory[1] !== 32'd150) begin
            $display("FAIL: RAM[1] should be 150");
            errors = errors + 1;
        end

        // Verify register contents.
        if (dut.registers.registers[5] !== 32'd100) begin
            $display("FAIL: t0 should be 100");
            errors = errors + 1;
        end

        if (dut.registers.registers[6] !== 32'd100) begin
            $display("FAIL: t1 should be 100");
            errors = errors + 1;
        end

        if (dut.registers.registers[7] !== 32'd150) begin
            $display("FAIL: t2 should be 150");
            errors = errors + 1;
        end

        if (dut.registers.registers[28] !== 32'd150) begin
            $display("FAIL: t3 should be 150");
            errors = errors + 1;
        end

        if (pc_out !== 32'h00000018) begin
            $display("FAIL: CPU did not reach the stop loop");
            errors = errors + 1;
        end

        if (errors == 0) begin
            $display("");
            $display("ALL CPU MEMORY TESTS PASSED");
        end
        else begin
            $display("");
            $display("CPU MEMORY TEST FAILED: %0d errors", errors);
            $fatal(1);
        end

        $finish;
    end

    initial begin
        #2000;
        $fatal(1, "Simulation timeout");
    end

endmodule
