module mux8way32(
    input wire [31:0] a,
    input wire [31:0] b,
    input wire [31:0] c,
    input wire [31:0] d,
    input wire [31:0] e,
    input wire [31:0] f,
    input wire [31:0] g,
    input wire [31:0] h,
    
    input wire [2:0] sel,

    output wire [31:0] out
);
    wire [31:0] out1;
    wire [31:0] out2;

    mux4way32 gate1(.a(a), .b(b), .c(c), .d(d), .sel(sel[1:0]), .out(out1));
    mux4way32 gate2(.a(e), .b(f), .c(g), .d(h), .sel(sel[1:0]), .out(out2));
    mux32 gate3(.a(out1), .b(out2), .sel(sel[2]), .c(out));
endmodule