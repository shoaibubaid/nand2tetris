
module ram512(
    input wire clk,
    input wire [15:0] in,
    input wire load,
    input wire [8:0] address,
    output wire [15:0] out
);

    wire [7:0] load_ram;

    wire [15:0] q0, q1, q2, q3;
    wire [15:0] q4, q5, q6, q7;

    dmux8way write_decoder(
        .in(load),
        .sel(address[8:6]),
        .a(load_ram[0]),
        .b(load_ram[1]),
        .c(load_ram[2]),
        .d(load_ram[3]),
        .e(load_ram[4]),
        .f(load_ram[5]),
        .g(load_ram[6]),
        .h(load_ram[7])
    );

    ram8 ram0(.clk(clk), .address(address[2:0]), .in(in), .load(load_ram[0]), .out(q0));
    ram8 ram1(.clk(clk), .address(address[2:0]), .in(in), .load(load_ram[1]), .out(q1));
    ram8 ram2(.clk(clk), .address(address[2:0]), .in(in), .load(load_ram[2]), .out(q2));
    ram8 ram3(.clk(clk), .address(address[2:0]), .in(in), .load(load_ram[3]), .out(q3));
    ram8 ram4(.clk(clk), .address(address[2:0]), .in(in), .load(load_ram[4]), .out(q4));
    ram8 ram5(.clk(clk), .address(address[2:0]), .in(in), .load(load_ram[5]), .out(q5));
    ram8 ram6(.clk(clk), .address(address[2:0]), .in(in), .load(load_ram[6]), .out(q6));
    ram8 ram7(.clk(clk), .address(address[2:0]), .in(in), .load(load_ram[7]), .out(q7));

    mux8way16 read_selector(
        .a(q0),
        .b(q1),
        .c(q2),
        .d(q3),
        .e(q4),
        .f(q5),
        .g(q6),
        .h(q7),
        .sel(address[8:6]),
        .out(out)
    );

endmodule

/**
 * Memory of 512 16-bit registers.
 * If load is asserted, the value of the register selected by
 * address is set to in; Otherwise, the value does not change.
 * The value of the selected register is emitted by out.
 */