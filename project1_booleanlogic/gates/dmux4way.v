module dmux4way(
    input wire in,
    input wire [1:0] sel,
    output wire a,
    output wire b,
    output wire c,
    output wire d
);
    wire out1;
    wire out2;

    dmux gate1(
        .in(in),
        .sel(sel[1]),
        .a(out1),
        .b(out2)
    );

    dmux gate2(
        .in(out1),
        .sel(sel[0]),
        .a(a),
        .b(b)
    );

    dmux gate3(
        .in(out2),
        .sel(sel[0]),
        .a(c),
        .b(d)
    );

endmodule

/**
 * 4-way demultiplexor:
 * [a, b, c, d] = [in, 0, 0, 0] if sel = 00
 *                [0, in, 0, 0] if sel = 01
 *                [0, 0, in, 0] if sel = 10
 *                [0, 0, 0, in] if sel = 11
 */