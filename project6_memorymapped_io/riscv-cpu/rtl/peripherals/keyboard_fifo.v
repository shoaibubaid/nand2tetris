
module keyboard_fifo (
    input wire clk,
    input wire reset,

    // Write interface
    input wire push,
    input wire [8:0] data_in,

    // Read interface
    input wire pop,
    output wire [8:0] data_out,

    // Status
    output wire empty,
    output wire full,
    output wire [4:0] count,
    output reg overflow,

    // Clear sticky overflow flag
    input wire clear_overflow
);

    // 16 entries, 9 bits per entry
    reg [8:0] memory [0:15];

    // Circular read and write pointers
    reg [3:0] read_ptr;
    reg [3:0] write_ptr;

    // Number of occupied entries
    reg [4:0] fifo_count;

    wire do_pop;
    wire do_push;

    assign empty = (fifo_count == 0);
    assign full  = (fifo_count == 16);

    assign count = fifo_count;

    // Combinational read: data from oldest entry.
    assign data_out = memory[read_ptr];

    // A pop is accepted only when data exists.
    assign do_pop = pop && !empty;

    // A push is accepted when space exists, or when
    // a simultaneous pop frees a slot.
    assign do_push = push && (!full || do_pop);

    always @(posedge clk) begin
        if (reset) begin
            read_ptr  <= 4'd0;
            write_ptr <= 4'd0;
            fifo_count <= 5'd0;
            overflow <= 1'b0;
        end
        else begin

            // Write new event
            if (do_push) begin
                memory[write_ptr] <= data_in;
                write_ptr <= write_ptr + 4'd1;
            end

            // Advance read pointer
            if (do_pop)
                read_ptr <= read_ptr + 4'd1;

            // Update occupancy
            case ({do_push, do_pop})
                2'b10:
                    fifo_count <= fifo_count + 5'd1;

                2'b01:
                    fifo_count <= fifo_count - 5'd1;

                default:
                    fifo_count <= fifo_count;
            endcase

            // Sticky overflow indication
            if (clear_overflow)
                overflow <= 1'b0;
            else if (push && !do_push)
                overflow <= 1'b1;
        end
    end

endmodule
