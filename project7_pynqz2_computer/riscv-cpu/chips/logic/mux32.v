module mux32(
    input wire [31:0] a,
    input wire [31:0] b,
    input wire sel,
    output wire [31:0] c 
);
    genvar i;
    generate
        
        for(i = 0; i < 32; i= i+1)begin
            mux gate(.a(a[i]), .b(b[i]), .sel(sel), .c(c[i]));

        end
    endgenerate
endmodule

/**
 * 32-bit multiplexor: 
 * for i = 0, ..., 31:
 * if (sel = 0) out[i] = a[i], else out[i] = b[i]
 */