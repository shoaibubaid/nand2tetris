module mux16_tb;

    reg [15:0] a;
    reg [15:0] b;
    reg sel;
    wire [15:0] c;

    mux16 uut(.a(a), .b(b), .sel(sel), .c(c));

    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, mux16_tb);

        $monitor("a = %b  b = %b  sel = %b  c = %b", a, b, sel, c);

        a = 254; b = 123; sel = 0;
        #10;

        a = 254; b = 123; sel = 1;
        #10;

        a = 16'b1010101010101010;
        b = 16'b1011101011101011;
        sel = 0;
        #10;

        a = 16'b1010101010101010;
        b = 16'b1011101011101011;
        sel = 1;
        #10;

        a = 33; b = 444; sel = 0;
        #10;

        a = 33; b = 444; sel = 1;
        #10;

        $display("Testing Completed");
        $finish;

    end
endmodule