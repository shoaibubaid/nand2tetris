module not16(
    input wire [15:0] in,
    output wire [15:0] out
);
    genvar i;
    
    generate
        for(i = 0; i <16; i=i+1)begin
            nand_gate gate(.a(in[i]), .b(in[i]), .c(out[i]));
        end
    endgenerate
endmodule