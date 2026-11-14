module and16_tb;
    reg [15:0] a;
    reg [15:0] b;
    wire [15:0] c;

    and16 uut(.a(a), .b(b), .c(c));

    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, and16_tb);

        $monitor("a = %b  b = %b c = %b", a,b,c);
        a = 254; b=123;
        #10

        a = 16'b1010101010101010; b = 16'b1011101011101011;
        #10

        a= 33; b = 444;
        #10
        $display("Testing Completed");
        $finish;

    end
endmodule