
module mux8way16_tb;

    reg [15:0] a, b, c, d;
    reg [15:0] e, f, g, h;

    reg [2:0] sel;

    wire [15:0] out;

    mux8way16 uut(
        .a(a), .b(b), .c(c), .d(d),
        .e(e), .f(f), .g(g), .h(h),
        .sel(sel),
        .out(out)
    );

    initial begin

        $dumpfile("dump.vcd");
        $dumpvars(0, mux8way16_tb);

        $monitor(
            "sel=%03b | a=%016b b=%016b c=%016b d=%016b | e=%016b f=%016b g=%016b h=%016b | out=%016b",
            sel, a, b, c, d, e, f, g, h, out
        );

        // First set of test cases

        a = 0;
        b = 0;
        c = 0;
        d = 0;
        e = 0;
        f = 0;
        g = 0;
        h = 0;

        sel = 0;
        #10;

        sel = 1;
        #10;

        sel = 2;
        #10;

        sel = 3;
        #10;

        sel = 4;
        #10;

        sel = 5;
        #10;

        sel = 6;
        #10;

        sel = 7;
        #10;


        // Second set of test cases

        a = 16'b0001001000110100;
        b = 16'b0010001101000101;
        c = 16'b0011010001010110;
        d = 16'b0100010101100111;

        e = 16'b0101011001111000;
        f = 16'b0110011110001001;
        g = 16'b0111100010011010;
        h = 16'b1000100110101011;

        sel = 0;
        #10;

        sel = 1;
        #10;

        sel = 2;
        #10;

        sel = 3;
        #10;

        sel = 4;
        #10;

        sel = 5;
        #10;

        sel = 6;
        #10;

        sel = 7;
        #10;

        $display("Testing Completed");
        $finish;

    end

endmodule
