module add16(
    input wire [15:0] a,
    input wire [15:0] b,
    output wire [15:0] out
);  
    wire [16:0] cin;
    assign cin[0] = 0;
    genvar i;
    generate
        for(i = 0; i < 16; i = i+1)begin
            assign out[i] = a[i] ^ b[i] ^ cin[i];
            assign cin[i+1] = (a[i] & b[i]) | (b[i] & cin[i]) | (a[i] & cin[i]);
        end
    endgenerate
endmodule