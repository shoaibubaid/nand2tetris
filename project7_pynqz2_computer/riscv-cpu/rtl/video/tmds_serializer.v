
module tmds_serializer (
    input  wire       pixel_clk,
    input  wire       serial_clk,
    input  wire       reset,

    input  wire [9:0] parallel_data,
    output wire       serial_data
);

`ifdef XILINX

    wire shift_out_1;
    wire shift_out_2;

    // Slave: supplies bits 8 and 9.
    OSERDESE2 #(
        .DATA_RATE_OQ("DDR"),
        .DATA_RATE_TQ("BUF"),
        .DATA_WIDTH(10),
        .SERDES_MODE("SLAVE"),
        .TRISTATE_WIDTH(1)
    ) serializer_slave (
        .OQ(),
        .OFB(),
        .TQ(),
        .TFB(),
        .SHIFTOUT1(shift_out_1),
        .SHIFTOUT2(shift_out_2),

        .CLK(serial_clk),
        .CLKDIV(pixel_clk),

        .D1(1'b0),
        .D2(1'b0),
        .D3(parallel_data[8]),
        .D4(parallel_data[9]),
        .D5(1'b0),
        .D6(1'b0),
        .D7(1'b0),
        .D8(1'b0),

        .T1(1'b0),
        .T2(1'b0),
        .T3(1'b0),
        .T4(1'b0),
        .TBYTEIN(1'b0),

        .TCE(1'b0),
        .OCE(1'b1),

        .RST(reset),

        .SHIFTIN1(1'b0),
        .SHIFTIN2(1'b0)
    );

    // Master: transmits bits 0 through 7 first,
    // then receives bits 8 and 9 from the slave.
    OSERDESE2 #(
        .DATA_RATE_OQ("DDR"),
        .DATA_RATE_TQ("BUF"),
        .DATA_WIDTH(10),
        .SERDES_MODE("MASTER"),
        .TRISTATE_WIDTH(1)
    ) serializer_master (
        .OQ(serial_data),
        .OFB(),
        .TQ(),
        .TFB(),
        .SHIFTOUT1(),
        .SHIFTOUT2(),

        .CLK(serial_clk),
        .CLKDIV(pixel_clk),

        .D1(parallel_data[0]),
        .D2(parallel_data[1]),
        .D3(parallel_data[2]),
        .D4(parallel_data[3]),
        .D5(parallel_data[4]),
        .D6(parallel_data[5]),
        .D7(parallel_data[6]),
        .D8(parallel_data[7]),

        .T1(1'b0),
        .T2(1'b0),
        .T3(1'b0),
        .T4(1'b0),
        .TBYTEIN(1'b0),

        .TCE(1'b0),
        .OCE(1'b1),

        .RST(reset),

        .SHIFTIN1(shift_out_1),
        .SHIFTIN2(shift_out_2)
    );

`else

    // Behavioral simulation model.
    // The first bit transmitted is parallel_data[0].
    reg [9:0] shift_register;
    reg [3:0] bit_index;
    reg serial_data_reg;

    assign serial_data = serial_data_reg;

    always @(posedge pixel_clk or posedge reset) begin
        if (reset) begin
            shift_register <= 10'd0;
            bit_index <= 4'd0;
        end
        else begin
            shift_register <= parallel_data;
            bit_index <= 4'd0;
        end
    end

    // Both edges of serial_clk transmit one bit.
    always @(serial_clk or posedge reset) begin
        if (reset) begin
            serial_data_reg <= 1'b0;
            bit_index <= 4'd0;
        end
        else begin
            serial_data_reg <= shift_register[bit_index];

            if (bit_index == 4'd9)
                bit_index <= 4'd0;
            else
                bit_index <= bit_index + 4'd1;
        end
    end

`endif

endmodule
