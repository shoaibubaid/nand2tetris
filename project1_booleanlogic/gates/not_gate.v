module not_gate(
    input wire a,
    output wire y
);
    nand_gate gate(.a(a), .b(a), .c(y)); 
endmodule