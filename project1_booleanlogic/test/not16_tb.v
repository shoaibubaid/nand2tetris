module not16_tb;
    reg [15:0] a;
    wire [15:0] b;

    not16 uut(.in(a), .out(b));

    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, not16_tb);

        $monitor("a = %b  b = %b", a,b);

        a = 0;
        #10

        a = 16'b1010101010101010;
        #10

        a= 33;
        #10
        $display("Testing Completed");
        $finish;

    end
endmodule