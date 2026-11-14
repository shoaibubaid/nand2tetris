module or_gate(
    input wire a,
    input wire b,
    output wire c
);
    // not(anot&bnot)
    wire a_not;
    wire b_not;

    nand_gate gate1(.a(a), .b(a), .c(a_not));
    nand_gate gate2(.a(b), .b(b), .c(b_not));
    nand_gate gate3(.a(a_not), .b(b_not), .c(c));

endmodule