module mux4way32(
    input wire [31:0] a,
    input wire [31:0] b,
    input wire [31:0] c,
    input wire [31:0] d,
    
    input wire [1:0] sel,

    output wire [31:0] out
);
    wire [31:0] out1;
    wire [31:0] out2;

    mux32 gate1(.a(a), .b(b), .sel(sel[0]), .c(out1));
    mux32 gate2(.a(c), .b(d), .sel(sel[0]), .c(out2));
    mux32 gate3(.a(out1), .b(out2), .sel(sel[1]), .c(out));

endmodule