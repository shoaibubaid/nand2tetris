
# =================================
# MAIN PROGRAM
# =================================

    lui  sp, 4

    # x = 10
    addi a0, zero, 10

    # y = 20
    addi a1, zero, 20

    # color = 0x5A
    addi a2, zero, 90

    # Call draw_pixel(10, 20, 0x5A)
    jal  ra, draw_pixel

done:
    jal  zero, done


# =================================
# draw_pixel(a0, a1, a2)
#
# a0 = x
# a1 = y
# a2 = color
#
# Uses t0 and t1
# =================================

draw_pixel:

    # t0 = y << 8
    slli t0, a1, 8

    # t1 = y << 6
    slli t1, a1, 6

    # t0 = y * 320
    add  t0, t0, t1

    # t0 = y * 320 + x
    add  t0, t0, a0

    # t1 = framebuffer base address
    lui  t1, 0x10000

    # t0 = framebuffer base + pixel offset
    add  t0, t0, t1

    # Write one byte (pixel color)
    sb   a2, 0(t0)

    # Return
    jalr zero, 0(ra)
