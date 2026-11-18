
`timescale 1ns/1ps

module main_ram (
    input  wire        clk,
    input  wire [11:0] address,
    input  wire [31:0] write_data,
    input  wire        write_enable,
    output wire [31:0] read_data
);

    // Existing 16 KB structural RAM
    ram4k_32 ram (
        .clk     (clk),
        .in      (write_data),
        .load    (write_enable),
        .address (address),
        .out     (read_data)
    );

endmodule
