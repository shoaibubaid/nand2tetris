module xor_gate(
    input wire a,
    input wire b,
    output wire c
);  
    wire out1;
    wire out2;
    wire out3;

    nand_gate gate1(.a(a), .b(b), .c(out1));
    nand_gate gate2(.a(a), .b(out1), .c(out2));
    nand_gate gate3(.a(out1), .b(b), .c(out3));
    nand_gate gate4(.a(out2), .b(out3), .c(c));

endmodule