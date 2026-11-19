
# =================================
# MAIN
# =================================

    lui sp, 4

    # Initial square position
    addi s0, zero, 50       # x
    addi s1, zero, 50       # y

    jal ra, draw_square

main_loop:

    # Check keyboard FIFO
    jal ra, keyboard_available

    beq a0, zero, main_loop

    # Read one keyboard event
    jal ra, read_key_event

    # Ignore key release events
    srli t0, a0, 8
    andi t0, t0, 1
    beq t0, zero, main_loop

    # Extract HID keycode
    andi t0, a0, 255

    # W = 0x1A : move up
    addi t1, zero, 26
    beq t0, t1, move_up

    # A = 0x04 : move left
    addi t1, zero, 4
    beq t0, t1, move_left

    # S = 0x16 : move down
    addi t1, zero, 22
    beq t0, t1, move_down

    # D = 0x07 : move right
    addi t1, zero, 7
    beq t0, t1, move_right

    jal zero, main_loop


# =================================
# Movement routines
# =================================

move_up:
    beq s1, zero, main_loop
    addi s1, s1, -1
    jal zero, update_square

move_down:
    addi t1, zero, 230
    bge s1, t1, main_loop
    addi s1, s1, 1
    jal zero, update_square

move_left:
    beq s0, zero, main_loop
    addi s0, s0, -1
    jal zero, update_square

move_right:
    addi t1, zero, 310
    bge s0, t1, main_loop
    addi s0, s0, 1
    jal zero, update_square


# =================================
# Erase old and draw new square
# =================================

update_square:

    # Erase old position
    add a0, s2, zero
    add a1, s3, zero
    addi a2, zero, 10
    addi a3, zero, 10
    addi a4, zero, 0

    jal ra, draw_rectangle

    # Save new position
    add s2, s0, zero
    add s3, s1, zero

    # Draw new position
    jal ra, draw_square

    jal zero, main_loop


# =================================
# draw_square()
# =================================

# =================================
# draw_square()
# =================================

draw_square:

    # Save caller's return address
    addi sp, sp, -16
    sw ra, 12(sp)

    add a0, s0, zero
    add a1, s1, zero
    addi a2, zero, 10
    addi a3, zero, 10
    addi a4, zero, 90

    jal ra, draw_rectangle

    # Restore caller's return address
    lw ra, 12(sp)
    addi sp, sp, 16

    jalr zero, 0(ra)


# =================================
# keyboard_available()
# Returns 1 if FIFO is nonempty
# =================================

keyboard_available:

    lui t0, 0x20000

    lw a0, 4(t0)

    andi a0, a0, 1

    jalr zero, 0(ra)


# =================================
# read_key_event()
# Returns 9-bit event in a0
# =================================

read_key_event:

    lui t0, 0x20000

    lw a0, 0(t0)

    jalr zero, 0(ra)


# =================================
# draw_rectangle(a0,a1,a2,a3,a4)
# =================================

draw_rectangle:

    addi sp, sp, -24

    sw ra, 20(sp)
    sw s0, 16(sp)
    sw s1, 12(sp)
    sw s2, 8(sp)
    sw s3, 4(sp)
    sw s4, 0(sp)

    add s0, a0, zero
    add s1, a1, zero
    add s2, a2, zero
    add s3, a3, zero
    add s4, a4, zero

    addi t0, zero, 0

row_loop:

    bge t0, s3, rectangle_done

    addi t1, zero, 0

col_loop:

    bge t1, s2, next_row

    add a0, s0, t1
    add a1, s1, t0
    add a2, s4, zero

    addi sp, sp, -8
    sw t0, 4(sp)
    sw t1, 0(sp)

    jal ra, draw_pixel

    lw t1, 0(sp)
    lw t0, 4(sp)
    addi sp, sp, 8

    addi t1, t1, 1

    jal zero, col_loop

next_row:

    addi t0, t0, 1

    jal zero, row_loop

rectangle_done:

    lw s4, 0(sp)
    lw s3, 4(sp)
    lw s2, 8(sp)
    lw s1, 12(sp)
    lw s0, 16(sp)
    lw ra, 20(sp)

    addi sp, sp, 24

    jalr zero, 0(ra)


# =================================
# draw_pixel(a0,a1,a2)
# =================================

draw_pixel:

    slli t2, a1, 8
    slli t3, a1, 6

    add t2, t2, t3
    add t2, t2, a0

    lui t3, 0x10000

    add t2, t2, t3

    sb a2, 0(t2)

    jalr zero, 0(ra)
