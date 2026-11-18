
`timescale 1ns/1ps

module data_memory (
    input  wire        clk,
    input  wire        reset,

    // Request interface from CPU
    input  wire        req,
    input  wire        mem_read,
    input  wire        mem_write,
    input  wire [31:0] address,
    input  wire [31:0] write_data,
    input  wire [2:0]  funct3,

    // Response interface to CPU
    output wire        ready,
    output reg  [31:0] read_data,
    output reg         access_error
);

    // ------------------------------------------------
    // FSM states
    // ------------------------------------------------

    localparam IDLE  = 2'b00;
    localparam READ  = 2'b01;
    localparam WRITE = 2'b10;
    localparam DONE  = 2'b11;

    reg [1:0] state;

    // ------------------------------------------------
    // Latched request information
    // ------------------------------------------------

    reg [31:0] address_q;
    reg [31:0] write_data_q;
    reg [2:0]  funct3_q;
    reg        mem_read_q;
    reg        mem_write_q;

    // ------------------------------------------------
    // RAM interface
    // ------------------------------------------------

    wire [31:0] ram_read_data;
    wire [31:0] ram_write_data;
    wire [11:0] ram_address;
    wire        ram_write_enable;

    assign ram_address = address_q[13:2];

    assign ram_write_enable = (state == WRITE);

    main_ram main_ram_inst (
        .clk          (clk),
        .address      (ram_address),
        .write_data   (ram_write_data),
        .write_enable (ram_write_enable),
        .read_data    (ram_read_data)
    );

    // ------------------------------------------------
    // Load formatting
    // ------------------------------------------------

    function [31:0] format_load;
        input [31:0] word;
        input [1:0]  byte_offset;
        input [2:0]  operation;

        reg [31:0] shifted;

        begin
            shifted = word >> (byte_offset * 8);

            case (operation)

                3'b000: // LB
                    format_load = {{24{shifted[7]}}, shifted[7:0]};

                3'b001: // LH
                    format_load = {{16{shifted[15]}}, shifted[15:0]};

                3'b010: // LW
                    format_load = shifted;

                3'b100: // LBU
                    format_load = {24'b0, shifted[7:0]};

                3'b101: // LHU
                    format_load = {16'b0, shifted[15:0]};

                default:
                    format_load = 32'b0;

            endcase
        end
    endfunction

    // ------------------------------------------------
    // Store formatting
    // ------------------------------------------------

    function [31:0] merge_store;
        input [31:0] old_word;
        input [31:0] new_data;
        input [1:0]  byte_offset;
        input [2:0]  operation;

        reg [31:0] mask;
        reg [31:0] shifted_data;

        begin

            case (operation)

                3'b000: begin // SB
                    mask = 32'h000000FF << (byte_offset * 8);
                    shifted_data = new_data << (byte_offset * 8);
                end

                3'b001: begin // SH
                    mask = 32'h0000FFFF << (byte_offset * 8);
                    shifted_data = new_data << (byte_offset * 8);
                end

                3'b010: begin // SW
                    mask = 32'hFFFFFFFF;
                    shifted_data = new_data;
                end

                default: begin
                    mask = 32'b0;
                    shifted_data = 32'b0;
                end

            endcase

            merge_store = (old_word & ~mask) |
                          (shifted_data & mask);
        end
    endfunction

    // Select the value written into RAM.
    // For SB/SH, this combines the old word with the new data.
    // For SW, it simply writes the complete new word.

    assign ram_write_data =
        (funct3_q == 3'b010) ? write_data_q :
        merge_store(
            ram_read_data,
            write_data_q,
            address_q[1:0],
            funct3_q
        );

    // ------------------------------------------------
    // Request validation
    // ------------------------------------------------

    function valid_request;
        input        is_read;
        input        is_write;
        input [31:0] addr;
        input [2:0]  operation;

        begin
            valid_request = 1'b0;

            // Exactly one of read/write must be asserted.
            if (is_read ^ is_write) begin

                // 16 KB address range: 0x00000000 - 0x00003FFF
                if (addr[31:14] == 18'b0) begin

                    if (is_read) begin
                        case (operation)

                            3'b000, 3'b100: // LB, LBU
                                valid_request = 1'b1;

                            3'b001, 3'b101: // LH, LHU
                                valid_request = (addr[0] == 1'b0);

                            3'b010: // LW
                                valid_request = (addr[1:0] == 2'b00);

                            default:
                                valid_request = 1'b0;

                        endcase
                    end

                    else begin
                        case (operation)

                            3'b000: // SB
                                valid_request = 1'b1;

                            3'b001: // SH
                                valid_request = (addr[0] == 1'b0);

                            3'b010: // SW
                                valid_request = (addr[1:0] == 2'b00);

                            default:
                                valid_request = 1'b0;

                        endcase
                    end
                end
            end
        end
    endfunction

    // ------------------------------------------------
    // FSM
    // ------------------------------------------------

    assign ready = (state == DONE);

    always @(posedge clk or posedge reset) begin

        if (reset) begin
            state        <= IDLE;

            address_q    <= 32'b0;
            write_data_q <= 32'b0;
            funct3_q     <= 3'b0;
            mem_read_q   <= 1'b0;
            mem_write_q  <= 1'b0;

            read_data    <= 32'b0;
            access_error <= 1'b0;
        end

        else begin

            case (state)

                // ------------------------------------
                IDLE: begin
                // ------------------------------------

                    if (!req) begin
                        access_error <= 1'b0;
                    end

                    else begin

                        if (!valid_request(
                            mem_read,
                            mem_write,
                            address,
                            funct3
                        )) begin

                            access_error <= 1'b1;
                            state <= DONE;

                        end

                        else begin

                            address_q    <= address;
                            write_data_q <= write_data;
                            funct3_q     <= funct3;
                            mem_read_q   <= mem_read;
                            mem_write_q  <= mem_write;

                            access_error <= 1'b0;

                            if (mem_read)
                                state <= READ;

                            else if (funct3 == 3'b010)
                                state <= WRITE; // SW

                            else
                                state <= READ;  // SB/SH
                        end
                    end
                end

                // ------------------------------------
                READ: begin
                // ------------------------------------

                    if (mem_read_q) begin

                        read_data <= format_load(
                            ram_read_data,
                            address_q[1:0],
                            funct3_q
                        );

                        state <= DONE;

                    end

                    else begin

                        // SB/SH: old RAM word is available.
                        // Next state writes the merged word.
                        state <= WRITE;

                    end
                end

                // ------------------------------------
                WRITE: begin
                // ------------------------------------

                    // RAM writes at this clock edge because
                    // ram_write_enable is asserted in WRITE.

                    state <= DONE;

                end

                // ------------------------------------
                DONE: begin
                // ------------------------------------

                    // Keep ready asserted until CPU releases req.
                    if (!req)
                        state <= IDLE;

                end

                default: begin
                    state <= IDLE;
                end

            endcase
        end
    end

endmodule
