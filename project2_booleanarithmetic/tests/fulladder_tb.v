module fulladder_tb;

    reg a;
    reg b;
    reg cin;

    wire sum;
    wire cout;

    fulladder uut(
        .a(a),
        .b(b),
        .cin(cin),
        .sum(sum),
        .cout(cout)
    );

    initial begin

        $dumpfile("dump.vcd");
        $dumpvars(0, fulladder_tb);

        $monitor(
            "a=%b b=%b cin=%b sum=%b carry=%b",
            a, b, cin, sum, cout
        );

        // First combination
        a = 0; b = 0; cin = 0;
        #10;

        // c = 1
        cin = 1;
        #10;

        // b = 1, c = 0
        b = 1; cin = 0;
        #10;

        // c = 1
        cin = 1;
        #10;

        // a = 1, b = 0, c = 0
        a = 1; b = 0; cin = 0;
        #10;

        // c = 1
        cin = 1;
        #10;

        // b = 1, c = 0
        b = 1; cin = 0;
        #10;

        // c = 1
        cin = 1;
        #10;

        $display("Testing Completed");
        $finish;

    end

endmodule