
module tmds_encoder (
    input  wire       pixel_clk,
    input  wire       reset,

    input  wire       video_enable,
    input  wire [7:0] video_data,

    input  wire       control_0,
    input  wire       control_1,

    output reg  [9:0] tmds_symbol
);

    // Running disparity.
    // Positive means more ones have been transmitted.
    // Negative means more zeros have been transmitted.
    reg signed [5:0] disparity;

    reg [8:0] q_m;

    integer ones_count;
    integer i;

    reg use_xor;

    reg signed [5:0] balance;
    reg signed [5:0] next_disparity;
    reg [9:0] next_symbol;

    // Stage 1: transition-minimized 9-bit intermediate code.
    always @(*) begin
        ones_count = 0;

        for (i = 0; i < 8; i = i + 1)
            ones_count = ones_count + video_data[i];

        use_xor = (ones_count < 4) ||
                  ((ones_count == 4) && video_data[0]);

        q_m[0] = video_data[0];

        for (i = 1; i < 8; i = i + 1)
            q_m[i] = q_m[i-1] ^ video_data[i] ^ !use_xor;

        q_m[8] = use_xor;

    end

    // Stage 2: DC-balanced 10-bit output.
    always @(*) begin
        balance = 6'sd0;

        for (i = 0; i < 8; i = i + 1)
            balance = balance + (q_m[i] ? 6'sd1 : -6'sd1);

        next_symbol = 10'b0;
        next_disparity = disparity;

        if (!video_enable) begin

            // HDMI control symbols.
            case ({control_1, control_0})
                2'b00: next_symbol = 10'b1101010100;
                2'b01: next_symbol = 10'b0010101011;
                2'b10: next_symbol = 10'b0101010100;
                2'b11: next_symbol = 10'b1010101011;
            endcase

            next_disparity = 6'sd0;

        end
        else if ((disparity == 0) || (balance == 0)) begin

            next_symbol[9]   = !q_m[8];
            next_symbol[8]   = q_m[8];
            next_symbol[7:0] = q_m[8] ? q_m[7:0] : ~q_m[7:0];

            if (q_m[8])
                next_disparity = disparity + balance;
            else
                next_disparity = disparity - balance;

        end
        else if (((disparity > 0) && (balance > 0)) ||
                 ((disparity < 0) && (balance < 0))) begin

            next_symbol[9]   = 1'b1;
            next_symbol[8]   = q_m[8];
            next_symbol[7:0] = ~q_m[7:0];

            next_disparity =
                disparity + (q_m[8] ? 6'sd2 : 6'sd0) - balance;

        end
        else begin

            next_symbol[9]   = 1'b0;
            next_symbol[8]   = q_m[8];
            next_symbol[7:0] = q_m[7:0];

            next_disparity =
                disparity - (q_m[8] ? 6'sd0 : 6'sd2) + balance;

        end
    end

    // Register the encoded symbol and disparity.
    always @(posedge pixel_clk) begin
        if (reset) begin
            tmds_symbol <= 10'b0;
            disparity   <= 6'sd0;
        end
        else begin
            tmds_symbol <= next_symbol;
            disparity   <= next_disparity;
        end
    end

endmodule
