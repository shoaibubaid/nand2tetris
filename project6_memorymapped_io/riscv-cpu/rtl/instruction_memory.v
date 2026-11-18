// Supplies instructions


module instruction_memory #(
    parameter ADDR_WIDTH = 10,
    parameter INIT_FILE = ""
)(
    input wire [31:0] address,
    output reg [31:0] instruction,
    output reg valid
);

    // Number of 32-bit instructions
    localparam DEPTH = (1 << ADDR_WIDTH);

    // NOP = addi x0, x0, 0
    localparam NOP = 32'h00000013;

    // Instruction storage
    reg [31:0] memory [0:DEPTH-1];

    integer i;

    // Initialize memory
    initial begin

        // Fill unused locations with NOP instructions
        for (i = 0; i < DEPTH; i = i + 1)
            memory[i] = NOP;

        // Load program if a hex file is provided
        if (INIT_FILE != "")
            $readmemh(INIT_FILE, memory);

    end

    // Combinational instruction read
    always @(*) begin

        // Check alignment and address range
        if ((address[1:0] != 2'b00) ||
            (|address[31:ADDR_WIDTH+2])) begin // '|' this symbol: It performs an OR operation across all bits and produces one bit.
            
            instruction = NOP;
            valid = 1'b0;

        end
        else begin

            // Convert byte address into word index
            instruction = memory[address[ADDR_WIDTH+1:2]];
            valid = 1'b1;

        end

    end

endmodule
