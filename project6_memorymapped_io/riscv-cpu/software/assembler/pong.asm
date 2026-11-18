
# ============================================================
# PONG - Initial keyboard-controlled paddle test
#
# Framebuffer: 320 x 240, RGB332
# Framebuffer base: 0x10000000
#
# Keyboard:
#   KEY_DATA   = 0x20000000
#   KEY_STATUS = 0x20000004
#
# Controls:
#   W = move left paddle up
#   S = move left paddle down
#
# Registers:
#   s0 = left paddle X
#   s1 = left paddle Y
#   s2 = previous left paddle Y
# ============================================================


_start:
    # Initialize stack pointer
    lui sp, 0x4

    # Clear the area around the left paddle
    addi a0, zero, 10
    addi a1, zero, 98
    addi a2, zero, 6
    addi a3, zero, 43
    addi a4, zero, 0
    jal ra, draw_rectangle

    # --------------------------------------------------------
    # Draw left paddle: x=10, y=100, width=6, height=40
    # --------------------------------------------------------
    addi a0, zero, 10
    addi a1, zero, 100
    addi a2, zero, 6
    addi a3, zero, 40
    addi a4, zero, -1
    jal ra, draw_rectangle

    # --------------------------------------------------------
    # Draw right paddle: x=304, y=100, width=6, height=40
    # --------------------------------------------------------
    addi a0, zero, 304
    addi a1, zero, 100
    addi a2, zero, 6
    addi a3, zero, 40
    addi a4, zero, -1
    jal ra, draw_rectangle

    
    # Save left paddle position
    addi s0, zero, 10
    addi s1, zero, 100

    # Save right paddle position
    addi s3, zero, 304
    addi s4, zero, 100


    # Initialize scores
    # s6 = left player's score
    addi s6, zero, 0

    # Right player's score stored at dedicated RAM address 0x3F00
    lui t0, 4
    addi t0, t0, -256
    sw zero, 0(t0)

    # Ball position: (157,117)
    addi s7, zero, 157
    addi s8, zero, 117

    # Ball velocity: (+1,+1)
    addi s9, zero, 1
    addi s10, zero, 1

    # Initialize hardware timer
    lui t0, 0x20000

    # Reset timer
    addi t1, zero, 2
    sw t1, 20(t0)

    # Enable timer
    addi t1, zero, 1
    sw t1, 20(t0)

    # Remember initial timer value
    lw s11, 16(t0)

    # Draw initial ball
    addi a0, s7, 0
    addi a1, s8, 0
    addi a2, zero, 6
    addi a3, zero, 6
    addi a4, zero, -1
    jal ra, draw_rectangle



# ============================================================
# MAIN LOOP
# ============================================================

main_loop:
    jal ra, update_ball_if_due

    jal ra, keyboard_available
    beq a0, zero, main_loop

    jal ra, read_key_event

    # Ignore key releases.
    # Event format: bit 8 = pressed, bits 7:0 = HID keycode
    srli t0, a0, 8
    andi t0, t0, 1
    beq t0, zero, main_loop

    # Extract HID keycode
    andi t0, a0, 255

    # W = 0x1A = 26
    addi t1, zero, 26
    beq t0, t1, move_left_up

    # S = 0x16 = 22
    addi t1, zero, 22
    beq t0, t1, move_left_down

    # I = 0x0C = 12
    addi t1, zero, 12
    beq t0, t1, move_right_up

    # K = 0x0E = 14
    addi t1, zero, 14
    beq t0, t1, move_right_down

    jal zero, main_loop

# ============================================================
# MOVE LEFT PADDLE UP
# ============================================================

move_left_up:
    # Cannot move above y=0
    beq s1, zero, main_loop

    # Save previous Y coordinate
    addi s2, s1, 0

    # Move up by one pixel
    addi s1, s1, -1

    jal ra, redraw_left_paddle
    jal zero, main_loop


# ============================================================
# MOVE LEFT PADDLE DOWN
# ============================================================

