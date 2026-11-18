
`timescale 1ns/1ps

module cpu_function_tb;

    reg clk = 0;
    reg reset = 1;

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

    always #5 clk = ~clk;

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

    
// initial begin
//     $dumpfile("cpu_function.vcd");
//     $dumpvars(0, cpu_function_tb);

//     cycles = 0;

//     repeat (3) @(negedge clk);
//     reset = 0;

//     // Wait until outer() returns to main().
//     // Main's done label is at address 0x10.
//     while (!(
//         pc_out == 32'h00000010 &&
//         dut.registers.registers[10] == 32'd12
//     ) && cycles < 300) begin
//         @(negedge clk);
//         cycles = cycles + 1;
//     end

//     $display("\n========================================");
//     $display("       STACK FRAME CPU TEST");
//     $display("========================================");

//     $display("PC       = %08h", pc_out);
//     $display("a0       = %08h", dut.registers.registers[10]);
//     $display("s0       = %08h", dut.registers.registers[8]);
//     $display("sp       = %08h", dut.registers.registers[2]);
//     $display("ra       = %08h", dut.registers.registers[1]);
//     $display("Cycles   = %0d", cycles);

//     if (cycles >= 300) begin
//         $display("FAIL: CPU timeout");
//         $fatal;
//     end

//     if (dut.registers.registers[10] != 32'd12) begin
//         $display("FAIL: Incorrect return value");
//         $fatal;
//     end

//     if (dut.registers.registers[8] != 32'd77) begin
//         $display("FAIL: s0 was not preserved");
//         $fatal;
//     end

//     if (dut.registers.registers[2] != 32'h00004000) begin
//         $display("FAIL: Stack pointer was not restored");
//         $fatal;
//     end

//     if (dut.registers.registers[1] != 32'h00000010) begin
//         $display("FAIL: Return address was not restored");
//         $fatal;
//     end

//     $display("\nSTACK FRAME TEST PASSED!");
//     $display("========================================\n");

//     $finish;
// end


    // initial begin
    //     $dumpfile("cpu_function.vcd");
    //     $dumpvars(0, cpu_function_tb);

    //     cycles = 0;

    //     repeat (3) @(negedge clk);
    //     reset = 0;

    //     // Wait until sum_three() returns.
    //     // done label is at address 0x10.
    //     while (!(
    //         pc_out == 32'h00000014 &&
    //         dut.registers.registers[10] == 32'd31
    //     ) && cycles < 200) begin
    //         @(negedge clk);
    //         cycles = cycles + 1;
    //     end

    //     $display("\n========================================");
    //     $display("     MULTIPLE ARGUMENTS CPU TEST");
    //     $display("========================================");

    //     $display("PC  = %08h", pc_out);
    //     $display("a0  = %08h", dut.registers.registers[10]);
    //     $display("a1  = %08h", dut.registers.registers[11]);
    //     $display("a2  = %08h", dut.registers.registers[12]);
    //     $display("sp  = %08h", dut.registers.registers[2]);
    //     $display("ra  = %08h", dut.registers.registers[1]);
    //     $display("Cycles = %0d", cycles);

    //     if (cycles >= 200) begin
    //         $display("FAIL: CPU timeout");
    //         $fatal;
    //     end

    //     if (dut.registers.registers[10] != 32'd31) begin
    //         $display("FAIL: Incorrect return value");
    //         $fatal;
    //     end

    //     if (dut.registers.registers[11] != 32'd11 ||
    //         dut.registers.registers[12] != 32'd13) begin
    //         $display("FAIL: Arguments were unexpectedly modified");
    //         $fatal;
    //     end

    //     $display("\nMULTIPLE ARGUMENTS TEST PASSED!");
    //     $display("========================================\n");

    //     $finish;
    // end


    // initial begin
    //     $dumpfile("draw_pixel.vcd");
    //     $dumpvars(0, cpu_function_tb);

    //     cycles = 0;

    //     repeat (3) @(negedge clk);
    //     reset = 0;

    //     // Wait until draw_pixel returns.
    //     while (!(
    //         pc_out == 32'h00000014 &&
    //         dut.dmem.framebuffer_controller.memory[1602][23:16] == 8'h5A
    //     ) && cycles < 300) begin
    //         @(negedge clk);
    //         cycles = cycles + 1;
    //     end

    //     $display("\n========================================");
    //     $display("         DRAW PIXEL CPU TEST");
    //     $display("========================================");

    //     $display("PC          = %08h", pc_out);
    //     $display("a0 (x)      = %08h", dut.registers.registers[10]);
    //     $display("a1 (y)      = %08h", dut.registers.registers[11]);
    //     $display("a2 (color)  = %08h", dut.registers.registers[12]);
    //     $display("Framebuffer word 1602 = %08h",
    //         dut.dmem.framebuffer_controller.memory[1602]);

    //     $display("Cycles = %0d", cycles);

    //     if (cycles >= 300) begin
    //         $display("FAIL: CPU timeout");
    //         $fatal;
    //     end

    //     if (dut.dmem.framebuffer_controller.memory[1602][23:16] != 8'h5A) begin
    //         $display("FAIL: Pixel was not written correctly");
    //         $fatal;
    //     end

    //     $display("\nDRAW PIXEL TEST PASSED!");
    //     $display("========================================\n");

    //     $finish;
    // end



    // integer x, y;
    // integer pixel_offset;
    // integer word_index;
    // integer byte_lane;
    // integer errors;

    // initial begin
    //     $dumpfile("draw_rectangle.vcd");
    //     $dumpvars(0, cpu_function_tb);

    //     cycles = 0;
    //     errors = 0;

    //     // Apply reset
    //     repeat (3) @(negedge clk);
    //     reset = 0;

    //     // Wait until draw_rectangle returns.
    //     // done label is at address 0x18.
    //     while (!(
    //         pc_out == 32'h0000001C &&
    //         dut.registers.registers[2] == 32'h00004000
    //     ) && cycles < 3000) begin
    //         @(negedge clk);
    //         cycles = cycles + 1;
    //     end

    //     $display("\n========================================");
    //     $display("       DRAW RECTANGLE CPU TEST");
    //     $display("========================================");

    //     $display("PC      = %08h", pc_out);
    //     $display("a0      = %08h", dut.registers.registers[10]);
    //     $display("a1      = %08h", dut.registers.registers[11]);
    //     $display("a2      = %08h", dut.registers.registers[12]);
    //     $display("a3      = %08h", dut.registers.registers[13]);
    //     $display("a4      = %08h", dut.registers.registers[14]);
    //     $display("sp      = %08h", dut.registers.registers[2]);
    //     $display("ra      = %08h", dut.registers.registers[1]);
    //     $display("Cycles  = %0d", cycles);

    //     // Check timeout
    //     if (cycles >= 3000) begin
    //         $display("FAIL: CPU timeout");
    //         $fatal;
    //     end

    //     // Verify all 15 pixels
    //     for (y = 20; y < 23; y = y + 1) begin
    //         for (x = 10; x < 15; x = x + 1) begin

    //             pixel_offset = y * 320 + x;
    //             word_index = pixel_offset / 4;
    //             byte_lane = pixel_offset % 4;

    //             if (dut.dmem.framebuffer_controller.memory[word_index]
    //                 [byte_lane*8 +: 8] !== 8'h5A) begin

    //                 $display(
    //                     "FAIL: Pixel (%0d,%0d), expected 0x5A, got 0x%02h",
    //                     x, y,
    //                     dut.dmem.framebuffer_controller.memory[word_index]
    //                     [byte_lane*8 +: 8]
    //                 );

    //                 errors = errors + 1;
    //             end
    //         end
    //     end

    //     // Final verification
    //     if (dut.registers.registers[2] != 32'h00004000) begin
    //         $display("FAIL: Stack pointer was not restored");
    //         $fatal;
    //     end

    //     if (errors != 0) begin
    //         $display("FAILED: %0d pixels incorrect", errors);
    //         $fatal;
    //     end

    //     $display("\nALL 15 PIXELS VERIFIED!");
    //     $display("DRAW RECTANGLE TEST PASSED!");
    //     $display("========================================\n");

    //     $finish;
    // end


    // integer i;
    // integer x, y;
    // integer pixel_offset;
    // integer word_index;
    // integer byte_lane;
    // integer errors;


    // initial begin
    //     $dumpfile("clear_screen.vcd");
    //     $dumpvars(0, cpu_function_tb);

    //     cycles = 0;
    //     errors = 0;

    //     repeat (3) @(negedge clk);
    //     reset = 0;

    //     // Wait for clear_screen() to return.
    //     // done label = 0x08.
    //     while (!(
    //         pc_out == 32'h00000008 &&
    //         dut.registers.registers[2] == 32'h00004000
    //     ) && cycles < 200000) begin
    //         @(negedge clk);
    //         cycles = cycles + 1;
    //     end

    //     $display("\n========================================");
    //     $display("         CLEAR SCREEN CPU TEST");
    //     $display("========================================");

    //     $display("PC     = %08h", pc_out);
    //     $display("SP     = %08h", dut.registers.registers[2]);
    //     $display("Cycles = %0d", cycles);

    //     if (cycles >= 200000) begin
    //         $display("FAIL: CPU timeout");
    //         $fatal;
    //     end

    //     // Verify all 19,200 framebuffer words.
    //     for (i = 0; i < 19200; i = i + 1) begin
    //         if (dut.dmem.framebuffer_controller.memory[i]
    //             !== 32'h00000000) begin

    //             $display(
    //                 "FAIL: Framebuffer word %0d = %08h",
    //                 i,
    //                 dut.dmem.framebuffer_controller.memory[i]
    //             );

    //             errors = errors + 1;
    //         end
    //     end

    //     if (errors != 0) begin
    //         $display("FAILED: %0d framebuffer words incorrect", errors);
    //         $fatal;
    //     end

    //     $display("ALL 19200 FRAMEBUFFER WORDS VERIFIED!");
    //     $display("CLEAR SCREEN TEST PASSED!");
    //     $display("========================================\n");

    //     $finish;
    // end



    // initial begin
    //     $dumpfile("keyboard_demo.vcd");
    //     $dumpvars(0, cpu_function_tb);

    //     cycles = 0;

    //     repeat (3) @(negedge clk);
    //     reset = 0;

    //     // Wait for keyboard_available() to return.
    //     // PC = 0x08 is the done loop.
    //     while (!(
    //         pc_out == 32'h00000008 &&
    //         dut.registers.registers[10] == 32'd0
    //     ) && cycles < 300) begin
    //         @(negedge clk);
    //         cycles = cycles + 1;
    //     end

    //     $display("\n========================================");
    //     $display("       KEYBOARD EMPTY FIFO TEST");
    //     $display("========================================");

    //     $display("PC      = %08h", pc_out);
    //     $display("a0      = %08h", dut.registers.registers[10]);
    //     $display("sp      = %08h", dut.registers.registers[2]);
    //     $display("Cycles  = %0d", cycles);

    //     if (cycles >= 300) begin
    //         $display("FAIL: CPU timeout");
    //         $fatal;
    //     end

    //     if (dut.registers.registers[10] != 32'd0) begin
    //         $display("FAIL: Expected empty FIFO");
    //         $fatal;
    //     end

    //     if (dut.registers.registers[2] != 32'h00004000) begin
    //         $display("FAIL: Stack pointer incorrect");
    //         $fatal;
    //     end

    //     $display("\nKEYBOARD EMPTY FIFO TEST PASSED!");
    //     $display("========================================\n");

    //     $finish;
    // end


    always @(negedge clk) begin
        if (!reset && cycles < 100) begin
            $display(
                "PC=%08h INST=%08h STATE=%0d a0=%08h",
                pc_out,
                instruction_out,
                dut.cpu_state,
                dut.registers.registers[10]
            );
        end
    end



    

    

    // initial begin
    //     $dumpfile("read_key.vcd");
    //     $dumpvars(0, cpu_function_tb);

    //     cycles = 0;

    //     // -------------------------------
    //     // RESET
    //     // -------------------------------
    //     repeat (3) @(negedge ps_clk);
    //     reset = 0;

    //     // -------------------------------
    //     // INJECT W KEY PRESS
    //     // Event = 9'h11A
    //     // -------------------------------
    //     @(negedge ps_clk);
    //     ps_event_data  = 9'h11A;
    //     ps_event_valid = 1'b1;

    //     // Wait for valid/ready handshake
    //     while (ps_event_ready !== 1'b1) begin
    //         @(negedge ps_clk);
    //     end

    //     // Deassert valid after acceptance
    //     @(negedge ps_clk);
    //     ps_event_valid = 1'b0;
    //     ps_event_data  = 9'b0;

    //     // -------------------------------
    //     // WAIT FOR CPU TO READ EVENT
    //     // done label = 0x10
    //     // Expected a0 = 0x11A
    //     // -------------------------------
    //     while (!(
    //         pc_out == 32'h00000010 &&
    //         dut.registers.registers[10] == 32'h0000011A
    //     ) && cycles < 2000) begin

    //         @(negedge clk);
    //         cycles = cycles + 1;

    //     end

    //     // -------------------------------
    //     // DISPLAY RESULTS
    //     // -------------------------------
    //     $display("\n========================================");
    //     $display("       KEYBOARD EVENT CPU TEST");
    //     $display("========================================");

    //     $display("PC      = %08h", pc_out);
    //     $display("a0      = %08h", dut.registers.registers[10]);
    //     $display("sp      = %08h", dut.registers.registers[2]);
    //     $display("Cycles  = %0d", cycles);

    //     // -------------------------------
    //     // VALIDATE RESULTS
    //     // -------------------------------
    //     if (cycles >= 2000) begin
    //         $display("FAIL: CPU timeout");
    //         $fatal;
    //     end

    //     if (dut.registers.registers[10] !== 32'h0000011A) begin
    //         $display("FAIL: Incorrect keyboard event");
    //         $fatal;
    //     end

    //     $display("\nKEYBOARD EVENT TEST PASSED!");
    //     $display("W KEY PRESS DETECTED!");
    //     $display("========================================");

    //     $finish;

    // end




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
                $display("ERROR: Could not open framebuffer.ppm");
            end
            else begin
                // PPM binary image header
                $fwrite(fd, "P6\n320 240\n255\n");

                for (y = 0; y < 240; y = y + 1) begin
                    for (x = 0; x < 320; x = x + 1) begin

                        pixel_offset = y * 320 + x;
                        word_index = pixel_offset / 4;
                        byte_lane = pixel_offset % 4;

                        word_data =
                            dut.dmem.framebuffer_controller.memory[word_index];

                        pixel = word_data[byte_lane * 8 +: 8];

                        // RGB332 to RGB888
                        red   = {pixel[7:5], pixel[7:5], pixel[7:6]};
                        green = {pixel[4:2], pixel[4:2], pixel[4:3]};
                        blue  = {pixel[1:0], pixel[1:0],
                                pixel[1:0], pixel[1:0]};

                        $fwrite(fd, "%c%c%c", red, green, blue);
                    end
                end

                $fclose(fd);

                $display("Framebuffer exported: framebuffer.ppm");
            end
        end
    endtask

    initial begin
        $dumpfile("timer_demo.vcd");
        $dumpvars(0, cpu_function_tb);

        cycles = 0;

        // Apply reset
        repeat (3) @(negedge clk);
        reset = 0;

        // Wait until the CPU reaches the done loop.
        // PC = 0x2C means the timer value has changed.
        while (pc_out != 32'h0000002C && cycles < 2000) begin
            @(negedge clk);
            cycles = cycles + 1;
        end

        $display("\n========================================");
        $display("         CPU TIMER TEST");
        $display("========================================");

        $display("PC              = %08h", pc_out);
        $display("Initial time    = %08h",
                dut.registers.registers[8]);   // s0
        $display("Current time    = %08h",
                dut.registers.registers[10]);  // a0
        $display("Cycles          = %0d", cycles);

        if (cycles >= 2000) begin
            $display("FAIL: CPU timeout waiting for timer");
            $fatal;
        end

        if (pc_out != 32'h0000002C) begin
            $display("FAIL: CPU did not reach done loop");
            $fatal;
        end

        if (dut.registers.registers[10] <=
            dut.registers.registers[8]) begin
            $display("FAIL: Timer did not advance");
            $fatal;
        end


        $display("\nTIMER TEST PASSED!");
        $display("========================================");

        dump_framebuffer();

        $finish;
    end



endmodule
