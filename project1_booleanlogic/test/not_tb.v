module not_tb;
    reg a;
    wire b;

    not_gate uut(.a(a), .y(b));

    initial begin
        $monitor("a = %b  b = %b", a,b);

        a = 0;
        #10
        if(b != 1) $display("FAIL 0");

        a = 1;
        #10
        if(b != 0) $display("FAIL 1");
        
        $display("Testing Completed");
        $finish;

    end
endmodule