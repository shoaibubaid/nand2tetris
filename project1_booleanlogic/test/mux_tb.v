module mux_test_bench;
    reg a;
    reg b;
    reg sel;
    wire o;

    mux uut(.a(a), .b(b), .sel(sel), .c(o));

    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, mux_test_bench);

        $monitor("a=%b b=%b sel = %b o = %b",a,b,sel,o);
        
        a = 0; b = 0; sel = 0;
        #10;
        if(o !== 0) $display("FAIL: 000");

        a = 1; b = 0; sel = 0;
        #10;
        if(o !== 1) $display("FAIL: 100");

        a = 0; b = 1; sel = 1;
        #10;
        if(o !== 1) $display("FAIL: 011");

        a = 1; b = 1; sel = 1;
        #10;
        if(o !== 1) $display("FAIL: 111");

        $display("Testing Completed");
        $finish;

    end
endmodule