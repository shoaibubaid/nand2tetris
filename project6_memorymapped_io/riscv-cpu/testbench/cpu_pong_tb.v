`timescale 1ns/1ps

module cpu_pong_tb;

    reg clk = 1'b0;
    reg reset = 1'b1;
    always #5 clk = ~clk;

    // PS-side keyboard event interface.
    reg        ps_event_valid = 1'b0;
    wire       ps_event_ready;
    reg [8:0]  ps_event_data = 9'b0;

    // Video read interface. The testbench does not need to generate HDMI;
    // it reads the same framebuffer through the CPU's hierarchy.
    reg  [16:0] video_pixel_address = 17'b0;
    wire [7:0]  video_pixel_data;

    wire [31:0] pc_out;
    wire [31:0] instruction_out;
    wire instruction_valid;
    wire cpu_valid;

    integer timeout;
    integer initial_left_y;
    integer initial_right_y;

    cpu #(
        .IMEM_ADDR_WIDTH(10),
        .IMEM_INIT_FILE("software/assembler/pong.hex")
    ) dut (
        .clk(clk),
        .reset(reset),
        .ps_clk(clk),
        .ps_reset(reset),
        .ps_event_valid(ps_event_valid),
        .ps_event_ready(ps_event_ready),
        .ps_event_data(ps_event_data),
        .video_pixel_address(video_pixel_address),
        .video_pixel_data(video_pixel_data),
        .pc_out(pc_out),
        .instruction_out(instruction_out),
        .instruction_valid(instruction_valid),
        .cpu_valid(cpu_valid)
    );

    // Framebuffer stores four RGB332 pixels in each 32-bit word.
    function [7:0] read_pixel;
        input integer x;
        input integer y;
        integer offset;
        integer word_index;
        integer byte_lane;
        reg [31:0] word_data;
        begin
            offset = y * 320 + x;
            word_index = offset / 4;
            byte_lane = offset % 4;
            word_data = dut.dmem.framebuffer_controller.memory[word_index];
            read_pixel = word_data[byte_lane * 8 +: 8];
        end
    endfunction

    task expect_white_pixel;
        input integer x;
        input integer y;
        input [255:0] description;
        begin
            if (read_pixel(x, y) !== 8'hff) begin
                $display("FAIL: %0s at (%0d,%0d), got %02h",
                         description, x, y, read_pixel(x,y));
                $fatal(1);
            end
            $display("PASS: %0s", description);
        end
    endtask

    // Send one pressed HID event through the same PS-to-CPU bridge used by
    // the board design. Event format is {pressed, HID usage}.
    // Send one pressed HID event through the PS-to-CPU bridge.
    task send_key;
        input [8:0] event_data;
        integer wait_cycles;
        begin
            @(negedge clk);
            ps_event_data  = event_data;
            ps_event_valid = 1'b1;

            wait_cycles = 0;
            while (ps_event_ready !== 1'b1 && wait_cycles < 1000) begin
                @(negedge clk);
                wait_cycles = wait_cycles + 1;
            end

            if (wait_cycles >= 1000) begin
                $display("FAIL: PS bridge did not become ready");
                $fatal(1);
            end

            // The event is accepted on the next active clock edge.
            @(posedge clk);
            @(negedge clk);
            ps_event_valid = 1'b0;
            ps_event_data  = 9'b0;

            repeat (15) @(negedge clk);
        end
    endtask

    initial begin
        $display("\n========================================");
        $display("PONG INTEGRATION TEST");
        $display("========================================\n");

        // Release reset with the timer effectively paused. This lets the
        // program finish drawing the initial scene before we accelerate time.
        repeat (5) @(negedge clk);
        reset = 1'b0;
        @(negedge clk);
        dut.dmem.timer_prescaler = 32'hffffffff;

        // Wait for the initial game state and graphics to be drawn.
        timeout = 0;
        while ((dut.registers.registers[23] !== 32'd157 ||
                dut.registers.registers[24] !== 32'd117) && timeout < 20000) begin
            @(negedge clk);
            timeout = timeout + 1;
        end
        if (timeout >= 20000) begin
            $display("FAIL: Pong initialization did not reach ball setup");
            $fatal(1);
        end

        // Wait until the first ball has been written to framebuffer.
        timeout = 0;
        while (read_pixel(159,119) !== 8'hff && timeout < 50000) begin
            @(negedge clk);
            timeout = timeout + 1;
        end
        if (timeout >= 30000) begin
            $display("FAIL: Initial ball was not rendered");
            $fatal(1);
        end

        expect_white_pixel(12, 110, "Left paddle rendered");
        expect_white_pixel(306, 110, "Right paddle rendered");
        $display("PASS: Initial ball rendered at (157,117)");

        // Accelerated simulation clock: 10 CPU clocks per timer tick.
        // Production default in memory_subsystem_pong.v remains 99,999.
        dut.dmem.timer_prescaler = 32'd9;
        dut.dmem.timer_prescaler_count = 32'd0;

        // ------------------------------------------------------------
        // 1. Timer-driven ball movement
        // ------------------------------------------------------------
        $display("\nTEST 1: TIMER-DRIVEN BALL MOVEMENT");
        timeout = 0;

        // Wait until both coordinates have updated.
        while ((dut.registers.registers[23] !== 32'd158 ||
                dut.registers.registers[24] !== 32'd118) &&
               timeout < 500000) begin
            @(negedge clk);
            timeout = timeout + 1;
        end

        if (timeout >= 10000) begin
            $display("FAIL: Ball did not reach (158,118)");
            $display("Actual ball=(%0d,%0d)",
                     dut.registers.registers[23],
                     dut.registers.registers[24]);
            $fatal(1);
        end

        $display("PASS: Ball moved to (158,118)");

        // ------------------------------------------------------------
        // 2. Bottom wall bounce
        // ------------------------------------------------------------
        $display("\nTEST 2: BOTTOM WALL BOUNCE");
        timeout = 0;
        while (dut.registers.registers[26] !== 32'hffffffff && timeout < 500000) begin
            @(negedge clk);
            timeout = timeout + 1;
        end
        if (dut.registers.registers[26] !== 32'hffffffff) begin
            $display("FAIL: Ball never reversed vertical direction at bottom wall");
            $fatal(1);
        end
        if (dut.registers.registers[24] > 32'd234 ||
            dut.registers.registers[24] < 32'd232) begin
            $display("FAIL: Bottom bounce occurred at unexpected Y=%0d",
                     dut.registers.registers[24]);
            $fatal(1);
        end
        $display("PASS: Bottom bounce; ball Y=%0d, vy=%0d",
                 dut.registers.registers[24], $signed(dut.registers.registers[26]));

        // Move the right paddle's logical Y into the ball's return path.
        // This is a controlled collision test: the paddle position register
        // is set directly so the test does not spend 90 HID events moving it.
        dut.registers.registers[20] = 32'd190; // s4 (x20) = right paddle Y

        // ------------------------------------------------------------
        // 3. Right paddle collision
        // ------------------------------------------------------------
        $display("\nTEST 3: RIGHT PADDLE COLLISION");
        timeout = 0;
        while (dut.registers.registers[25] !== 32'hffffffff && timeout < 50000) begin
            @(negedge clk);
            timeout = timeout + 1;
        end
        if (dut.registers.registers[25] !== 32'hffffffff) begin
            $display("FAIL: Ball did not reverse X direction at right paddle");
            $display("Current ball=(%0d,%0d), vx=%0d, right paddle Y=%0d",
                     dut.registers.registers[23], dut.registers.registers[24],
                     $signed(dut.registers.registers[25]), dut.registers.registers[20]);
            $fatal(1);
        end
        $display("PASS: Right paddle collision at ball=(%0d,%0d)",
                 dut.registers.registers[23], dut.registers.registers[24]);

        // ------------------------------------------------------------
        // 4. Top wall bounce
        // ------------------------------------------------------------
        $display("\nTEST 4: TOP WALL BOUNCE");
        timeout = 0;
        while (dut.registers.registers[26] !== 32'd1 && timeout < 500000) begin
            @(negedge clk);
            timeout = timeout + 1;
        end
        if (dut.registers.registers[26] !== 32'd1) begin
            $display("FAIL: Ball never reversed vertical direction at top wall");
            $fatal(1);
        end
        if (dut.registers.registers[24] > 32'd2) begin
            $display("FAIL: Top bounce occurred at unexpected Y=%0d",
                     dut.registers.registers[24]);
            $fatal(1);
        end
        $display("PASS: Top bounce; ball Y=%0d, vy=%0d",
                 dut.registers.registers[24], $signed(dut.registers.registers[26]));

        // At this point the ball is travelling left after the top bounce.
        // Position the left paddle in its path for a deterministic collision.
        dut.registers.registers[9] = 32'd50; // s1 = left paddle Y

        // ------------------------------------------------------------
        // 5. Left paddle collision
        // ------------------------------------------------------------
        $display("\nTEST 5: LEFT PADDLE COLLISION");
        timeout = 0;
        while (dut.registers.registers[25] !== 32'd1 && timeout < 120000) begin
            @(negedge clk);
            timeout = timeout + 1;
        end
        if (dut.registers.registers[25] !== 32'd1) begin
            $display("FAIL: Ball did not reverse X direction at left paddle");
            $display("Current ball=(%0d,%0d), vx=%0d, left paddle Y=%0d",
                     dut.registers.registers[23], dut.registers.registers[24],
                     $signed(dut.registers.registers[25]), dut.registers.registers[9]);
            $fatal(1);
        end
        $display("PASS: Left paddle collision at ball=(%0d,%0d)",
                 dut.registers.registers[23], dut.registers.registers[24]);

        // ------------------------------------------------------------
        // 6. Keyboard controls (same PS bridge path as hardware)
        // ------------------------------------------------------------
        // Stop generating new timer ticks during keyboard tests.
        dut.dmem.timer_prescaler = 32'hffffffff;
        $display("\nTEST 6: KEYBOARD CONTROLS");
        initial_left_y = dut.registers.registers[9];  // s1
        send_key(9'h11a); // W press
        $display("\n--- KEYBOARD DEBUG ---");
        $display("PS ready       = %b", ps_event_ready);
        $display("CPU event valid= %b", dut.dmem.cpu_event_valid);
        $display("CPU event ready= %b", dut.dmem.cpu_event_ready);
        $display("CPU event data = %03h", dut.dmem.cpu_event_data);
        $display("FIFO count     = %0d",
                dut.dmem.keyboard_controller.fifo_count);
        $display("Left paddle Y  = %0d", dut.registers.registers[9]);
        $display("PC             = %08h", pc_out);
        $display("---------------------\n");
        $display("PC             = %08h", pc_out);
        $display("Instruction    = %08h", instruction_out);
        $display("CPU state      = %0d", dut.cpu_state);
        $display("Memory request = %b", dut.memory_req);
        $display("Memory read    = %b", dut.MemRead);
        $display("ALU address    = %08h", dut.alu_result);
        $display("Memory data    = %08h", dut.memory_read_data);
        $display("Keyboard sel   = %b", dut.dmem.select_keyboard);
        $display("a0             = %08h", dut.registers.registers[10]);
        $display("memory_ready = %b", dut.memory_ready);
        $display("memory_req   = %b", dut.memory_req);
        $display("RAM select   = %b", dut.dmem.select_ram);
        $display("RAM ready    = %b", dut.dmem.ram_ready);
        $display("RAM state    = %b", dut.dmem.ram_controller.state);

        
        timeout = 0;
        while (dut.registers.registers[9] !== (initial_left_y - 1) &&
            timeout < 500000) begin
            @(negedge clk);
            timeout = timeout + 1;
        end

        if (dut.registers.registers[9] !== (initial_left_y - 1)) begin
            $display("FAIL: W did not move left paddle up");
            $fatal(1);
        end
        $display("PASS: W moves left paddle up");

        initial_left_y = dut.registers.registers[9];
        send_key(9'h116); // S press
        timeout = 0;
        while (dut.registers.registers[9] !== (initial_left_y + 1) &&
            timeout < 500000) begin
            @(negedge clk);
            timeout = timeout + 1;
        end

        if (dut.registers.registers[9] !== (initial_left_y + 1)) begin
            $display("FAIL: S did not move left paddle down");
            $fatal(1);
        end
        $display("PASS: S moves left paddle down");

        initial_right_y = dut.registers.registers[20]; // s4
        send_key(9'h10c); // I press
        timeout = 0;
        while (dut.registers.registers[20] != initial_right_y - 1 &&
            timeout < 500000) begin
            @(negedge clk);
            timeout = timeout + 1;
        end

        if (dut.registers.registers[20] != initial_right_y - 1) begin
            $display("FAIL: I did not move right paddle up");
            $fatal(1);
        end
        $display("PASS: I moves right paddle up");

        // K: move right paddle down
        initial_right_y = dut.registers.registers[20];
        send_key(9'h10e);
        timeout = 0;

        while (dut.registers.registers[20] != initial_right_y + 1 &&
            timeout < 500000) begin
            @(negedge clk);
            timeout = timeout + 1;
        end

        if (dut.registers.registers[20] != initial_right_y + 1) begin
            $display("FAIL: K did not move right paddle down");
            $fatal(1);
        end
        $display("PASS: K moves right paddle down");

        $display("\n========================================");
        $display("ALL PONG TESTS PASSED");
        $display("Ball physics: movement, top/bottom bounce, both paddle collisions");
        $display("Keyboard: W/S/I/K");
        $display("========================================\n");
        $finish;
    end

    always @(posedge clk) begin
        if (dut.memory_req &&
            dut.memory_ready &&
            dut.cpu_state == 2'b01) begin

            $display(
                "HANDSHAKE: time=%0t reset=%b pc=%h cpu_state=%b ready=%b req=%b",
                $time,
                reset,
                dut.pc,
                dut.cpu_state,
                dut.memory_ready,
                dut.memory_req
            );

            #1;

            $display(
                "AFTER EDGE: time=%0t pc=%h cpu_state=%b",
                $time,
                dut.pc,
                dut.cpu_state
            );
        end
    end

    integer keyboard_trace_count = 0;

    always @(posedge clk) begin
        if (!reset &&
            dut.dmem.keyboard_controller.fifo_count != 0 &&
            keyboard_trace_count < 150) begin

            $display(
                "KEYTRACE pc=%h instr=%h state=%b req=%b ready=%b addr=%h s1=%0d timer=%0d last=%0d",
                pc_out,
                instruction_out,
                dut.cpu_state,
                dut.memory_req,
                dut.memory_ready,
                dut.alu_result,
                dut.registers.registers[9],
                dut.dmem.timer_count,
                dut.registers.registers[27]
            );

            keyboard_trace_count = keyboard_trace_count + 1;
        end
    end

    initial begin
        #50000000;
        $display("FAIL: Global simulation timeout");
        $fatal(1);
    end

endmodule
