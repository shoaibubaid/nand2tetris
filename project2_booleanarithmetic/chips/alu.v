
module alu(
    input wire [15:0] x,
    input wire [15:0] y,

    input wire zx,
    input wire nx,
    input wire zy,
    input wire ny,
    input wire f,
    input wire no,

    output reg [15:0] out,
    output reg zr,
    output reg ng
);

    reg [15:0] x1;
    reg [15:0] y1;
    reg [15:0] result;

    always @(*) begin

        // Step 1: Zero x if requested
        if (zx == 1)
            x1 = 16'b0000000000000000;
        else
            x1 = x;

        // Step 2: Negate x if requested
        if (nx == 1)
            x1 = ~x1;

        // Step 3: Zero y if requested
        if (zy == 1)
            y1 = 16'b0000000000000000;
        else
            y1 = y;

        // Step 4: Negate y if requested
        if (ny == 1)
            y1 = ~y1;

        // Step 5: Perform AND or addition
        if (f == 1)
            result = x1 + y1;
        else
            result = x1 & y1;

        // Step 6: Negate output if requested
        if (no == 1)
            result = ~result;

        // Step 7: Assign final output
        out = result;

        // Step 8: Zero flag
        zr = (out == 16'b0000000000000000);

        // Step 9: Negative flag
        ng = out[15];

    end

endmodule
