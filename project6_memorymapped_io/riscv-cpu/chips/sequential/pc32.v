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

    // Increment the current PC value.
    inc32 incrementer(
        .a(out),
        .out(incremented)
    );

    // Priority 1: load takes priority over increment.
    mux32 mux_load_inc(
        .a(incremented),
        .b(in),
        .sel(load),
        .c(load_or_inc)
    );

    // Priority 2: reset takes priority over everything.
    mux32 mux_reset(
        .a(load_or_inc),
        .b(32'd0),
        .sel(reset),
        .c(next_value)
    );

    // Store the selected next value.
    register pc_register(
        .clk(clk),
        .in(next_value),
        .load(1'b1),
        .out(out)
    );

endmodule


// A 32-bit counter.
// if      reset(t): out(t+1) = 0
// else if load(t):  out(t+1) = in(t)
// else if inc(t):   out(t+1) = out(t) + 1
// else              out(t+1) = out(t)