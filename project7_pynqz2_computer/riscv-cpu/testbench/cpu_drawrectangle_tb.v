
`timescale 1ns/1ps

module cpu_drawrectangle_tb;

    // =================================
    // Clock and reset
    // =================================

    reg clk = 0;
    reg reset = 1;

    always #5 clk = ~clk;

    // =================================
    // CPU signals
    // =================================

    wire [31:0] pc_out;
    wire [31:0] instruction_out;

    wire instruction_valid;
    wire cpu_valid;

    reg ps_event_valid = 0;
    wire ps_event_ready;
    reg [8:0] ps_event_data = 0;

    wire ps_clk = clk;
    wire ps_reset = reset;

    integer cycles;
    integer timeout;

    reg trace_enable = 0;
    reg [31:0] previous_pc;

    // =================================
    // CPU instance
    // =================================

    cpu #(
        .IMEM_ADDR_WIDTH(10),
        .IMEM_INIT_FILE("software/assembler/program.hex")
    ) dut (
        .clk(clk),
        .reset(reset),

        .pc_out(pc_out),
        .instruction_out(instruction_out),
        .instruction_valid(instruction_valid),
        .cpu_valid(cpu_valid),

        .ps_clk(ps_clk),
        .ps_reset(ps_reset),
        .ps_event_valid(ps_event_valid),
        .ps_event_ready(ps_event_ready),
        .ps_event_data(ps_event_data)
    );

    // =================================
    // Framebuffer PPM exporter
    // =================================

    task dump_framebuffer;

        integer fd;
        integer x, y;
        integer pixel_offset;
        integer word_index;
        integer byte_lane;

        reg [31:0] word_data;
        reg [7:0] pixel;

        reg [7:0] red;
        reg [7:0] green;
        reg [7:0] blue;

        begin
            fd = $fopen("framebuffer.ppm", "wb");

            if (fd == 0) begin
                $display("ERROR: Cannot open framebuffer.ppm");
            end
            else begin
                $fwrite(fd, "P6\n320 240\n255\n");

                for (y = 0; y < 240; y = y + 1) begin
                    for (x = 0; x < 320; x = x + 1) begin

                        pixel_offset = y * 320 + x;
                        word_index = pixel_offset / 4;
                        byte_lane = pixel_offset % 4;

                        word_data =
                            dut.dmem.framebuffer_controller.memory[word_index];

                        pixel = word_data[byte_lane * 8 +: 8];

                        red = {
                            pixel[7:5],
                            pixel[7:5],
                            pixel[7:6]
                        };

                        green = {
                            pixel[4:2],
                            pixel[4:2],
                            pixel[4:3]
                        };

                        blue = {
                            pixel[1:0],
                            pixel[1:0],
                            pixel[1:0],
                            pixel[1:0]
                        };

                        $fwrite(fd, "%c%c%c", red, green, blue);
                    end
                end

                $fclose(fd);
                $display("Framebuffer exported!");
            end
        end

    endtask

    // =================================
    // Reset sequence
    // =================================

    initial begin
        repeat (3) @(negedge clk);

        reset = 0;

        $display("CPU reset released!");
    end

    // =================================
    // CPU instruction monitor
    // =================================

    // initial begin
    //     previous_pc = 32'hFFFFFFFF;

    //     forever begin
    //         @(negedge clk);

    //         if (!reset && trace_enable) begin
    //             if (pc_out != previous_pc) begin

    //                 $display(
    //                     "PC=%08h INST=%08h STATE=%0d X=%0d Y=%0d",
    //                     pc_out,
    //                     instruction_out,
    //                     dut.cpu_state,
    //                     dut.registers.registers[8],
    //                     dut.registers.registers[9]
    //                 );

    //                 previous_pc = pc_out;
    //             end
    //         end
    //     end
    // end

    initial begin
        previous_pc = 32'hFFFFFFFF;
    end

    always @(posedge clk) begin
        if (!reset && dut.pc !== previous_pc) begin
            $display("PC CHANGE: %08h -> %08h",
                    previous_pc, dut.pc);
            previous_pc <= dut.pc;
        end
    end

    // =================================
    // Keyboard movement test
    // =================================

    initial begin

        timeout = 0;

        // Wait for reset release
        wait (reset === 1'b0);

        // Wait for initial square drawing
        repeat (10000) @(negedge clk);

        $display("\n================================");
        $display("KEYBOARD MOVEMENT TEST");
        $display("================================");

        $display("Before W press:");
        $display("PC = %08h", pc_out);
        $display("X = %0d", dut.registers.registers[8]);
        $display("Y = %0d", dut.registers.registers[9]);

        // Verify initial position
        if (dut.registers.registers[8] != 32'd50 ||
            dut.registers.registers[9] != 32'd50) begin

            $display("FAIL: Initial square position incorrect");
            $fatal;
        end
    

        // Enable CPU trace
        trace_enable = 1;

        // Inject W press
        @(negedge ps_clk);

        ps_event_data = 9'h11A;
        ps_event_valid = 1'b1;

        $display("Sending W event: %03h", ps_event_data);

        // Wait for source-side bridge handshake
        do begin
            @(posedge ps_clk);
        end while (ps_event_ready !== 1'b1);

        @(negedge ps_clk);

        ps_event_valid = 1'b0;
        ps_event_data = 9'b0;

        $display("PS-side bridge accepted W event!");

        // Allow CDC transfer time
        repeat (10) @(negedge clk);

        // FIFO diagnostics
        $display("FIFO count = %0d",
            dut.dmem.keyboard_controller.fifo_count);

        $display("FIFO empty = %b",
            dut.dmem.keyboard_controller.fifo_empty);

        // Wait for CPU to process W
        while (
            dut.registers.registers[9] != 32'd49 &&
            timeout < 100000
        ) begin
            @(negedge clk);
            timeout = timeout + 1;
        end

        trace_enable = 0;

        $display("\n================================");
        $display("KEYBOARD TEST RESULT");
        $display("================================");

        $display("PC = %08h", pc_out);
        $display("X = %0d", dut.registers.registers[8]);
        $display("Y = %0d", dut.registers.registers[9]);
        $display("Cycles waited = %0d", timeout);

        $display("FIFO count = %0d",
            dut.dmem.keyboard_controller.fifo_count);

        if (timeout >= 100000) begin
            $display("FAIL: CPU did not process W event");
            $fatal;
        end

        if (dut.registers.registers[8] != 32'd50 ||
            dut.registers.registers[9] != 32'd49) begin

            $display("FAIL: Incorrect square coordinates");
            $fatal;
        end

        $display("\nKEYBOARD MOVEMENT TEST PASSED!");

        dump_framebuffer();

        $finish;
    end

    // Trace the JALR instruction at PC = 0xC8
    always @(posedge clk) begin
        if (!reset && dut.pc == 32'h000000C8) begin
            $display(
                "JALR TRACE: PC=%08h INST=%08h rs1=%0d rs1_data=%08h immediate=%08h Jalr=%b next_pc=%08h state=%b",
                dut.pc,
                dut.instruction,
                dut.rs1,
                dut.rs1_data,
                dut.immediate,
                dut.Jalr,
                dut.next_pc,
                dut.cpu_state
            );
        end
    end


    

endmodule
