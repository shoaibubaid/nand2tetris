module mux4way16_tb;

    reg [15:0] a;
    reg [15:0] b;
    reg [15:0] c;
    reg [15:0] d;
    reg [1:0] sel;

    wire [15:0] out;

    mux4way16 uut(
        .a(a),
        .b(b),
        .c(c),
        .d(d),
        .sel(sel),
        .out(out)
    );

    initial begin

        $dumpfile("dump.vcd");
        $dumpvars(0, mux4way16_tb);

        $monitor(
            "a=%016b b=%016b c=%016b d=%016b sel=%02b out=%016b",
            a, b, c, d, sel, out
        );

        // First set of test cases

        a = 0;
        b = 0;
        c = 0;
        d = 0;
        sel = 0;
        #10;

        sel = 1;
        #10;

        sel = 2;
        #10;

        sel = 3;
        #10;


        // Second set of test cases

        a = 16'b0001001000110100;
        b = 16'b1001100001110110;
        c = 16'b1010101010101010;
        d = 16'b0101010101010101;

        sel = 0;
        #10;

        sel = 1;
        #10;

        sel = 2;
        #10;

        sel = 3;
        #10;

        $display("Testing Completed");
        $finish;

    end

endmodule