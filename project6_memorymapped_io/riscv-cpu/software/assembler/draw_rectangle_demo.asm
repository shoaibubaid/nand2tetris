
# =================================
# MAIN
# =================================

    lui  sp, 4

    # x = 10
    addi a0, zero, 10

    # y = 20
    addi a1, zero, 20

    # width = 5
    addi a2, zero, 5

    # height = 3
    addi a3, zero, 3

    # color = 0x5A
    addi a4, zero, 90

    jal  ra, draw_rectangle

done:
    jal  zero, done


# =================================
# draw_rectangle(a0,a1,a2,a3,a4)
#
# a0 = x
# a1 = y
# a2 = width
# a3 = height
# a4 = color
# =================================

draw_rectangle:

    # Allocate stack frame
    addi sp, sp, -24

    # Save return address
    sw   ra, 20(sp)

    # Save callee-saved registers
    sw   s0, 16(sp)
    sw   s1, 12(sp)
    sw   s2, 8(sp)
    sw   s3, 4(sp)
    sw   s4, 0(sp)

    # Preserve rectangle parameters
    add  s0, a0, zero      # original x
    add  s1, a1, zero      # original y
    add  s2, a2, zero      # width
    add  s3, a3, zero      # height
    add  s4, a4, zero      # color

    # row = 0
    addi t0, zero, 0

row_loop:

    # if row >= height, finish
    bge  t0, s3, rectangle_done

    # col = 0
    addi t1, zero, 0

col_loop:

    # if col >= width, next row
    bge  t1, s2, next_row

    # draw_pixel(x + col, y + row, color)

    add  a0, s0, t1
    add  a1, s1, t0
    add  a2, s4, zero

    # Preserve loop counters around function call
    addi sp, sp, -8
    sw   t0, 4(sp)
    sw   t1, 0(sp)

    jal  ra, draw_pixel

    # Restore loop counters
    lw   t1, 0(sp)
    lw   t0, 4(sp)
    addi sp, sp, 8

    # col++
    addi t1, t1, 1

    jal  zero, col_loop

next_row:

    # row++
    addi t0, t0, 1

    jal  zero, row_loop

rectangle_done:

    # Restore registers
    lw   s4, 0(sp)
    lw   s3, 4(sp)
    lw   s2, 8(sp)
    lw   s1, 12(sp)
    lw   s0, 16(sp)
    lw   ra, 20(sp)

    # Release stack frame
    addi sp, sp, 24

    jalr zero, 0(ra)


# =================================
# draw_pixel(a0,a1,a2)
#
# a0 = x
# a1 = y
# a2 = color
# =================================

draw_pixel:

    slli t2, a1, 8
    slli t3, a1, 6

    add  t2, t2, t3
    add  t2, t2, a0

    lui  t3, 0x10000

    add  t2, t2, t3

    sb   a2, 0(t2)

    jalr zero, 0(ra)
