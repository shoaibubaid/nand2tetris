module and_test_bench;
    reg a;
    reg b;
    wire o;

    and_gate uut(.a(a), .b(b), .c(o));

    initial begin
        $monitor("a=%b b=%b o = %b",a,b,o);
        
        a = 0; b = 0;
        #10;
        if(o !== 0) $display("FAIL: 00");

        a = 1; b = 0;
        #10;
        if(o !== 0) $display("FAIL: 10");

        a = 0; b = 1;
        #10;
        if(o !== 0) $display("FAIL: 01");

        a = 1; b = 1;
        #10;
        if(o !== 1) $display("FAIL: 11");

        $display("Testing Completed");
        $finish;

    end
endmodule