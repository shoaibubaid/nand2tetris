
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

    reg        mem_read_q;
    reg        mem_write_q;
    reg [31:0] address_q;
    reg [31:0] write_data_q;
    reg [2:0]  funct3_q;

    reg [31:0] modified_word;

    // ------------------------------------------------
    // RAM interface
    // ------------------------------------------------

    wire [31:0] ram_out;
    wire [31:0] ram_in;
    wire [11:0] ram_address;
    wire        ram_load;

    assign ram_address = address_q[13:2];
    assign ram_in      = modified_word;

    // RAM writes only during WRITE state
    assign ram_load = (state == WRITE);

    // Existing structural 16 KB RAM
    main_ram main_ram_inst (
        .clk          (clk),
        .address      (ram_address),
        .write_data   (ram_in),
        .write_enable (ram_load),
        .read_data    (ram_out)
    );

    // ------------------------------------------------
    // Handshake
    // ------------------------------------------------

    assign ready = (state == DONE);

    // ------------------------------------------------
    // Load formatting
    // ------------------------------------------------

    function [31:0] format_load;

        input [31:0] word_in;
        input [1:0]  byte_offset;
        input [2:0]  load_funct3;

        reg [31:0] shifted_word;

        begin
            shifted_word = word_in >> (byte_offset * 8);

            case (load_funct3)

                // LB: sign-extend byte
                3'b000:
                    format_load = {
                        {24{shifted_word[7]}},
                        shifted_word[7:0]
                    };

                // LH: sign-extend halfword
                3'b001:
                    format_load = {
                        {16{shifted_word[15]}},
                        shifted_word[15:0]
                    };

                // LW: full word
                3'b010:
                    format_load = word_in;

                // LBU: zero-extend byte
                3'b100:
                    format_load = {
                        24'b0,
                        shifted_word[7:0]
                    };

                // LHU: zero-extend halfword
                3'b101:
                    format_load = {
                        16'b0,
                        shifted_word[15:0]
                    };

                default:
                    format_load = 32'b0;

            endcase
        end

    endfunction

    // ------------------------------------------------
    // Store formatting: read-modify-write
    // ------------------------------------------------

    function [31:0] merge_store;

        input [31:0] old_word;
        input [31:0] new_data;
        input [1:0]  byte_offset;
        input [2:0]  store_funct3;

        reg [31:0] mask;
        reg [31:0] shifted_data;

        begin

            case (store_funct3)

                // SB: modify one byte
                3'b000: begin

                    mask = 32'h000000FF
                           << (byte_offset * 8);

                    shifted_data = (new_data & 32'h000000FF)
                                   << (byte_offset * 8);

                end

                // SH: modify two bytes
                3'b001: begin

                    mask = 32'h0000FFFF
                           << (byte_offset * 8);

                    shifted_data = (new_data & 32'h0000FFFF)
                                   << (byte_offset * 8);

                end

                // SW: replace complete word
                3'b010: begin

                    mask = 32'hFFFFFFFF;
                    shifted_data = new_data;

                end

                default: begin

                    mask = 32'b0;
                    shifted_data = 32'b0;

                end

            endcase

            merge_store = (old_word & ~mask)
                          | (shifted_data & mask);

        end

    endfunction

    // ------------------------------------------------
    // Request validation
    // ------------------------------------------------

    function request_valid;

        input        is_read;
        input        is_write;
        input [31:0] addr;
        input [2:0]  operation;

        begin

            request_valid = 1'b1;

            // Exactly one operation must be requested
            if (is_read == is_write)
                request_valid = 1'b0;

            // 16 KB address range:
            // 0x00000000 - 0x00003FFF
            if (addr[31:14] != 18'b0)
                request_valid = 1'b0;

            if (is_read) begin

                case (operation)

                    // LB
                    // LBU
                    3'b000,
                    3'b100: ;

                    // LH, LHU: halfword alignment
                    3'b001,
                    3'b101: begin
                        if (addr[0] != 1'b0)
                            request_valid = 1'b0;
                    end

                    // LW: word alignment
                    3'b010: begin
                        if (addr[1:0] != 2'b00)
                            request_valid = 1'b0;
                    end

                    default:
                        request_valid = 1'b0;

                endcase

            end
            else if (is_write) begin

                case (operation)

                    // SB
                    3'b000: ;

                    // SH: halfword alignment
                    3'b001: begin
                        if (addr[0] != 1'b0)
                            request_valid = 1'b0;
                    end

                    // SW: word alignment
                    3'b010: begin
                        if (addr[1:0] != 2'b00)
                            request_valid = 1'b0;
                    end

                    default:
                        request_valid = 1'b0;

                endcase

            end

        end

    endfunction

    // ------------------------------------------------
    // Memory controller FSM
    // ------------------------------------------------

    always @(posedge clk) begin

        if (reset) begin

            state         <= IDLE;

            mem_read_q    <= 1'b0;
            mem_write_q   <= 1'b0;

            address_q     <= 32'b0;
            write_data_q  <= 32'b0;
            funct3_q      <= 3'b0;

            modified_word <= 32'b0;
            read_data     <= 32'b0;

            access_error  <= 1'b0;

        end

        else begin

            case (state)

                // ------------------------------------
                // IDLE: accept a new request
                // ------------------------------------

                IDLE: begin

                    access_error <= 1'b0;

                    if (req) begin

                        if (!request_valid(
                            mem_read,
                            mem_write,
                            address,
                            funct3
                        )) begin

                            access_error <= 1'b1;
                            state <= DONE;

                        end

                        else begin

                            mem_read_q   <= mem_read;
                            mem_write_q  <= mem_write;

                            address_q    <= address;
                            write_data_q <= write_data;
                            funct3_q     <= funct3;

                            // SW does not require a read
                            if (mem_write && funct3 == 3'b010) begin

                                modified_word <= write_data;
                                state <= WRITE;

                            end
                            else begin

                                state <= READ;

                            end

                        end

                    end

                end

                // ------------------------------------
                // READ: access existing RAM word
                // ------------------------------------

                READ: begin

                    if (mem_read_q) begin

                        // Load operation
                        read_data <= format_load(
                            ram_out,
                            address_q[1:0],
                            funct3_q
                        );

                        state <= DONE;

                    end

                    else begin

                        // SB / SH:
                        // Read old word and merge new data
                        modified_word <= merge_store(
                            ram_out,
                            write_data_q,
                            address_q[1:0],
                            funct3_q
                        );

                        state <= WRITE;

                    end

                end

                // ------------------------------------
                // WRITE: write complete 32-bit word
                // ------------------------------------

                WRITE: begin

                    // ram_load is HIGH during this state.
                    // The RAM writes at this clock edge.

                    state <= DONE;

                end

                // ------------------------------------
                // DONE: wait for request deassertion
                // ------------------------------------

                DONE: begin

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
