// Top-level computer interface
module top #(
    parameter IMEM_ADDR_WIDTH = 10,
    parameter IMEM_INIT_FILE = "",
    parameter DMEM_BYTES = 4096
)(
    input wire clk,
    input wire reset,

    // Debug outputs
    output wire [31:0] pc,
    output wire [31:0] instruction,
    output wire instruction_valid,
    output wire cpu_valid
);

    // Instantiate the CPU
    cpu #(
        .IMEM_ADDR_WIDTH(IMEM_ADDR_WIDTH),
        .IMEM_INIT_FILE(IMEM_INIT_FILE),
        .DMEM_BYTES(DMEM_BYTES)
    ) processor (
        .clk(clk),
        .reset(reset),

        .pc_out(pc),
        .instruction_out(instruction),
        .instruction_valid(instruction_valid),
        .cpu_valid(cpu_valid)
    );

endmodule