module or8way(
    input wire [7:0] a,
    output wire b
);

    wire w1, w2, w3, w4, w5, w6;

    or_gate g1(.a(a[0]), .b(a[1]), .c(w1));
    or_gate g2(.a(a[2]), .b(a[3]), .c(w2));
    or_gate g3(.a(a[4]), .b(a[5]), .c(w3));
    or_gate g4(.a(a[6]), .b(a[7]), .c(w4));

    or_gate g5(.a(w1), .b(w2), .c(w5));
    or_gate g6(.a(w3), .b(w4), .c(w6));

    or_gate g7(.a(w5), .b(w6), .c(b));

endmodule