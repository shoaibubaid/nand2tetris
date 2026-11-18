

# =================================
# MAIN
# =================================

    lui sp, 4

    # Configure timer
    lui t0, 0x20000
    addi t0, t0, 16

    # Prescaler = 100000 cycles per millisecond
    lui t1, 0x18
    addi t1, t1, 1696
    sw t1, 8(t0)

    # Reset and enable timer
    addi t1, zero, 3
    sw t1, 4(t0)

    # Initial square position
    addi s0, zero, 10      # x
    addi s1, zero, 50      # y

    # Draw initial square
    add a0, s0, zero
    add a1, s1, zero
    addi a2, zero, 10      # width
    addi a3, zero, 10      # height
    addi a4, zero, 90      # color

    jal ra, draw_rectangle

movement_loop:

    # Record current timer value
    jal ra, timer_read_ms
    add s2, a0, zero

wait_for_tick:

    jal ra, timer_read_ms

    # Wait until timer changes
    beq a0, s2, wait_for_tick

    # Erase previous square using black
    add a0, s0, zero
    add a1, s1, zero
    addi a2, zero, 10
    addi a3, zero, 10
    addi a4, zero, 0

    jal ra, draw_rectangle

    # Move square one pixel right
    addi s0, s0, 1

    # Restart from left when reaching boundary
    addi t0, zero, 300
    blt s0, t0, draw_new_square

    addi s0, zero, 10

draw_new_square:

    # Draw new square
    add a0, s0, zero
    add a1, s1, zero
    addi a2, zero, 10
    addi a3, zero, 10
    addi a4, zero, 90

    jal ra, draw_rectangle

    jal zero, movement_loop


# =================================
# timer_read_ms()
# Returns elapsed time in a0
# =================================

timer_read_ms:

    lui t0, 0x20000
    addi t0, t0, 16

    lw a0, 0(t0)

    jalr zero, 0(ra)



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
