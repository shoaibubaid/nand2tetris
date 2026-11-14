module inc16_tb;
    reg [15:0] in;
    wire [15:0] out;

    inc16 uut(
        .a(in),
        .out(out)
    );

    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, inc16_tb);

        $monitor("in=%016b out=%016b", in, out);

        // in = 0
        in = 16'b0000000000000000; #10;

        // in = -1
        in = 16'b1111111111111111; #10;

        // in = 5
        in = 16'b0000000000000101; #10;

        // in = -5
        in = 16'b1111111111111011; #10;

        $display("Testing Completed");
        $finish;
    end
endmodule