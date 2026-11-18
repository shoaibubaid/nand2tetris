
`timescale 1ns/1ps

module framebuffer (
    input wire clk,
    input wire reset,

    input wire req,
    input wire mem_read,
    input wire mem_write,

    input wire [16:0] offset,
    input wire [31:0] write_data,
    input wire [2:0] funct3,
    input wire [16:0] video_pixel_address,

    output wire ready,
    output reg [31:0] read_data,
    output reg access_error,
    output reg [7:0] video_pixel_data

);

    // 320 * 240 pixels, 1 byte per pixel.
    // 76,800 bytes = 19,200 words.
    localparam NUM_WORDS = 19200;
    localparam NUM_BYTES = 76800;

    reg [31:0] memory [0:NUM_WORDS-1];

    // Controller states
    localparam IDLE  = 2'b00;
    localparam READ  = 2'b01;
    localparam WRITE = 2'b10;
    localparam DONE  = 2'b11;

    reg [1:0] state;

    // Latched request
    reg [14:0] word_index_q;
    reg [1:0] byte_offset_q;
    reg [31:0] write_data_q;
    reg [2:0] funct3_q;

    assign ready = (state == DONE);

    // Check whether an access is supported and aligned.
    function valid_access;
        input [2:0] operation;
        input [16:0] byte_offset;
        input read_en;
        input write_en;

        begin
            valid_access = 1'b0;

            if (read_en && !write_en) begin
                case (operation)
                    3'b000, 3'b100: valid_access = 1'b1; // LB, LBU

                    3'b001, 3'b101:
                        valid_access = (byte_offset[0] == 1'b0); // LH, LHU

                    3'b010:
                        valid_access = (byte_offset[1:0] == 2'b00); // LW

                    default: valid_access = 1'b0;
                endcase
            end
            else if (write_en && !read_en) begin
                case (operation)
                    3'b000: valid_access = 1'b1; // SB

                    3'b001:
                        valid_access = (byte_offset[0] == 1'b0); // SH

                    3'b010:
                        valid_access = (byte_offset[1:0] == 2'b00); // SW

                    default: valid_access = 1'b0;
                endcase
            end
        end
    endfunction

    // Format a 32-bit word into the requested load result.
    function [31:0] format_load;
        input [31:0] word;
        input [1:0] byte_offset;
        input [2:0] operation;

        reg [31:0] shifted;

        begin
            shifted = word >> (byte_offset * 8);

            case (operation)
                3'b000: format_load = {{24{shifted[7]}}, shifted[7:0]};  // LB
                3'b100: format_load = {24'b0, shifted[7:0]};             // LBU
                3'b001: format_load = {{16{shifted[15]}}, shifted[15:0]}; // LH
                3'b101: format_load = {16'b0, shifted[15:0]};             // LHU
                3'b010: format_load = word;                               // LW

                default: format_load = 32'b0;
            endcase
        end
    endfunction

    // Memory controller FSM
    always @(posedge clk) begin
        if (reset) begin
            state <= IDLE;

            word_index_q <= 0;
            byte_offset_q <= 0;
            write_data_q <= 0;
            funct3_q <= 0;

            read_data <= 0;
            access_error <= 0;
        end
        else begin
            case (state)

                IDLE: begin
                    access_error <= 0;

                    if (req) begin

                        // Reject addresses outside the framebuffer.
                        if (offset >= NUM_BYTES) begin
                            access_error <= 1;
                            state <= DONE;
                        end

                        // Reject unsupported or misaligned operations.
                        else if (!valid_access(
                            funct3, offset, mem_read, mem_write
                        )) begin
                            access_error <= 1;
                            state <= DONE;
                        end

                        else begin
                            word_index_q <= offset[16:2];
                            byte_offset_q <= offset[1:0];
                            write_data_q <= write_data;
                            funct3_q <= funct3;

                            if (mem_read)
                                state <= READ;
                            else
                                state <= WRITE;
                        end
                    end
                end

                READ: begin
                    read_data <= format_load(
                        memory[word_index_q],
                        byte_offset_q,
                        funct3_q
                    );

                    state <= DONE;
                end

                WRITE: begin
                    case (funct3_q)

                        // Store byte
                        3'b000: begin
                            case (byte_offset_q)
                                2'b00: memory[word_index_q][7:0]   <= write_data_q[7:0];
                                2'b01: memory[word_index_q][15:8]  <= write_data_q[7:0];
                                2'b10: memory[word_index_q][23:16] <= write_data_q[7:0];
                                2'b11: memory[word_index_q][31:24] <= write_data_q[7:0];
                            endcase
                        end

                        // Store halfword
                        3'b001: begin
                            if (byte_offset_q[1] == 1'b0)
                                memory[word_index_q][15:0] <= write_data_q[15:0];
                            else
                                memory[word_index_q][31:16] <= write_data_q[15:0];
                        end

                        // Store word
                        3'b010: begin
                            memory[word_index_q] <= write_data_q;
                        end

                        default: begin
                            access_error <= 1;
                        end

                    endcase

                    state <= DONE;
                end

                DONE: begin
                    // Keep response valid until requester releases req.
                    if (!req)
                        state <= IDLE;
                end

                default: begin
                    state <= IDLE;
                end

            endcase
        end
    end

    // Independent video read port.
    // One-cycle synchronous read latency.
    always @(posedge clk) begin
        if (reset) begin
            video_pixel_data <= 8'd0;
        end
        else if (video_pixel_address < 17'd76800) begin
            case (video_pixel_address[1:0])
                2'b00:
                    video_pixel_data <= memory[video_pixel_address[16:2]][7:0];

                2'b01:
                    video_pixel_data <= memory[video_pixel_address[16:2]][15:8];

                2'b10:
                    video_pixel_data <= memory[video_pixel_address[16:2]][23:16];

                2'b11:
                    video_pixel_data <= memory[video_pixel_address[16:2]][31:24];
            endcase
        end
        else begin
            video_pixel_data <= 8'd0;
        end
    end

endmodule
