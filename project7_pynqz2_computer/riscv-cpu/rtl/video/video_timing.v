
module video_timing (
    input  wire       pixel_clk,
    input  wire       reset,

    output wire [9:0] pixel_x,
    output wire [9:0] pixel_y,

    output wire       video_active,
    output wire       hsync,
    output wire       vsync
);

    // 640x480 @ 60 Hz timing
    localparam H_VISIBLE = 640;
    localparam H_FRONT   = 16;
    localparam H_SYNC    = 96;
    localparam H_BACK    = 48;
    localparam H_TOTAL   = 800;

    localparam V_VISIBLE = 480;
    localparam V_FRONT   = 10;
    localparam V_SYNC    = 2;
    localparam V_BACK    = 33;
    localparam V_TOTAL   = 525;

    localparam H_SYNC_START = H_VISIBLE + H_FRONT; // 656
    localparam H_SYNC_END   = H_SYNC_START + H_SYNC; // 752

    localparam V_SYNC_START = V_VISIBLE + V_FRONT; // 490
    localparam V_SYNC_END   = V_SYNC_START + V_SYNC; // 492

    reg [9:0] h_count;
    reg [9:0] v_count;

    // Raster counters
    always @(posedge pixel_clk) begin
        if (reset) begin
            h_count <= 10'd0;
            v_count <= 10'd0;
        end
        else begin
            if (h_count == H_TOTAL - 1) begin
                h_count <= 10'd0;

                if (v_count == V_TOTAL - 1)
                    v_count <= 10'd0;
                else
                    v_count <= v_count + 10'd1;
            end
            else begin
                h_count <= h_count + 10'd1;
            end
        end
    end

    // Coordinates identify the current raster position.
    // They are meaningful as framebuffer coordinates only
    // when video_active is high.
    assign pixel_x = h_count;
    assign pixel_y = v_count;

    assign video_active =
        (h_count < H_VISIBLE) &&
        (v_count < V_VISIBLE);

    // 640x480 standard sync polarity: active low
    assign hsync = !(
        (h_count >= H_SYNC_START) &&
        (h_count < H_SYNC_END)
    );

    assign vsync = !(
        (v_count >= V_SYNC_START) &&
        (v_count < V_SYNC_END)
    );

endmodule
