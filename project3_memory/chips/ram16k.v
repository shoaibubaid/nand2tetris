module ram16k(
    input wire clk,
    input wire [15:0] in,
    input wire load,
    input wire [13:0] address,
    output wire [15:0] out
);

    wire [3:0] bank_load;
    wire [15:0] q0, q1, q2, q3;

    // Decode the two most significant address bits.
    dmux4way write_decoder(
        .in(load),
        .sel(address[13:12]),
        .a(bank_load[0]),
        .b(bank_load[1]),
        .c(bank_load[2]),
        .d(bank_load[3])
    );

    // Four banks, each containing 4096 words of 16 bits.
    ram4k bank0(
        .clk(clk), .in(in), .load(bank_load[0]),
        .address(address[11:0]), .out(q0)
    );

    ram4k bank1(
        .clk(clk), .in(in), .load(bank_load[1]),
        .address(address[11:0]), .out(q1)
    );

    ram4k bank2(
        .clk(clk), .in(in), .load(bank_load[2]),
        .address(address[11:0]), .out(q2)
    );

    ram4k bank3(
        .clk(clk), .in(in), .load(bank_load[3]),
        .address(address[11:0]), .out(q3)
    );

    // Select the output from the addressed bank.
    mux4way16 read_selector(
        .a(q0), .b(q1), .c(q2), .d(q3),
        .sel(address[13:12]),
        .out(out)
    );

endmodule

/**
 * Memory of 16K 16-bit registers.
 * If load is asserted, the value of the register selected by
 * address is set to in; Otherwise, the value does not change.
 * The value of the selected register is emitted by out.
 */