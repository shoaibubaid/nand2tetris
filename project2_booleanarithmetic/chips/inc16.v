module inc16(
    input wire [15:0] a,
    output wire [15:0] out
);
    assign out = a + 16'd1;
endmodule