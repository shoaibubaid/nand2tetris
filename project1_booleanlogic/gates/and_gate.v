module and_gate(
    input wire a,
    input wire b,
    output wire c
);  
    wire d;
    nand_gate gate1(.a(a), .b(b), .c(d));
    nand_gate gate2(.a(d), .b(d), .c(c));
endmodule