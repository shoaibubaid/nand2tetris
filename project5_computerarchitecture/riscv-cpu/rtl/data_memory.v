// Handles loads and stores
module data_memory #(
    parameter MEM_BYTES = 4096
)(
    input wire clk,

    input wire [31:0] address,
    input wire [31:0] write_data,
    input wire [2:0] funct3,

    input wire MemRead,
    input wire MemWrite,

    output reg [31:0] read_data,
    output reg access_valid
);

    // Byte-addressed memory
    reg [7:0] memory [0:MEM_BYTES-1]; // 4096 locations each of size 8bit

    integer i;
    reg operation_supported;

    // Initialize memory to zero
    initial begin
        for (i = 0; i < MEM_BYTES; i = i + 1)
            memory[i] = 8'b0;
    end

    // Combinational read and access validation
    always @(*) begin

        read_data = 32'b0;
        access_valid = 1'b0;
        operation_supported = 1'b0;

        // Both read and write cannot be active simultaneously
        if (MemRead ^ MemWrite) begin

            // Check supported access type
            if (MemRead) begin
                case (funct3)
                    3'b000, // LB
                    3'b001, // LH
                    3'b010, // LW
                    3'b100, // LBU
                    3'b101: // LHU
                        operation_supported = 1'b1;

                    default:
                        operation_supported = 1'b0;
                endcase
            end
            else begin
                case (funct3)
                    3'b000, // SB
                    3'b001, // SH
                    3'b010: // SW
                        operation_supported = 1'b1;

                    default:
                        operation_supported = 1'b0;
                endcase
            end

            // Check address range and alignment
            if (operation_supported) begin

                case (funct3)

                    // Byte access: any byte address is valid
                    3'b000, 3'b100: begin
                        if (address < MEM_BYTES)
                            access_valid = 1'b1;
                    end

                    // Halfword access: 2-byte aligned
                    3'b001, 3'b101: begin
                        if ((address[0] == 1'b0) &&
                            (address < MEM_BYTES - 1))
                            access_valid = 1'b1;
                    end

                    // Word access: 4-byte aligned
                    3'b010: begin
                        if ((address[1:0] == 2'b00) &&
                            (address < MEM_BYTES - 3))
                            access_valid = 1'b1;
                    end

                    default:
                        access_valid = 1'b0;

                endcase
            end

            // Perform read if requested and valid
            if (MemRead && access_valid) begin

                case (funct3)

                    // LB: Load signed byte
                    3'b000: begin
                        read_data = {
                            {24{memory[address][7]}},
                            memory[address]
                        };
                    end

                    // LH: Load signed halfword
                    3'b001: begin
                        read_data = {
                            {16{memory[address + 1][7]}},
                            memory[address + 1],
                            memory[address]
                        };
                    end

                    // LW: Load word
                    3'b010: begin
                        read_data = {
                            memory[address + 3],
                            memory[address + 2],
                            memory[address + 1],
                            memory[address]
                        };
                    end

                    // LBU: Load unsigned byte
                    3'b100: begin
                        read_data = {
                            24'b0,
                            memory[address]
                        };
                    end

                    // LHU: Load unsigned halfword
                    3'b101: begin
                        read_data = {
                            16'b0,
                            memory[address + 1],
                            memory[address]
                        };
                    end

                    default:
                        read_data = 32'b0;

                endcase
            end
        end
    end

    // Synchronous write
    always @(posedge clk) begin

        if (MemWrite && access_valid) begin

            case (funct3)

                // SB: Store byte
                3'b000: begin
                    memory[address] <= write_data[7:0];
                end

                // SH: Store halfword
                3'b001: begin
                    memory[address]     <= write_data[7:0];
                    memory[address + 1] <= write_data[15:8];
                end

                // SW: Store word
                3'b010: begin
                    memory[address]     <= write_data[7:0];
                    memory[address + 1] <= write_data[15:8];
                    memory[address + 2] <= write_data[23:16];
                    memory[address + 3] <= write_data[31:24];
                end

                default: begin
                    // Unsupported store: do nothing
                end

            endcase
        end
    end

endmodule
