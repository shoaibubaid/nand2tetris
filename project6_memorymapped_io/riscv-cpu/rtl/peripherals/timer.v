
`timescale 1ns/1ps

module timer #(
    parameter integer CLK_HZ = 100_000_000
)(
    input wire clk,
    input wire reset,

    // CPU memory interface
    input wire req,
    input wire mem_read,
    input wire mem_write,
    input wire [3:0] offset,
    input wire [31:0] write_data,
    input wire [2:0] funct3,

    output wire ready,
    output reg [31:0] read_data,
    output reg access_error
);

    // ------------------------------------------------
    // Register offsets
    // ------------------------------------------------

    localparam [3:0] TIME_OFFSET      = 4'h0;
    localparam [3:0] CONTROL_OFFSET   = 4'h4;
    localparam [3:0] PRESCALER_OFFSET = 4'h8;
    localparam [3:0] STATUS_OFFSET    = 4'hC;

    // At least one clock cycle per millisecond.
    localparam [31:0] DEFAULT_PRESCALER =
        (CLK_HZ / 1000 >= 1) ? CLK_HZ / 1000 : 1;

    // ------------------------------------------------
    // Internal registers
    // ------------------------------------------------

    reg [31:0] time_counter;
    reg [31:0] prescaler_counter;
    reg [31:0] prescaler;

    reg timer_enable;
    reg tick_flag;

    // ------------------------------------------------
    // Request FSM
    // ------------------------------------------------

    localparam IDLE = 1'b0;
    localparam DONE = 1'b1;

    reg state;

    assign ready = (state == DONE);

    wire read_request =
        req && mem_read && !mem_write;

    wire write_request =
        req && mem_write && !mem_read;

    wire valid_width = (funct3 == 3'b010);

    wire valid_offset =
        (offset == TIME_OFFSET) ||
        (offset == CONTROL_OFFSET) ||
        (offset == PRESCALER_OFFSET) ||
        (offset == STATUS_OFFSET);

    wire tick_pulse =
        timer_enable &&
        (prescaler_counter >= prescaler - 1'b1);

    // ------------------------------------------------
    // Timer counter and prescaler
    // ------------------------------------------------

    always @(posedge clk) begin
        if (reset) begin
            time_counter      <= 32'd0;
            prescaler_counter <= 32'd0;
            prescaler         <= DEFAULT_PRESCALER;
            timer_enable      <= 1'b0;
            tick_flag         <= 1'b0;
        end
        else begin

            // Generate one millisecond tick.
            if (timer_enable) begin
                if (tick_pulse) begin
                    prescaler_counter <= 32'd0;
                    time_counter <= time_counter + 1'b1;
                    tick_flag <= 1'b1;
                end
                else begin
                    prescaler_counter <= prescaler_counter + 1'b1;
                end
            end

            // Clear the sticky tick flag.
            if (state == IDLE &&
                write_request &&
                valid_width &&
                offset == STATUS_OFFSET &&
                write_data[1]) begin

                tick_flag <= 1'b0;
            end

            // CONTROL register write.
            if (state == IDLE &&
                write_request &&
                valid_width &&
                offset == CONTROL_OFFSET) begin

                timer_enable <= write_data[0];

                if (write_data[1]) begin
                    time_counter <= 32'd0;
                    prescaler_counter <= 32'd0;
                    tick_flag <= 1'b0;
                end
            end

            // PRESCALER register write.
            if (state == IDLE &&
                write_request &&
                valid_width &&
                offset == PRESCALER_OFFSET) begin

                if (write_data != 32'd0) begin
                    prescaler <= write_data;
                    prescaler_counter <= 32'd0;
                end
            end
        end
    end

    // ------------------------------------------------
    // Bus transaction controller
    // ------------------------------------------------

    always @(posedge clk) begin
        if (reset) begin
            state <= IDLE;
            read_data <= 32'd0;
            access_error <= 1'b0;
        end
        else begin

            case (state)

                IDLE: begin
                    access_error <= 1'b0;

                    if (req) begin

                        if ((mem_read == mem_write) ||
                            !valid_width ||
                            !valid_offset ||
                            (offset[1:0] != 2'b00)) begin

                            read_data <= 32'd0;
                            access_error <= 1'b1;
                        end
                        else if (read_request) begin

                            case (offset)

                                TIME_OFFSET:
                                    read_data <= time_counter;

                                CONTROL_OFFSET:
                                    read_data <= {
                                        30'd0,
                                        1'b0,
                                        timer_enable
                                    };

                                PRESCALER_OFFSET:
                                    read_data <= prescaler;

                                STATUS_OFFSET:
                                    read_data <= {
                                        30'd0,
                                        tick_flag,
                                        timer_enable
                                    };

                                default:
                                    read_data <= 32'd0;

                            endcase
                        end
                        else if (write_request) begin

                            // TIME is read-only.
                            if (offset == TIME_OFFSET) begin
                                access_error <= 1'b1;
                            end
                            // Zero is not a valid prescaler.
                            else if (offset == PRESCALER_OFFSET &&
                                     write_data == 32'd0) begin
                                access_error <= 1'b1;
                            end
                            else begin
                                access_error <= 1'b0;
                            end
                        end

                        state <= DONE;
                    end
                end

                DONE: begin
                    if (!req) begin
                        state <= IDLE;
                    end
                end

                default: begin
                    state <= IDLE;
                end

            endcase
        end
    end

endmodule
