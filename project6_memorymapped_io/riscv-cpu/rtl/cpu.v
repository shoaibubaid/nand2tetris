
`timescale 1ns/1ps

module cpu #(
    parameter IMEM_ADDR_WIDTH = 10,
    parameter IMEM_INIT_FILE = "",
    parameter DMEM_BYTES = 4096
)(
    input wire clk,
    input wire reset,

    // Debug outputs
    output wire [31:0] pc_out,
    output wire [31:0] instruction_out,
    output wire instruction_valid,
    output wire cpu_valid
);

    // =====================================================
    // 1. CPU CONTROL FSM
    // =====================================================

    localparam CPU_RUN         = 2'b00;
    localparam CPU_MEM_WAIT    = 2'b01;
    localparam CPU_MEM_RELEASE = 2'b10;

    reg [1:0] cpu_state;

    wire memory_operation;
    wire branch_operation;
    wire alu_operation_valid;
    wire base_valid;

    wire memory_req;
    wire memory_ready;
    wire memory_error;

    wire reg_write_enable;


    // =====================================================
    // 2. PROGRAM COUNTER
    // =====================================================

    reg [31:0] pc;
    wire [31:0] next_pc;

    assign pc_out = pc;

    always @(posedge clk) begin
        if (reset) begin
            pc <= 32'b0;
            cpu_state <= CPU_RUN;
        end
        else begin

            case (cpu_state)

                CPU_RUN: begin

                    if (memory_operation && base_valid) begin
                        // Memory instruction:
                        // Issue request and hold PC.
                        cpu_state <= CPU_MEM_WAIT;
                    end
                    else begin
                        // Normal instruction.
                        pc <= next_pc;
                    end

                end

                CPU_MEM_WAIT: begin

                    if (memory_ready) begin
                        // Memory operation completed.
                        // Advance PC and release request.
                        pc <= next_pc;
                        cpu_state <= CPU_MEM_RELEASE;
                    end

                    // Otherwise, hold PC and wait.
                end

                CPU_MEM_RELEASE: begin

                    // memory_req becomes 0 in this state.
                    // Give memory controller one cycle to return
                    // from DONE to IDLE.
                    cpu_state <= CPU_RUN;

                end

                default: begin
                    cpu_state <= CPU_RUN;
                end

            endcase
        end
    end


    // =====================================================
    // 3. INSTRUCTION MEMORY
    // =====================================================

    wire [31:0] instruction;
    wire imem_valid;

    assign instruction_out = instruction;
    assign instruction_valid = imem_valid;

    instruction_memory #(
        .ADDR_WIDTH(IMEM_ADDR_WIDTH),
        .INIT_FILE(IMEM_INIT_FILE)
    ) imem (
        .address(pc),
        .instruction(instruction),
        .valid(imem_valid)
    );


    // =====================================================
    // 4. INSTRUCTION DECODER
    // =====================================================

    wire [6:0] opcode;
    wire [4:0] rd, rs1, rs2;
    wire [2:0] funct3;
    wire [6:0] funct7;

    instruction_decoder decoder (
        .instruction(instruction),
        .opcode(opcode),
        .rd(rd),
        .funct3(funct3),
        .rs1(rs1),
        .rs2(rs2),
        .funct7(funct7)
    );


    // =====================================================
    // 5. CONTROL UNIT
    // =====================================================

    wire RegWrite;
    wire ALUSrcA, ALUSrcB;
    wire [1:0] ALUOp;
    wire [2:0] ImmSrc;
    wire [1:0] ResultSrc;

    wire MemRead, MemWrite;
    wire Branch, Jump, Jalr;
    wire control_valid;

    control_unit control (
        .opcode(opcode),
        .RegWrite(RegWrite),
        .ALUSrcA(ALUSrcA),
        .ALUSrcB(ALUSrcB),
        .ALUOp(ALUOp),
        .ImmSrc(ImmSrc),
        .ResultSrc(ResultSrc),
        .MemRead(MemRead),
        .MemWrite(MemWrite),
        .Branch(Branch),
        .Jump(Jump),
        .Jalr(Jalr),
        .valid(control_valid)
    );


    // =====================================================
    // 6. REGISTER FILE
    // =====================================================

    wire [31:0] rs1_data;
    wire [31:0] rs2_data;

    wire [31:0] write_back_data;

    register_file registers (
        .clk(clk),
        .rs1(rs1),
        .rs2(rs2),
        .rd(rd),
        .write_data(write_back_data),
        .reg_write(reg_write_enable),
        .read_data1(rs1_data),
        .read_data2(rs2_data)
    );


    // =====================================================
    // 7. IMMEDIATE GENERATOR
    // =====================================================

    wire [31:0] immediate;

    immediate_generator imm_gen (
        .instruction(instruction),
        .imm_src(ImmSrc),
        .immediate(immediate)
    );


    // =====================================================
    // 8. ALU INPUT MULTIPLEXERS
    // =====================================================

    wire [31:0] alu_operand_a;
    wire [31:0] alu_operand_b;

    // ALUSrcA: 0 = register data, 1 = PC
    assign alu_operand_a = ALUSrcA ? pc : rs1_data;

    // ALUSrcB: 0 = rs2 data, 1 = immediate
    assign alu_operand_b = ALUSrcB ? immediate : rs2_data;


    // =====================================================
    // 9. ALU CONTROL
    // =====================================================

    wire [3:0] alu_ctrl;
    wire alu_control_valid;

    alu_control alu_ctrl_unit (
        .ALUOp(ALUOp),
        .funct3(funct3),
        .funct7(funct7),
        .alu_control(alu_ctrl),
        .valid(alu_control_valid)
    );


    // =====================================================
    // 10. ALU
    // =====================================================

    wire [31:0] alu_result;

    alu32 alu (
        .x(alu_operand_a),
        .y(alu_operand_b),
        .alu_control(alu_ctrl),
        .out(alu_result),
        .zero()
    );


    // =====================================================
    // 11. BRANCH UNIT
    // =====================================================

    wire branch_taken;
    wire branch_valid;

    branch_unit branch (
        .Branch(Branch),
        .funct3(funct3),
        .rs1_data(rs1_data),
        .rs2_data(rs2_data),
        .branch_taken(branch_taken),
        .valid(branch_valid)
    );


    // =====================================================
    // 12. MEMORY SUBSYSTEM
    // =====================================================

    wire [31:0] memory_read_data;

    assign memory_operation = MemRead || MemWrite;

    // A memory request is asserted in RUN and remains
    // asserted while the CPU waits for completion.
    assign memory_req =
        !reset &&
        (
            (cpu_state == CPU_RUN &&
             memory_operation &&
             base_valid)
            ||
            (cpu_state == CPU_MEM_WAIT)
        );

    // Unified memory subsystem:
    // RAM + Framebuffer + Keyboard + Timer.
    memory_subsystem dmem (
        .clk(clk),
        .reset(reset),

        .req(memory_req),
        .mem_read(MemRead),
        .mem_write(MemWrite),
        .address(alu_result),
        .write_data(rs2_data),
        .funct3(funct3),

        .ready(memory_ready),
        .read_data(memory_read_data),
        .access_error(memory_error)
    );


    // =====================================================
    // 13. WRITE-BACK MULTIPLEXER
    // =====================================================

    // ResultSrc:
    // 00 = ALU result
    // 01 = Data memory result
    // 10 = PC + 4

    reg [31:0] write_back_mux;

    always @(*) begin

        case (ResultSrc)

            2'b00:
                write_back_mux = alu_result;

            2'b01:
                write_back_mux = memory_read_data;

            2'b10:
                write_back_mux = pc + 32'd4;

            default:
                write_back_mux = 32'b0;

        endcase

    end

    assign write_back_data = write_back_mux;


    // =====================================================
    // 14. NEXT PC LOGIC
    // =====================================================

    next_pc_logic pc_logic (
        .pc(pc),
        .immediate(immediate),
        .rs1_data(rs1_data),
        .branch_taken(branch_taken && branch_valid),
        .Jump(Jump),
        .Jalr(Jalr),
        .next_pc(next_pc)
    );


    // =====================================================
    // 15. INSTRUCTION VALIDITY AND REGISTER WRITE CONTROL
    // =====================================================

    assign branch_operation = Branch;

    // Branch comparisons are handled by branch_unit.
    // Other instructions require valid ALU control.
    assign alu_operation_valid =
        branch_operation ? 1'b1 : alu_control_valid;

    // Validity of the instruction itself.
    // Does not depend on memory completion.
    assign base_valid =
        imem_valid &&
        control_valid &&
        alu_operation_valid &&
        (!branch_operation || branch_valid);

    // An instruction is complete when:
    // 1. It is a non-memory instruction in RUN.
    // 2. It is a memory instruction in WAIT and ready is asserted.

    assign cpu_valid =
        base_valid &&
        (
            (!memory_operation &&
             cpu_state == CPU_RUN)

            ||

            (memory_operation &&
             cpu_state == CPU_MEM_WAIT &&
             memory_ready &&
             !memory_error)
        );

    // Register file writes only when an instruction
    // completes successfully.
    assign reg_write_enable =
        RegWrite &&
        cpu_valid &&
        !reset;

endmodule
