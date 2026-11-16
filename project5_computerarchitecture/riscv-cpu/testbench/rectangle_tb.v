
module rectangle_tb;

    reg clk;
    reg reset;

    wire [31:0] pc;
    wire [31:0] instruction;
    wire instruction_valid;
    wire cpu_valid;

    integer i;
    integer errors;

    // =====================================================
    // TOP-LEVEL PROCESSOR
    // =====================================================

    top #(
        .IMEM_ADDR_WIDTH(10),
        .IMEM_INIT_FILE("machine_code/rectangle.hex"),
        .DMEM_BYTES(4096)
    ) dut (
        .clk(clk),
        .reset(reset),
        .pc(pc),
        .instruction(instruction),
        .instruction_valid(instruction_valid),
        .cpu_valid(cpu_valid)
    );


    // =====================================================
    // CLOCK GENERATION
    // =====================================================

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end


    // =====================================================
    // INSTRUCTION TRACE
    // =====================================================

    always @(posedge clk) begin
        if (!reset) begin
            $display(
                "PC=%08h INST=%08h IMEM_VALID=%b CPU_VALID=%b",
                pc,
                instruction,
                instruction_valid,
                cpu_valid
            );
        end
    end


    // =====================================================
    // MAIN TEST
    // =====================================================

    initial begin

        errors = 0;

        // -------------------------------------------------
        // RESET
        // -------------------------------------------------

        reset = 1;

        repeat (2) @(posedge clk);

        #1 reset = 0;

        // -------------------------------------------------
        // EXECUTE PROGRAM
        // -------------------------------------------------

        repeat (60) @(posedge clk);

        #1;

        // -------------------------------------------------
        // REGISTER FILE
        // -------------------------------------------------

        $display("\n================================");
        $display("       REGISTER FILE");
        $display("================================");

        for (i = 0; i < 32; i = i + 1) begin

            $display(
                "x%0d = 0x%08h (%0d)",
                i,
                dut.processor.registers.registers[i],
                dut.processor.registers.registers[i]
            );

        end


        // -------------------------------------------------
        // EXPECTED REGISTER VALUES
        // -------------------------------------------------

        $display("\n================================");
        $display("      REGISTER VERIFICATION");
        $display("================================");

        if (dut.processor.registers.registers[5] !== 32'd10) begin
            $display("ERROR: x5 expected 10");
            errors = errors + 1;
        end

        if (dut.processor.registers.registers[6] !== 32'd10) begin
            $display("ERROR: x6 expected 10");
            errors = errors + 1;
        end

        if (dut.processor.registers.registers[7] !== 32'd640) begin
            $display("ERROR: x7 expected 640");
            errors = errors + 1;
        end


        // -------------------------------------------------
        // FRAMEBUFFER
        // -------------------------------------------------

        $display("\n================================");
        $display("          FRAMEBUFFER");
        $display("================================");

        for (i = 0; i < 10; i = i + 1) begin

            $display(
                "Row %0d: %02h%02h",
                i,
                dut.processor.dmem.memory[i*64+1],
                dut.processor.dmem.memory[i*64]
            );

        end


        // -------------------------------------------------
        // VERIFY FRAMEBUFFER
        // -------------------------------------------------

        $display("\n================================");
        $display("     FRAMEBUFFER VERIFICATION");
        $display("================================");

        for (i = 0; i < 10; i = i + 1) begin

            if (
                dut.processor.dmem.memory[i*64] !== 8'hFF ||
                dut.processor.dmem.memory[i*64+1] !== 8'hFF
            ) begin

                $display(
                    "ERROR: Row %0d was not written correctly",
                    i
                );

                errors = errors + 1;

            end
            else begin

                $display("Row %0d: PASS", i);

            end

        end


        // -------------------------------------------------
        // FINAL RESULT
        // -------------------------------------------------

        $display("\n================================");

        if (errors == 0) begin

            $display("SUCCESS: RECTANGLE GENERATED!");
            $display("All register and framebuffer checks passed.");

        end
        else begin

            $display("FAILURE: %0d errors detected.", errors);

        end

        $display("================================\n");

        $finish;

    end

endmodule