move_left_down:
    # Check whether bottom edge would exceed screen
    addi t1, s1, 40
    addi t2, zero, 240
    bge t1, t2, main_loop

    # Save previous Y coordinate
    addi s2, s1, 0

    # Move down by one pixel
    addi s1, s1, 1

    jal ra, redraw_left_paddle
    jal zero, main_loop



# ============================================================
# MOVE RIGHT PADDLE UP
# ============================================================

move_right_up:
    beq s4, zero, main_loop

    # Save previous Y
    addi s5, s4, 0

    # Move up
    addi s4, s4, -1

    jal ra, redraw_right_paddle
    jal zero, main_loop


# ============================================================
# MOVE RIGHT PADDLE DOWN
# ============================================================

move_right_down:
    # Check bottom boundary
    addi t1, s4, 40
    addi t2, zero, 240
    bge t1, t2, main_loop

    # Save previous Y
    addi s5, s4, 0

    # Move down
    addi s4, s4, 1

    jal ra, redraw_right_paddle
    jal zero, main_loop


# ============================================================
# REDRAW LEFT PADDLE
#
# s0 = X
# s1 = new Y
# s2 = old Y
#
# This is a non-leaf function, so preserve ra.
# ============================================================

redraw_left_paddle:
    addi sp, sp, -16
    sw ra, 12(sp)

    # Erase old paddle
    addi a0, s0, 0
    addi a1, s2, 0
    addi a2, zero, 6
    addi a3, zero, 40
    addi a4, zero, 0
    jal ra, draw_rectangle

    # Draw paddle at new position
    addi a0, s0, 0
    addi a1, s1, 0
    addi a2, zero, 6
    addi a3, zero, 40
    addi a4, zero, -1
    jal ra, draw_rectangle

    # Restore return address
    lw ra, 12(sp)
    addi sp, sp, 16
    jalr zero, 0(ra)


# ============================================================
# REDRAW RIGHT PADDLE
#
# s3 = X
# s4 = new Y
# s5 = old Y
# ============================================================

redraw_right_paddle:
    addi sp, sp, -16
    sw ra, 12(sp)

    # Erase old paddle
    addi a0, s3, 0
    addi a1, s5, 0
    addi a2, zero, 6
    addi a3, zero, 40
    addi a4, zero, 0
    jal ra, draw_rectangle

    # Draw new paddle
    addi a0, s3, 0
    addi a1, s4, 0
    addi a2, zero, 6
    addi a3, zero, 40
    addi a4, zero, -1
    jal ra, draw_rectangle

    # Restore return address
    lw ra, 12(sp)
    addi sp, sp, 16
    jalr zero, 0(ra)


# ============================================================
# BALL MOVEMENT AND WALL COLLISION
#
# s7  = ball X
# s8  = ball Y
# s9  = velocity X
# s10 = velocity Y
# s11 = last timer value
#
# Ball size: 6x6
# Update interval: 20 timer units
# ============================================================

update_ball_if_due:
    addi sp, sp, -16
    sw ra, 12(sp)

    # Read hardware timer
    lui t0, 0x20000
    lw t1, 16(t0)

    # Calculate elapsed time
    sub t2, t1, s11

    # Update every 20 timer units
    addi t3, zero, 20
    bltu t2, t3, ball_not_due

    # Save current timer value
    addi s11, t1, 0

    # ------------------------------------------------
    # Erase old ball
    # ------------------------------------------------

    addi a0, s7, 0
    addi a1, s8, 0
    addi a2, zero, 6
    addi a3, zero, 6
    addi a4, zero, 0
    jal ra, draw_rectangle

    # ------------------------------------------------
    # Calculate new X position
    # ------------------------------------------------


    # Calculate next X position
    add t0, s7, s9

    # Moving left?
    blt s9, zero, check_left_goal

    # Moving right: check right boundary
    addi t1, zero, 314
    blt t1, t0, left_player_scores

    jal zero, ball_x_ready

check_left_goal:
    # Ball has completely left the screen
    blt t0, zero, right_player_scores

