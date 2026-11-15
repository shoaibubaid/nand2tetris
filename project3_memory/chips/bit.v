module bit_gate(
    input wire clk,
    input wire in,
    input wire load,
    output wire out
);

    wire temp1;

    mux gate_mux(.a(out), .b(in), .sel(load), .c(temp1));
    dff gate_dff(.clk(clk), .in(temp1), .out(out));

endmodule

/**
 * 1-bit register:
 * If load is asserted, the register's value is set to in;
 * Otherwise, the register maintains its current value:
 * if (load(t)) out(t+1) = in(t), else out(t+1) = out(t)
 */