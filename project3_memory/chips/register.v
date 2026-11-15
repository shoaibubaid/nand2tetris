module register(
    input wire clk,
    input wire [15:0] in,
    input wire load,
    output wire [15:0] out
);

    wire [15:0] temp1;
    genvar i;
    generate
        for(i = 0; i < 16; i= i+1)begin : register_bits
            mux gate_mux(.a(out[i]), .b(in[i]), .sel(load), .c(temp1[i]));
            dff gate_dff(.clk(clk), .in(temp1[i]), .out(out[i]));        
        end
    endgenerate
    

endmodule

/**
 * 16-bit register:
 * If load is asserted, the register's value is set to in;
 * Otherwise, the register maintains its current value:
 * if (load(t)) out(t+1) = int(t), else out(t+1) = out(t)
 */