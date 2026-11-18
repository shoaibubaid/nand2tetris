
`timescale 1ns/1ps

module framebuffer_video_read_tb;

    reg clk, reset;
    reg req, mem_read, mem_write;
    reg [16:0] offset;
    reg [31:0] write_data;
    reg [2:0] funct3;

    wire ready;
    wire [31:0] read_data;
    wire access_error;

    reg [16:0] video_pixel_address;
    wire [7:0] video_pixel_data;

    integer errors;
    integer i;

    framebuffer dut (
        .clk(clk),
        .reset(reset),
        .req(req),
        .mem_read(mem_read),
        .mem_write(mem_write),
        .offset(offset),
        .write_data(write_data),
        .funct3(funct3),
        .ready(ready),
        .read_data(read_data),
        .access_error(access_error),
        .video_pixel_address(video_pixel_address),
        .video_pixel_data(video_pixel_data)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    task write_word;
        input [16:0] address;
        input [31:0] data;
        begin
            @(negedge clk);
            req = 1;
            mem_read = 0;
            mem_write = 1;
            offset = address;
            write_data = data;
            funct3 = 3'b010; // SW

            wait (ready);
            #1;

            if (access_error) begin
                $display("FAIL: write access error");
                errors = errors + 1;
            end

            @(negedge clk);
            req = 0;
            mem_write = 0;

            // Allow controller to return to IDLE.
            @(negedge clk);
        end
    endtask

    task check_pixel;
        input [16:0] address;
        input [7:0] expected;
        begin
            @(negedge clk);
            video_pixel_address = address;

            // Synchronous read: wait for sampling edge.
            @(posedge clk);
            #1;

            if (video_pixel_data !== expected) begin
                $display(
                    "FAIL: pixel[%0d] expected %h, got %h",
                    address, expected, video_pixel_data
                );
                errors = errors + 1;
            end
            else begin
                $display(
                    "PASS: pixel[%0d] = %h",
                    address, video_pixel_data
                );
            end
        end
    endtask

    initial begin
        reset = 1;
        req = 0;
        mem_read = 0;
        mem_write = 0;
        offset = 0;
        write_data = 0;
        funct3 = 0;
        video_pixel_address = 0;
        errors = 0;

        repeat (3) @(negedge clk);
        reset = 0;

        // CPU writes two words.
        write_word(0, 32'h44332211);
        write_word(4, 32'h88776655);

        // Video port reads all eight individual pixels.
        check_pixel(0, 8'h11);
        check_pixel(1, 8'h22);
        check_pixel(2, 8'h33);
        check_pixel(3, 8'h44);

        check_pixel(4, 8'h55);
        check_pixel(5, 8'h66);
        check_pixel(6, 8'h77);
        check_pixel(7, 8'h88);

        if (errors == 0)
            $display("ALL FRAMEBUFFER VIDEO READ TESTS PASSED");
        else
            $display("FRAMEBUFFER VIDEO READ TESTS FAILED: %0d errors", errors);

        $finish;
    end

endmodule
