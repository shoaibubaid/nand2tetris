module add32(
    input wire [31:0] a,
    input wire [31:0] b,
    output wire [31:0] out
);  
    wire [32:0] cin;
    assign cin[0] = 0;
    genvar i;
    generate
        for(i = 0; i < 32; i = i+1)begin
            assign out[i] = a[i] ^ b[i] ^ cin[i];
            assign cin[i+1] = (a[i] & b[i]) | (b[i] & cin[i]) | (a[i] & cin[i]);
        end
    endgenerate
endmodule