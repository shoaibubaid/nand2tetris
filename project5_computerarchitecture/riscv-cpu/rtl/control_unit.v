
module control_unit(
    input wire [6:0] opcode,

    output reg RegWrite,
    output reg ALUSrcA,
    output reg ALUSrcB,

    output reg [1:0] ALUOp,
    output reg [2:0] ImmSrc,
    output reg [1:0] ResultSrc,

    output reg MemRead,
    output reg MemWrite,

    output reg Branch,
    output reg Jump,
    output reg Jalr,

    output reg valid
);

    // RV32I opcode definitions
    localparam OP_R_TYPE = 7'b0110011;
    localparam OP_I_TYPE = 7'b0010011;
    localparam OP_LOAD   = 7'b0000011;
    localparam OP_STORE  = 7'b0100011;
    localparam OP_BRANCH = 7'b1100011;
    localparam OP_LUI    = 7'b0110111;
    localparam OP_AUIPC  = 7'b0010111;
    localparam OP_JAL    = 7'b1101111;
    localparam OP_JALR   = 7'b1100111;

    // Immediate format definitions
    localparam IMM_I = 3'b000;
    localparam IMM_S = 3'b001;
    localparam IMM_B = 3'b010;
    localparam IMM_U = 3'b011;
    localparam IMM_J = 3'b100;

    // ALU operation category definitions
    localparam ALU_ADDR = 2'b00;
    localparam ALU_BR   = 2'b01;
    localparam ALU_REG  = 2'b10;
    localparam ALU_IMM  = 2'b11;

    // Write-back source definitions
    localparam RESULT_ALU  = 2'b00;
    localparam RESULT_MEM  = 2'b01;
    localparam RESULT_PC4  = 2'b10;

    always @(*) begin

        // Safe default values
        RegWrite = 1'b0;
        ALUSrcA  = 1'b0;
        ALUSrcB  = 1'b0;

        ALUOp    = ALU_ADDR;
        ImmSrc   = IMM_I;
        ResultSrc = RESULT_ALU;

        MemRead  = 1'b0;
        MemWrite = 1'b0;

        Branch = 1'b0;
        Jump   = 1'b0;
        Jalr   = 1'b0;

        valid = 1'b0;

        case (opcode)

            // R-type: ADD, SUB, AND, OR, etc.
            OP_R_TYPE: begin
                RegWrite = 1'b1;
                ALUSrcA  = 1'b0;
                ALUSrcB  = 1'b0;
                ALUOp    = ALU_REG;

                valid = 1'b1;
            end

            // I-type arithmetic: ADDI, ANDI, ORI, etc.
            OP_I_TYPE: begin
                RegWrite = 1'b1;
                ALUSrcA  = 1'b0;
                ALUSrcB  = 1'b1;
                ALUOp    = ALU_IMM;
                ImmSrc   = IMM_I;

                valid = 1'b1;
            end

            // Load: LB, LH, LW, LBU, LHU
            OP_LOAD: begin
                RegWrite = 1'b1;
                ALUSrcA  = 1'b0;
                ALUSrcB  = 1'b1;
                ALUOp    = ALU_ADDR;
                ImmSrc   = IMM_I;

                MemRead  = 1'b1;
                ResultSrc = RESULT_MEM;

                valid = 1'b1;
            end

            // Store: SB, SH, SW
            OP_STORE: begin
                RegWrite = 1'b0;
                ALUSrcA  = 1'b0;
                ALUSrcB  = 1'b1;
                ALUOp    = ALU_ADDR;
                ImmSrc   = IMM_S;

                MemWrite = 1'b1;

                valid = 1'b1;
            end

            // Conditional branches
            OP_BRANCH: begin
                RegWrite = 1'b0;
                ALUSrcA  = 1'b0;
                ALUSrcB  = 1'b0;
                ALUOp    = ALU_BR;
                ImmSrc   = IMM_B;

                Branch = 1'b1;

                valid = 1'b1;
            end

            // LUI: rd = upper immediate
            OP_LUI: begin
                RegWrite = 1'b1;
                ALUSrcA  = 1'b0;  // rs1 is x0
                ALUSrcB  = 1'b1;
                ALUOp    = ALU_ADDR;
                ImmSrc   = IMM_U;

                valid = 1'b1;
            end

            // AUIPC: rd = PC + upper immediate
            OP_AUIPC: begin
                RegWrite = 1'b1;
                ALUSrcA  = 1'b1;  // Select PC
                ALUSrcB  = 1'b1;
                ALUOp    = ALU_ADDR;
                ImmSrc   = IMM_U;

                valid = 1'b1;
            end

            // JAL: rd = PC + 4, PC = PC + immediate
            OP_JAL: begin
                RegWrite = 1'b1;
                ImmSrc   = IMM_J;
                ResultSrc = RESULT_PC4;

                Jump = 1'b1;

                valid = 1'b1;
            end

            // JALR: rd = PC + 4, PC = (rs1 + immediate) & ~1
            OP_JALR: begin
                RegWrite = 1'b1;
                ALUSrcA  = 1'b0;
                ALUSrcB  = 1'b1;
                ALUOp    = ALU_ADDR;
                ImmSrc   = IMM_I;
                ResultSrc = RESULT_PC4;

                Jalr = 1'b1;

                valid = 1'b1;
            end

            default: begin
                // Unsupported opcode.
                // Keep all safe default values.
                valid = 1'b0;
            end

        endcase
    end

endmodule
