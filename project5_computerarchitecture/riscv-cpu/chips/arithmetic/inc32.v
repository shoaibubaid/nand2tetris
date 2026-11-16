module inc32(
    input wire [31:0] a,
    output wire [31:0] out
);
    assign out = a + 32'd1;
endmodule

/**
 * 32-bit incrementer:
 * out = in + 1
 */