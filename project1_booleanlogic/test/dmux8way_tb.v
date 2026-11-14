
module dmux8way_tb;

    reg in;
    reg [2:0] sel;

    wire a, b, c, d, e, f, g, h;

    dmux8way uut(
        .in(in),
        .sel(sel),
        .a(a),
        .b(b),
        .c(c),
        .d(d),
        .e(e),
        .f(f),
        .g(g),
        .h(h)
    );

    initial begin

        $dumpfile("dump.vcd");
        $dumpvars(0, dmux8way_tb);

        $monitor(
            "in=%b sel=%03b | a=%b b=%b c=%b d=%b e=%b f=%b g=%b h=%b",
            in, sel, a, b, c, d, e, f, g, h
        );

        // First set: in = 0

        in = 0;
        sel = 3'b000;
        #10;

        sel = 3'b001;
        #10;

        sel = 3'b010;
        #10;

        sel = 3'b011;
        #10;

        sel = 3'b100;
        #10;

        sel = 3'b101;
        #10;

        sel = 3'b110;
        #10;

        sel = 3'b111;
        #10;


        // Second set: in = 1

        in = 1;
        sel = 3'b000;
        #10;

        sel = 3'b001;
        #10;

        sel = 3'b010;
        #10;

        sel = 3'b011;
        #10;

        sel = 3'b100;
        #10;

        sel = 3'b101;
        #10;

        sel = 3'b110;
        #10;

        sel = 3'b111;
        #10;


        $display("Testing Completed");
        $finish;

    end

endmodule