ball_x_ready:
    addi s7, t0, 0



    # ------------------------------------------------
    # Calculate new Y position
    # ------------------------------------------------

    add t0, s8, s10

    # Top boundary
    blt t0, zero, reverse_ball_y

    # Bottom boundary: 240 - 6 = 234
    addi t1, zero, 234
    blt t1, t0, reverse_ball_y

    jal zero, ball_y_ready

reverse_ball_y:
    sub s10, zero, s10
    add t0, s8, s10


ball_y_ready:
    addi s8, t0, 0

    # =================================================
    # PADDLE COLLISION DETECTION
    #
    # Ball: 6x6
    # Left paddle:  x=10,  y=s1, width=6, height=40
    # Right paddle: x=304, y=s4, width=6, height=40
    # =================================================

    # Calculate ball right and bottom edges
    addi t0, s7, 6
    addi t1, s8, 6

    # -------------------------------------------------
    # Determine direction
    # -------------------------------------------------

    blt s9, zero, check_left_collision

    # =================================================
    # RIGHT PADDLE COLLISION
    # =================================================

    # Ball must reach right paddle's left edge (304)
    addi t2, zero, 304
    blt t0, t2, collision_done

    # Ball must not have passed paddle's right edge (310)
    addi t2, zero, 310
    blt t2, s7, collision_done

    # Vertical overlap:
    # ball_bottom > paddle_top
    bge s4, t1, collision_done

    # ball_top < paddle_bottom
    addi t2, s4, 40
    bge s8, t2, collision_done

    # Collision! Reverse horizontal velocity
    sub s9, zero, s9

    jal zero, collision_done


check_left_collision:

    # =================================================
    # LEFT PADDLE COLLISION
    # =================================================

    # Ball must reach left paddle's right edge (16)
    addi t2, zero, 16
    blt t2, s7, collision_done

    # Ball must not have passed paddle's left edge (10)
    addi t2, zero, 10
    blt t0, t2, collision_done

    # Vertical overlap:
    # ball_bottom > paddle_top
    bge s1, t1, collision_done

    # ball_top < paddle_bottom
    addi t2, s1, 40
    bge s8, t2, collision_done

    # Collision! Reverse horizontal velocity
    sub s9, zero, s9


collision_done:

    # Draw ball at new position
    addi a0, s7, 0
    addi a1, s8, 0
    addi a2, zero, 6
    addi a3, zero, 6
    addi a4, zero, -1
    jal ra, draw_rectangle

ball_not_due:
    lw ra, 12(sp)
    addi sp, sp, 16
    jalr zero, 0(ra)


# ============================================================
# LEFT PLAYER SCORES
# Ball passed the right paddle
#
# s6 = left score
# ============================================================

left_player_scores:

    # Maximum displayed score = 10
    addi t0, zero, 10
    bge s6, t0, left_reset_ball

    # Increment left score
    addi s6, s6, 1

    # Calculate marker X = 140 + (score-1)*6
    addi t0, s6, -1
    slli t1, t0, 2
    slli t2, t0, 1
    add t1, t1, t2
    addi a0, t1, 140

    # Draw score marker
    addi a1, zero, 8
    addi a2, zero, 4
    addi a3, zero, 8
    addi a4, zero, -1
    jal ra, draw_rectangle

left_reset_ball:
    # Reset ball to centre
    addi s7, zero, 157
    addi s8, zero, 117

    # Serve towards right player
    addi s9, zero, 1
    addi s10, zero, 1

    # Draw ball
    addi a0, s7, 0
    addi a1, s8, 0
    addi a2, zero, 6
    addi a3, zero, 6
    addi a4, zero, -1
    jal ra, draw_rectangle

    jal zero, ball_not_due


# ============================================================
# RIGHT PLAYER SCORES
# Ball passed the left paddle
#
# Right score stored at RAM 0x3FF0
# ============================================================

