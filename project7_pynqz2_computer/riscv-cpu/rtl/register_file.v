
module register_file(
    input wire clk,

    // Read register addresses
    input wire [4:0] rs1,
    input wire [4:0] rs2,

    // Write register address and data
    input wire [4:0] rd,
    input wire [31:0] write_data,

    // Write enable
    input wire reg_write,

    // Read outputs
    output wire [31:0] read_data1,
    output wire [31:0] read_data2
);

    // 32 registers, each 32 bits wide
    reg [31:0] registers [0:31];

    // Write operation (synchronous)
    always @(posedge clk) begin
        if (reg_write && (rd != 5'd0)) begin
            registers[rd] <= write_data;
        end
    end

    // Read operations (asynchronous)
    assign read_data1 = (rs1 == 5'd0) ? 32'd0 : registers[rs1];
    assign read_data2 = (rs2 == 5'd0) ? 32'd0 : registers[rs2];

endmodule


// Signal	    Width	Purpose
// clk	        1	    Clock
// rs1	        5	    Address of first source register
// rs2	        5	    Address of second source register
// rd	        5	    Address of destination register
// write_data	32	    Data to write
// reg_write	1	    Enables writing
// read_data1	32	    Value stored in rs1
// read_data2	32	    Value stored in rs2