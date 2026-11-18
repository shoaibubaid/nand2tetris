
module pc32(
    input wire clk,
    input wire [31:0] in,
    input wire reset,
    input wire load,
    input wire inc,
    output wire [31:0] out
);

    wire [31:0] incremented;
    wire [31:0] load_or_inc;
    wire [31:0] next_value;
    wire [31:0] final_value;

    // Increment current PC by 1.
    inc32 incrementer(
        .a(out),
        .out(incremented)
    );

    // Priority 1: increment or hold.
    mux32 mux_inc(
        .a(out),
        .b(incremented),
        .sel(inc),
        .c(load_or_inc)
    );

    // Priority 2: load.
    mux32 mux_load(
        .a(load_or_inc),
        .b(in),
        .sel(load),
        .c(next_value)
    );

    // Priority 3: reset.
    mux32 mux_reset(
        .a(next_value),
        .b(32'd0),
        .sel(reset),
        .c(final_value)
    );

    // 32-bit program counter storage.
    register32 pc_register(
        .clk(clk),
        .in(final_value),
        .load(1'b1),
        .out(out)
    );

endmodule
