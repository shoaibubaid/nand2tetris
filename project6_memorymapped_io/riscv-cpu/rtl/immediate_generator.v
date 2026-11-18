// Take a 32-bit instruction, extract its immediate value, and 
// produce a 32-bit signed value that the ALU or PC logic can use.
// But RISC-V has an interesting design: 
// immediate values are stored in different bit positions 
// depending on the instruction format. eg. B-Type instructions.

// Immediate generator is shown as sign extend in the diagram.

// An immediate value is a constant number written directly 
// inside an assembly instruction, 
// rather than being stored in a register.


module immediate_generator(
    input wire [31:0] instruction,
    input wire [2:0] imm_src,
    output reg [31:0] immediate
);

    always @(*) begin

        case (imm_src)

            // I-type: ADDI, LW, JALR, etc.
            3'b000: begin
                immediate = {
                    {20{instruction[31]}},
                    instruction[31:20]
                };
            end

            // S-type: SW, etc.
            3'b001: begin
                immediate = {
                    {20{instruction[31]}},
                    instruction[31:25],
                    instruction[11:7]
                };
            end

            // B-type: BEQ, BNE, BLT, BGE, etc.
            3'b010: begin
                immediate = {
                    {19{instruction[31]}},
                    instruction[31],
                    instruction[7],
                    instruction[30:25],
                    instruction[11:8],
                    1'b0
                };
            end

            // U-type: LUI, AUIPC
            3'b011: begin
                immediate = {
                    instruction[31:12],
                    12'b0
                };
            end

            // J-type: JAL
            3'b100: begin
                immediate = {
                    {11{instruction[31]}},
                    instruction[31],
                    instruction[19:12],
                    instruction[20],
                    instruction[30:21],
                    1'b0
                };
            end

            // Unsupported or unused format
            default: begin
                immediate = 32'b0;
            end

        endcase

    end

endmodule
