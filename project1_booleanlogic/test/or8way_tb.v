module or8way_tb;

    reg [7:0] a;
    wire b;

    or8way uut(.a(a), .b(b));

    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, or8way_tb);

        $monitor("a = %b  b = %b", a, b);

        a = 8'b00000000;
        #10;

        a = 8'b00000001;
        #10;

        a = 8'b00010000;
        #10;

        a = 8'b10000000;
        #10;

        a = 8'b10101010;
        #10;

        a = 8'b11111111;
        #10;

        $display("Testing Completed");
        $finish;
    end

endmodule