module dmux4way_tb;

    reg in;
    reg [1:0] sel;

    wire a, b, c, d;

    dmux4way uut(
        .in(in),
        .sel(sel),
        .a(a),
        .b(b),
        .c(c),
        .d(d)
    );

    initial begin

        $dumpfile("dump.vcd");
        $dumpvars(0, dmux4way_tb);

        $monitor(
            "in=%b sel=%02b a=%b b=%b c=%b d=%b",
            in, sel, a, b, c, d
        );

        // First set: in = 0

        in = 0;
        sel = 2'b00;
        #10;

        sel = 2'b01;
        #10;

        sel = 2'b10;
        #10;

        sel = 2'b11;
        #10;


        // Second set: in = 1

        in = 1;
        sel = 2'b00;
        #10;

        sel = 2'b01;
        #10;

        sel = 2'b10;
        #10;

        sel = 2'b11;
        #10;


        $display("Testing Completed");
        $finish;

    end

endmodule