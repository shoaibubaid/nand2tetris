// Determines the ALU operation


module alu_control(
    input wire [1:0] ALUOp,     // a signal from the main control unit indicating the general operation category.
    input wire [2:0] funct3,    // fields extracted by the instruction decoder.
    input wire [6:0] funct7,    // fields extracted by the instruction decoder.

    output reg [3:0] alu_control,
    output reg valid
);

    // ALU operation encodings
    localparam ADD  = 4'b0000;
    localparam SUB  = 4'b0001;
    localparam AND  = 4'b0010;
    localparam OR   = 4'b0011;
    localparam XOR  = 4'b0100;
    localparam SLL  = 4'b0101;
    localparam SRL  = 4'b0110;
    localparam SRA  = 4'b0111;
    localparam SLT  = 4'b1000;
    localparam SLTU = 4'b1001;

    always @(*) begin

        // Safe defaults
        alu_control = ADD;
        valid = 1'b0;

        case (ALUOp)

            // Address calculation
            2'b00: begin
                alu_control = ADD;
                valid = 1'b1;
            end

            // Branch comparison
            2'b01: begin
                case (funct3)

                    3'b000, 3'b001: begin
                        alu_control = SUB;  // BEQ, BNE
                        valid = 1'b1;
                    end

                    3'b100, 3'b101: begin
                        alu_control = SLT;  // BLT, BGE
                        valid = 1'b1;
                    end

                    3'b110, 3'b111: begin
                        alu_control = SLTU; // BLTU, BGEU
                        valid = 1'b1;
                    end

                    default: begin
                        alu_control = ADD;
                        valid = 1'b0;
                    end

                endcase
            end

            // R-type instructions
            2'b10: begin
                case (funct3)

                    3'b000: begin
                        if (funct7 == 7'b0000000) begin
                            alu_control = ADD;
                            valid = 1'b1;
                        end
                        else if (funct7 == 7'b0100000) begin
                            alu_control = SUB;
                            valid = 1'b1;
                        end
                    end

                    3'b001: begin
                        if (funct7 == 7'b0000000) begin
                            alu_control = SLL;
                            valid = 1'b1;
                        end
                    end

                    3'b010: begin
                        if (funct7 == 7'b0000000) begin
                            alu_control = SLT;
                            valid = 1'b1;
                        end
                    end

                    3'b011: begin
                        if (funct7 == 7'b0000000) begin
                            alu_control = SLTU;
                            valid = 1'b1;
                        end
                    end

                    3'b100: begin
                        if (funct7 == 7'b0000000) begin
                            alu_control = XOR;
                            valid = 1'b1;
                        end
                    end

                    3'b101: begin
                        if (funct7 == 7'b0000000) begin
                            alu_control = SRL;
                            valid = 1'b1;
                        end
                        else if (funct7 == 7'b0100000) begin
                            alu_control = SRA;
                            valid = 1'b1;
                        end
                    end

                    3'b110: begin
                        if (funct7 == 7'b0000000) begin
                            alu_control = OR;
                            valid = 1'b1;
                        end
                    end

                    3'b111: begin
                        if (funct7 == 7'b0000000) begin
                            alu_control = AND;
                            valid = 1'b1;
                        end
                    end

                endcase
            end

            // I-type arithmetic/logical instructions
            2'b11: begin
                case (funct3)

                    3'b000: begin
                        alu_control = ADD;  // ADDI
                        valid = 1'b1;
                    end

                    3'b010: begin
                        alu_control = SLT;  // SLTI
                        valid = 1'b1;
                    end

                    3'b011: begin
                        alu_control = SLTU; // SLTIU
                        valid = 1'b1;
                    end

                    3'b100: begin
                        alu_control = XOR;  // XORI
                        valid = 1'b1;
                    end

                    3'b110: begin
                        alu_control = OR;   // ORI
                        valid = 1'b1;
                    end

                    3'b111: begin
                        alu_control = AND;  // ANDI
                        valid = 1'b1;
                    end

                    3'b001: begin
                        if (funct7 == 7'b0000000) begin
                            alu_control = SLL; // SLLI
                            valid = 1'b1;
                        end
                    end

                    3'b101: begin
                        if (funct7 == 7'b0000000) begin
                            alu_control = SRL; // SRLI
                            valid = 1'b1;
                        end
                        else if (funct7 == 7'b0100000) begin
                            alu_control = SRA; // SRAI
                            valid = 1'b1;
                        end
                    end

                endcase
            end

            default: begin
                alu_control = ADD;
                valid = 1'b0;
            end

        endcase
    end

endmodule
