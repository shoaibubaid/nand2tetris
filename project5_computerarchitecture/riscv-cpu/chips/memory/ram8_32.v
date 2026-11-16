module ram8_32(
    input wire clk,
    input wire [2:0] address,
    input wire [31:0] in,
    input wire load,
    output wire [31:0] out
);

    // Individual load signals for the 8 registers
    wire [7:0] reg_load;

    // Outputs of the 8 registers
    wire [31:0] q0, q1, q2, q3;
    wire [31:0] q4, q5, q6, q7;

    // Decode the address to select which register gets written
    dmux8way write_decoder(
        .in(load),
        .sel(address),
        .a(reg_load[0]),
        .b(reg_load[1]),
        .c(reg_load[2]),
        .d(reg_load[3]),
        .e(reg_load[4]),
        .f(reg_load[5]),
        .g(reg_load[6]),
        .h(reg_load[7])
    );

    // Eight 32-bit registers
    register32 r0(.clk(clk), .in(in), .load(reg_load[0]), .out(q0));
    register32 r1(.clk(clk), .in(in), .load(reg_load[1]), .out(q1));
    register32 r2(.clk(clk), .in(in), .load(reg_load[2]), .out(q2));
    register32 r3(.clk(clk), .in(in), .load(reg_load[3]), .out(q3));
    register32 r4(.clk(clk), .in(in), .load(reg_load[4]), .out(q4));
    register32 r5(.clk(clk), .in(in), .load(reg_load[5]), .out(q5));
    register32 r6(.clk(clk), .in(in), .load(reg_load[6]), .out(q6));
    register32 r7(.clk(clk), .in(in), .load(reg_load[7]), .out(q7));

    // Select the addressed register's output
    mux8way32 read_selector(
        .a(q0),
        .b(q1),
        .c(q2),
        .d(q3),
        .e(q4),
        .f(q5),
        .g(q6),
        .h(q7),
        .sel(address),
        .out(out)
    );

endmodule

/**
 * Memory of eight 32-bit registers.
 * If load is asserted, the value of the register selected by
 * address is set to in; Otherwise, the value does not change.
 * The value of the selected register is emitted by out.
 */