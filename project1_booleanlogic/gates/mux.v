module mux(
    input wire a,
    input wire b,
    input wire sel,
    output wire c
);  
    wire out1;
    wire out2;
    wire out3;
    not_gate gate0(.a(sel), .y(out1));
    and_gate gate1(.a(a), .b(out1), .c(out2));
    and_gate gate2(.a(b), .b(sel), .c(out3));
    or_gate gate3(.a(out2), .b(out3), .c(c));
endmodule