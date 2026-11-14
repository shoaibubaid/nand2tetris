module dmux(
    input wire in,
    input wire sel,
    output wire a,
    output wire b
);
    wire out1;
    wire out2;
    wire out3;
    not_gate gate0(.a(sel), .y(out1));
    and_gate gate1(.a(in), .b(out1), .c(a));
    and_gate gate2(.a(in), .b(sel), .c(b));
endmodule