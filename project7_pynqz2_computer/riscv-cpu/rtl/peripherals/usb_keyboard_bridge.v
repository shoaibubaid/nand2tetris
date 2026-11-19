
module usb_keyboard_bridge (
    // Processing-system clock domain
    input wire ps_clk,
    input wire ps_reset,

    input wire ps_event_valid,
    output wire ps_event_ready,
    input wire [8:0] ps_event_data,

    // RISC-V peripheral clock domain
    input wire cpu_clk,
    input wire cpu_reset,

    output reg cpu_event_valid,
    input wire cpu_event_ready,
    output reg [8:0] cpu_event_data
);

    // Request toggle: PS -> CPU
    reg request_toggle;

    // Acknowledge toggle: CPU -> PS
    reg acknowledge_toggle;

    // Synchronizers
    reg ack_sync_1;
    reg ack_sync_2;

    reg req_sync_1;
    reg req_sync_2;

    // Source-side holding register
    reg [8:0] held_event_data;

    // PS can send a new event when the previous event
    // has been acknowledged.
    assign ps_event_ready =
        (request_toggle == ack_sync_2);

    // ------------------------------------------------
    // PS clock domain
    // ------------------------------------------------

    always @(posedge ps_clk) begin
        if (ps_reset) begin
            request_toggle <= 1'b0;
            held_event_data <= 9'd0;

            ack_sync_1 <= 1'b0;
            ack_sync_2 <= 1'b0;
        end
        else begin

            // Synchronize acknowledgement from CPU domain.
            ack_sync_1 <= acknowledge_toggle;
            ack_sync_2 <= ack_sync_1;

            // Capture a new event and toggle request.
            if (ps_event_valid && ps_event_ready) begin
                held_event_data <= ps_event_data;
                request_toggle <= ~request_toggle;
            end
        end
    end

    // ------------------------------------------------
    // CPU clock domain
    // ------------------------------------------------

    always @(posedge cpu_clk) begin
        if (cpu_reset) begin
            req_sync_1 <= 1'b0;
            req_sync_2 <= 1'b0;

            acknowledge_toggle <= 1'b0;

            cpu_event_valid <= 1'b0;
            cpu_event_data <= 9'd0;
        end
        else begin

            // Synchronize request from PS domain.
            req_sync_1 <= request_toggle;
            req_sync_2 <= req_sync_1;

            // New request received.
            if (!cpu_event_valid &&
                (req_sync_2 != acknowledge_toggle)) begin

                // Data has remained stable during CDC.
                cpu_event_data <= held_event_data;
                cpu_event_valid <= 1'b1;
            end

            // Consumer accepted the event.
            else if (cpu_event_valid && cpu_event_ready) begin

                cpu_event_valid <= 1'b0;

                // Acknowledge this request.
                acknowledge_toggle <= req_sync_2;
            end
        end
    end

endmodule
