// Evaluates branch conditions

module branch_unit(
    input wire Branch,
    input wire [2:0] funct3,

    input wire [31:0] rs1_data,
    input wire [31:0] rs2_data,

    output reg branch_taken,
    output reg valid
);

    always @(*) begin

        // Default values
        branch_taken = 1'b0;
        valid = 1'b0;

        if (Branch) begin

            case (funct3)

                // BEQ: Branch if equal
                3'b000: begin
                    branch_taken = (rs1_data == rs2_data);
                    valid = 1'b1;
                end

                // BNE: Branch if not equal
                3'b001: begin
                    branch_taken = (rs1_data != rs2_data);
                    valid = 1'b1;
                end

                // BLT: Branch if less than (signed)
                3'b100: begin
                    branch_taken =
                        ($signed(rs1_data) < $signed(rs2_data));
                    valid = 1'b1;
                end

                // BGE: Branch if greater than or equal (signed)
                3'b101: begin
                    branch_taken =
                        ($signed(rs1_data) >= $signed(rs2_data));
                    valid = 1'b1;
                end

                // BLTU: Branch if less than (unsigned)
                3'b110: begin
                    branch_taken = (rs1_data < rs2_data);
                    valid = 1'b1;
                end

                // BGEU: Branch if greater than or equal (unsigned)
                3'b111: begin
                    branch_taken = (rs1_data >= rs2_data);
                    valid = 1'b1;
                end

                default: begin
                    branch_taken = 1'b0;
                    valid = 1'b0;
                end

            endcase
        end

    end

endmodule
