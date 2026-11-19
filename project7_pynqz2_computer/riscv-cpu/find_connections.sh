for f in rtl/top.v rtl/cpu.v rtl/memory_subsystem.v rtl/framebuffer.v rtl/video/video_system.v rtl/video/video_controller.v rtl/video/video_timing.v; do
    echo
    echo "========== $f =========="
    grep -nE 'module |endmodule|input |output |inout |parameter |assign |inst|clk|reset' "$f"
done