
`timescale 1ns/1ps

module cpu_framebuffer_tb;

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
        .IMEM_INIT_FILE("testbench/cpu_framebuffer.hex")
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

        // Program has 7 instructions.
        // The final JAL at 0x18 loops forever.
        while (pc_out != 32'h00000018 && cycles < 200) begin
            @(posedge clk);
            cycles = cycles + 1;
        end

        if (cycles >= 200)
            $fatal(1, "CPU execution timeout");

        // Allow final instruction to complete.
        repeat (5) @(posedge clk);
        #1;

        $display("");
        $display("======= CPU FRAMEBUFFER TEST =======");

        $display("PC       = %h", pc_out);

        $display("");
        $display("REGISTERS:");

        $display("t0 (x5)  = %h", dut.registers.registers[5]);
        $display("t1 (x6)  = %h", dut.registers.registers[6]);
        $display("t2 (x7)  = %h", dut.registers.registers[7]);
        $display("t3 (x28) = %h", dut.registers.registers[28]);

        $display("");
        $display("FRAMEBUFFER:");

        $display("Word 0 = %h",
            dut.dmem.framebuffer_controller.memory[0]);

        $display("Word 1 = %h",
            dut.dmem.framebuffer_controller.memory[1]);

        // -----------------------------------------
        // Register checks
        // -----------------------------------------

        if (dut.registers.registers[5] !== 32'h10000000) begin
            $display("FAIL: t0 framebuffer base address");
            errors = errors + 1;
        end

        if (dut.registers.registers[6] !== 32'h0000005A) begin
            $display("FAIL: t1 pixel value");
            errors = errors + 1;
        end

        if (dut.registers.registers[7] !== 32'h0000005A) begin
            $display("FAIL: LBU framebuffer readback");
            errors = errors + 1;
        end

        if (dut.registers.registers[28] !== 32'h0000005A) begin
            $display("FAIL: LW framebuffer readback");
            errors = errors + 1;
        end

        // -----------------------------------------
        // Framebuffer integrity checks
        // -----------------------------------------

        // SB wrote byte 0 of word 0.
        if (dut.dmem.framebuffer_controller.memory[0][7:0]
            !== 8'h5A) begin

            $display("FAIL: Framebuffer pixel 0");
            errors = errors + 1;
        end

        // SW wrote the entire second word.
        if (dut.dmem.framebuffer_controller.memory[1]
            !== 32'h0000005A) begin

            $display("FAIL: Framebuffer word 1");
            errors = errors + 1;
        end

        // -----------------------------------------
        // Final PC check
        // -----------------------------------------

        if (pc_out !== 32'h00000018) begin
            $display("FAIL: CPU did not reach expected stop position");
            errors = errors + 1;
        end

        // -----------------------------------------
        // Final result
        // -----------------------------------------

        if (errors == 0) begin
            $display("");
            $display("==================================");
            $display(" ALL CPU FRAMEBUFFER TESTS PASSED");
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
