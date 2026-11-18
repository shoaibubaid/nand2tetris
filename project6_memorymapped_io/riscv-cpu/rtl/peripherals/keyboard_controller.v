
module keyboard_controller (
    input wire clk,
    input wire reset,

    // Incoming event from USB keyboard bridge
    input wire       event_valid,
    output wire      event_ready,
    input wire [8:0] event_data,

    // CPU MMIO interface
    input wire        req,
    input wire        mem_read,
    input wire        mem_write,
    input wire [3:0]  offset,
    input wire [31:0] write_data,
    input wire [2:0]  funct3,

    output wire       ready,
    output reg [31:0] read_data,
    output reg        access_error
);

    localparam KEY_DATA   = 4'h0;
    localparam KEY_STATUS = 4'h4;

    localparam IDLE = 1'b0;
    localparam DONE = 1'b1;

    reg state;

    // FIFO signals
    wire [8:0] fifo_data;
    wire fifo_empty;
    wire fifo_full;
    wire [4:0] fifo_count;
    wire fifo_overflow;

    wire fifo_push;
    wire fifo_pop;
    wire clear_overflow;

    // The bridge waits whenever the FIFO is full.
    assign event_ready = !fifo_full;
    assign fifo_push = event_valid && event_ready;

    // Supported MMIO operations use 32-bit LW/SW.
    wire valid_word_access;
    assign valid_word_access = (funct3 == 3'b010);

    wire read_data_request;
    wire write_status_request;

    assign read_data_request =
        (state == IDLE) &&
        req &&
        mem_read &&
        !mem_write &&
        valid_word_access &&
        (offset == KEY_DATA);

    // Reading KEY_DATA removes exactly one event.
    assign fifo_pop = read_data_request && !fifo_empty;

    assign write_status_request =
        (state == IDLE) &&
        req &&
        !mem_read &&
        mem_write &&
        valid_word_access &&
        (offset == KEY_STATUS);

    assign clear_overflow =
        write_status_request && write_data[1];

    keyboard_fifo fifo (
        .clk(clk),
        .reset(reset),

        .push(fifo_push),
        .data_in(event_data),

        .pop(fifo_pop),
        .data_out(fifo_data),

        .empty(fifo_empty),
        .full(fifo_full),
        .count(fifo_count),
        .overflow(fifo_overflow),

        .clear_overflow(clear_overflow)
    );

    // The response remains asserted until req drops.
    assign ready = (state == DONE);

    always @(posedge clk) begin
        if (reset) begin
            state <= IDLE;
            read_data <= 32'd0;
            access_error <= 1'b0;
        end
        else begin
            case (state)

                IDLE: begin
                    if (req) begin
                        read_data <= 32'd0;
                        access_error <= 1'b0;

                        // Require exactly one operation.
                        if (mem_read == mem_write ||
                            !valid_word_access) begin
                            access_error <= 1'b1;
                        end

                        else if (mem_read) begin
                            case (offset)

                                KEY_DATA: begin
                                    if (!fifo_empty)
                                        read_data <=
                                            {23'd0, fifo_data};
                                    else
                                        read_data <= 32'd0;
                                end

                                KEY_STATUS: begin
                                    read_data <= {
                                        24'd0,
                                        1'b0,
                                        fifo_count,
                                        fifo_overflow,
                                        !fifo_empty
                                    };
                                end

                                default: begin
                                    access_error <= 1'b1;
                                end
                            endcase
                        end

                        else if (mem_write) begin
                            case (offset)

                                KEY_STATUS: begin
                                    // Overflow clear is performed
                                    // by the combinational signal.
                                end

                                default: begin
                                    access_error <= 1'b1;
                                end
                            endcase
                        end

                        state <= DONE;
                    end
                end

                DONE: begin
                    // Prevent repeated FIFO pops while
                    // the CPU holds its request high.
                    if (!req)
                        state <= IDLE;
                end

            endcase
        end
    end

endmodule