right_player_scores:

    # Load right score
    lui t0, 4
    addi t0, t0, -256
    lw t1, 0(t0)

    # Maximum displayed score = 10
    addi t2, zero, 10
    bge t1, t2, right_reset_ball

    # Increment and save score
    addi t1, t1, 1
    sw t1, 0(t0)

    # Calculate marker X = 180 + (score-1)*6
    addi t0, t1, -1
    slli t2, t0, 2
    slli t3, t0, 1
    add t2, t2, t3
    addi a0, t2, 180

    # Draw score marker
    addi a1, zero, 8
    addi a2, zero, 4
    addi a3, zero, 8
    addi a4, zero, -1
    jal ra, draw_rectangle

right_reset_ball:
    # Reset ball to centre
    addi s7, zero, 157
    addi s8, zero, 117

    # Serve towards left player
    addi s9, zero, -1
    addi s10, zero, 1

    # Draw ball
    addi a0, s7, 0
    addi a1, s8, 0
    addi a2, zero, 6
    addi a3, zero, 6
    addi a4, zero, -1
    jal ra, draw_rectangle

    jal zero, ball_not_due


# ============================================================
# GRAPHICS ROUTINES
# ============================================================

# ------------------------------------------------------------
# draw_pixel(a0=x, a1=y, a2=color)
#
# Address = framebuffer_base + y*320 + x
# ------------------------------------------------------------

draw_pixel:
    # Calculate y * 320
    slli t0, a1, 8
    slli t1, a1, 6
    add t0, t0, t1

    # Add x
    add t0, t0, a0

    # Add framebuffer base 0x10000000
    lui t1, 0x10000
    add t0, t0, t1

    # Write RGB332 pixel
    sb a2, 0(t0)

    jalr zero, 0(ra)


# ------------------------------------------------------------
# draw_rectangle(a0=x, a1=y, a2=width, a3=height, a4=color)
#
# Uses s0-s6 and preserves them.
# ------------------------------------------------------------

draw_rectangle:
    addi sp, sp, -32

    sw ra, 28(sp)
    sw s0, 24(sp)
    sw s1, 20(sp)
    sw s2, 16(sp)
    sw s3, 12(sp)
    sw s4, 8(sp)
    sw s5, 4(sp)
    sw s6, 0(sp)

    # Save arguments
    addi s0, a0, 0       # X
    addi s1, a1, 0       # Y
    addi s2, a2, 0       # Width
    addi s3, a3, 0       # Height
    addi s4, a4, 0       # Color

    addi s5, zero, 0     # Row counter

rectangle_row_loop:
    bge s5, s3, rectangle_done

    addi s6, zero, 0     # Column counter

rectangle_column_loop:
    bge s6, s2, rectangle_next_row

    # Pixel X = rectangle X + column
    add a0, s0, s6

    # Pixel Y = rectangle Y + row
    add a1, s1, s5

    # Pixel color
    addi a2, s4, 0

    jal ra, draw_pixel

    addi s6, s6, 1
    jal zero, rectangle_column_loop

rectangle_next_row:
    addi s5, s5, 1
    jal zero, rectangle_row_loop


rectangle_done:
    # Restore registers
    lw s6, 0(sp)
    lw s5, 4(sp)
    lw s4, 8(sp)
    lw s3, 12(sp)
    lw s2, 16(sp)
    lw s1, 20(sp)
    lw s0, 24(sp)
    lw ra, 28(sp)

    addi sp, sp, 32
    jalr zero, 0(ra)


# ============================================================
# KEYBOARD ROUTINES
# ============================================================

# ------------------------------------------------------------
# keyboard_available()
#
# Returns:
#   a0 = 1 if FIFO is not empty
#   a0 = 0 if FIFO is empty
# ------------------------------------------------------------

keyboard_available:
    lui t0, 0x20000
    lw t1, 4(t0)

    andi a0, t1, 1

    jalr zero, 0(ra)


# ------------------------------------------------------------
# read_key_event()
#
# Returns:
#   a0 = 9-bit keyboard event
#
# Reading KEY_DATA pops the FIFO.
# ------------------------------------------------------------

read_key_event:
    lui t0, 0x20000
    lw a0, 0(t0)

    jalr zero, 0(ra)
