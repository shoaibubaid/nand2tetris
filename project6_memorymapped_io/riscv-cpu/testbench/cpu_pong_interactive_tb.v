`timescale 1ns/1ps

// Interactive Pygame/VPI testbench. Keeps the real CPU and pong.hex running.
module cpu_pong_tb;
    reg clk = 1'b0;
    reg reset = 1'b1;
    always #5 clk = ~clk;

    reg        ps_event_valid = 1'b0;
    wire       ps_event_ready;
    reg [8:0]  ps_event_data = 9'b0;

    reg  [16:0] video_pixel_address = 17'b0;
    wire [7:0]  video_pixel_data;
    wire [31:0] pc_out;
    wire [31:0] instruction_out;
    wire instruction_valid;
    wire cpu_valid;

    cpu #(
        .IMEM_ADDR_WIDTH(10),
        .IMEM_INIT_FILE("software/assembler/pong.hex")
    ) dut (
        .clk(clk), .reset(reset),
        .ps_clk(clk), .ps_reset(reset),
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

    initial begin
        repeat (5) @(negedge clk);
        reset = 1'b0;
        // Simulation runs in paced 33,000-cycle batches. Scale the hardware
        // timer to 1 tick per 1,000 simulated clocks (about 1 ms per tick).
        // This preserves the game's 20-tick movement interval in wall time.
        dut.dmem.timer_prescaler = 32'd999;
        $display("Pong interactive simulation started. Waiting for Pygame VPI client...");
    end
endmodule
