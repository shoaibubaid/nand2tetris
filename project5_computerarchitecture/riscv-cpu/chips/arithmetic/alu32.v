
module alu32(
    input wire [31:0] x,
    input wire [31:0] y,
    input wire [3:0] alu_control,

    output reg [31:0] out,
    output wire zero
);

    always @(*) begin

        case (alu_control)

            // ADD
            4'b0000:
                out = x + y;

            // SUB
            4'b0001:
                out = x - y;

            // AND
            4'b0010:
                out = x & y;

            // OR
            4'b0011:
                out = x | y;

            // XOR
            4'b0100:
                out = x ^ y;

            // Shift left logical
            4'b0101:
                out = x << y[4:0];

            // Shift right logical
            4'b0110:
                out = x >> y[4:0];

            // Shift right arithmetic
            4'b0111:
                out = $signed(x) >>> y[4:0];

            // Set less than (signed)
            4'b1000:
                out = ($signed(x) < $signed(y)) ? 32'd1 : 32'd0;

            // Set less than (unsigned)
            4'b1001:
                out = (x < y) ? 32'd1 : 32'd0;

            default:
                out = 32'b0;

        endcase

    end 

    assign zero = (out == 32'b0);

endmodule
