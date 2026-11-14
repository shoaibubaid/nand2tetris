module halfadder_tb;

    reg a;
    reg b;
    wire sum;
    wire carry;

    halfadder uut(
        .a(a),
        .b(b),
        .sum(sum),
        .carry(carry)
    );

    initial begin

        $dumpfile("dump.vcd");
        $dumpvars(0, halfadder_tb);

        $monitor("a=%b b=%b sum=%b carry=%b", a, b, sum, carry);

        a = 0;
        b = 0;
        #10;

        a = 0;
        b = 1;
        #10;

        a = 1;
        b = 0;
        #10;

        a = 1;
        b = 1;
        #10;

        $display("Testing Completed");
        $finish;

    end

endmodule