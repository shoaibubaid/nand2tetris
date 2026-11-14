module or16(
    input wire [15:0] a,
    input wire [15:0] b,
    output wire [15:0] c 
);
    genvar i;
    generate
        
        for(i = 0; i < 16; i= i+1)begin
            or_gate gate(.a(a[i]), .b(b[i]), .c(c[i]));

        end
    endgenerate
endmodule