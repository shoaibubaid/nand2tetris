module mux16(
    input wire [15:0] a,
    input wire [15:0] b,
    input wire sel,
    output wire [15:0] c 
);
    genvar i;
    generate
        
        for(i = 0; i < 16; i= i+1)begin
            mux gate(.a(a[i]), .b(b[i]), .sel(sel), .c(c[i]));

        end
    endgenerate
endmodule

/**
 * 16-bit multiplexor: 
 * for i = 0, ..., 15:
 * if (sel = 0) out[i] = a[i], else out[i] = b[i]
 */