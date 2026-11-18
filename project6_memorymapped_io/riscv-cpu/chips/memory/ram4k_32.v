module ram4k_32(
    input wire clk,
    input wire [31:0] in,
    input wire load,
    input wire [11:0] address,
    output wire [31:0] out
);

    // Write enable for each RAM512
    wire [7:0] load_ram;

    // Outputs of the eight RAM512 chips
    wire [31:0] q0, q1, q2, q3;
    wire [31:0] q4, q5, q6, q7;

    // Select which RAM512 receives the write
    dmux8way write_decoder(
        .in(load),
        .sel(address[11:9]),
        .a(load_ram[0]),
        .b(load_ram[1]),
        .c(load_ram[2]),
        .d(load_ram[3]),
        .e(load_ram[4]),
        .f(load_ram[5]),
        .g(load_ram[6]),
        .h(load_ram[7])
    );

    // Eight RAM512 chips
    ram512_32 ram0(.clk(clk), .in(in), .load(load_ram[0]), .address(address[8:0]), .out(q0));
    ram512_32 ram1(.clk(clk), .in(in), .load(load_ram[1]), .address(address[8:0]), .out(q1));
    ram512_32 ram2(.clk(clk), .in(in), .load(load_ram[2]), .address(address[8:0]), .out(q2));
    ram512_32 ram3(.clk(clk), .in(in), .load(load_ram[3]), .address(address[8:0]), .out(q3));
    ram512_32 ram4(.clk(clk), .in(in), .load(load_ram[4]), .address(address[8:0]), .out(q4));
    ram512_32 ram5(.clk(clk), .in(in), .load(load_ram[5]), .address(address[8:0]), .out(q5));
    ram512_32 ram6(.clk(clk), .in(in), .load(load_ram[6]), .address(address[8:0]), .out(q6));
    ram512_32 ram7(.clk(clk), .in(in), .load(load_ram[7]), .address(address[8:0]), .out(q7));

    // Select output from the addressed RAM512
    mux8way32 read_selector(
        .a(q0),
        .b(q1),
        .c(q2),
        .d(q3),
        .e(q4),
        .f(q5),
        .g(q6),
        .h(q7),
        .sel(address[11:9]),
        .out(out)
    );

endmodule

/**
 * Memory of 4K 16-bit registers.
 * If load is asserted, the value of the register selected by
 * address is set to in; Otherwise, the value does not change.
 * The value of the selected register is emitted by out.
 */