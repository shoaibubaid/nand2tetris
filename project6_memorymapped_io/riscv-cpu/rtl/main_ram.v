
`timescale 1ns/1ps

module main_ram (
    input  wire        clk,
    input  wire [11:0] address,
    input  wire [31:0] write_data,
    input  wire        write_enable,
    output wire [31:0] read_data
);

`ifdef STRUCTURAL_RAM

    ram4k_32 ram (
        .clk     (clk),
        .in      (write_data),
        .load    (write_enable),
        .address (address),
        .out     (read_data)
    );

`else

    // Behavioral model: 4096 words = 16 KB
    reg [31:0] memory [0:4095];

    // Combinational read
    assign read_data = memory[address];

    // Synchronous write
    always @(posedge clk) begin
        if (write_enable)
            memory[address] <= write_data;
    end

`endif

endmodule
