
`timescale 1ns/1ps

module cpu_drawrectangle_tb;

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

    
    task dump_framebuffer;
        integer fd;
        integer x, y;
        integer pixel_offset;
        integer word_index;
        integer byte_lane;
        reg [31:0] word_data;
        reg [7:0] pixel;
        reg [7:0] red, green, blue;

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

                        red   = {pixel[7:5], pixel[7:5], pixel[7:6]};
                        green = {pixel[4:2], pixel[4:2], pixel[4:3]};
                        blue  = {pixel[1:0], pixel[1:0],
                                pixel[1:0], pixel[1:0]};

                        $fwrite(fd, "%c%c%c", red, green, blue);
                    end
                end

                $fclose(fd);
                $display("Framebuffer exported!");
            end
        end
    endtask



    initial begin
        $dumpfile("rectangle_demo.vcd");
        $dumpvars(0, cpu_drawrectangle_tb);

        cycles = 0;

        repeat (3) @(negedge clk);
        reset = 0;

        // Wait for rectangle drawing to finish.
        while (pc_out != 32'h0000001C && cycles < 100000) begin
            @(negedge clk);
            cycles = cycles + 1;
        end

        $display("PC = %08h", pc_out);
        $display("Cycles = %0d", cycles);

        if (cycles >= 100000) begin
            $display("FAIL: CPU timeout");
            $fatal;
        end

        dump_framebuffer();

        $display("RECTANGLE FRAMEBUFFER EXPORTED!");
        $finish;
    end



endmodule
