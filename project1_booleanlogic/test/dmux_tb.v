module dmux_test_bench;
    reg i;
    reg sel;
    wire a;
    wire b;

    dmux uut(.a(a), .b(b), .sel(sel), .in(i));

    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, dmux_test_bench);

        $monitor("i=%b sel=%b a = %b b = %b",i,sel,a,b);
        
        i = 0; sel = 0;
        #10;
        if(a !== 0 || b !== 0) $display("FAIL: 00");

        i = 0; sel = 1;
        #10;
        if(a !== 0 || b !== 0) $display("FAIL: 01");

        i = 1; sel = 0;
        #10;
        if(a !== 1 || b !== 0) $display("FAIL: 10");

        i = 1; sel = 1;
        #10;
        if(a !== 0 || b !== 1) $display("FAIL: 01");

        $display("Testing Completed");
        $finish;

    end
endmodule