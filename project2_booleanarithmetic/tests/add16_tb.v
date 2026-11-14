module add16_tb;

    reg [15:0] a;
    reg [15:0] b;
    wire [15:0] out;

    add16 uut(
        .a(a),
        .b(b),
        .out(out)
    );

    initial begin

        $dumpfile("dump.vcd");
        $dumpvars(0, add16_tb);

        $monitor(
            "a=%016b b=%016b out=%016b",
            a, b, out
        );

        // Test 1
        a = 16'b0000000000000000;
        b = 16'b0000000000000000;
        #10;

        // Test 2
        a = 16'b0000000000000000;
        b = 16'b1111111111111111;
        #10;

        // Test 3
        a = 16'b1111111111111111;
        b = 16'b1111111111111111;
        #10;

        // Test 4
        a = 16'b1010101010101010;
        b = 16'b0101010101010101;
        #10;

        // Test 5
        a = 16'b0011110011000011;
        b = 16'b0000111111110000;
        #10;

        // Test 6
        a = 16'b0001001000110100;
        b = 16'b1001100001110110;
        #10;

        $display("Testing Completed");
        $finish;

    end

endmodule