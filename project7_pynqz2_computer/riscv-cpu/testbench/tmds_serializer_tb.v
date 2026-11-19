`timescale 1ns/1ps

module tmds_serializer_tb;

    reg pixel_clk;
    reg serial_clk;
    reg reset;

    reg [9:0] parallel_data;
    wire serial_data;

    integer errors;
    integer i;

    reg [9:0] expected_word;

    tmds_serializer dut (
        .pixel_clk(pixel_clk),
        .serial_clk(serial_clk),
        .reset(reset),
        .parallel_data(parallel_data),
        .serial_data(serial_data)
    );

    // Pixel clock: 100 MHz for simulation.
    initial pixel_clk = 0;
    always #5 pixel_clk = ~pixel_clk;

    // Serializer clock: 500 MHz (5x pixel clock).
    // Its phase is offset to avoid simultaneous pixel/serial edges.
    initial begin
        #0.5;
        serial_clk = 0;
        forever #1 serial_clk = ~serial_clk;
    end

    task transmit_and_check;
        input [9:0] word;
        integer bit_number;

        begin
            // Present the word before the next pixel-clock edge.
            @(negedge pixel_clk);
            parallel_data = word;

            // Wait until the word is loaded.
            @(posedge pixel_clk);
            #0.1;

            // Sample ten serialized bits.
            for (bit_number = 0; bit_number < 10;
                 bit_number = bit_number + 1) begin

                @(serial_clk);
                #0.1;

                if (serial_data !== word[bit_number]) begin
                    $display(
                        "FAIL: word=%b bit=%0d expected=%b got=%b",
                        word, bit_number,
                        word[bit_number], serial_data
                    );
                    errors = errors + 1;
                end
            end

            $display("Checked word: %b", word);
        end
    endtask

    initial begin
        errors = 0;
        reset = 1;
        parallel_data = 10'd0;

        repeat (3) @(negedge pixel_clk);
        reset = 0;

        transmit_and_check(10'b1101010100);
        transmit_and_check(10'b0010101011);
        transmit_and_check(10'b1011000110);

        if (errors == 0)
            $display("ALL TMDS SERIALIZER TESTS PASSED");
        else
            $display("TMDS SERIALIZER TESTS FAILED: %0d errors", errors);

        $finish;
    end

endmodule