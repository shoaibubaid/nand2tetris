// Determines the next PC
module next_pc_logic(
    input wire [31:0] pc,
    input wire [31:0] immediate,
    input wire [31:0] rs1_data,

    input wire branch_taken,
    input wire Jump,
    input wire Jalr,

    output reg [31:0] next_pc
);

    always @(*) begin
        // Default: execute the next sequential instruction
        next_pc = pc + 32'd4;

        // JALR: target = (rs1 + immediate), with bit 0 cleared
        if (Jalr) begin
            next_pc = (rs1_data + immediate) & 32'hFFFFFFFE;
        end

        // JAL: target = PC + immediate
        else if (Jump) begin
            next_pc = pc + immediate;
        end

        // Conditional branch: target = PC + immediate
        else if (branch_taken) begin
            next_pc = pc + immediate;
        end
    end

endmodule