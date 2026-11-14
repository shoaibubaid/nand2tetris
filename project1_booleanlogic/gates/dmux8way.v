module dmux8way(
    input wire in,
    input wire [2:0] sel,
    output wire a,
    output wire b,
    output wire c,
    output wire d,
    output wire e,
    output wire f,
    output wire g,
    output wire h
);
    wire out1;
    wire out2;

    dmux gate3(
        .in(in),
        .sel(sel[2]),
        .a(out1),
        .b(out2)
    );

    dmux4way gate1(
        .in(out1),
        .sel(sel[1:0]),
        .a(a),
        .b(b),
        .c(c),
        .d(d)
    );

    dmux4way gate2(
        .in(out2),
        .sel(sel[1:0]),
        .a(e),
        .b(f),
        .c(g),
        .d(h)
    );

    

endmodule