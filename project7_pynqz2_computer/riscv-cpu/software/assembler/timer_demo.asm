
# MAIN
    lui sp, 4

    # Configure timer prescaler to 4 cycles/ms
    lui t0, 0x20000
    addi t0, t0, 16

    addi t1, zero, 4
    sw t1, 8(t0)

    # Reset and enable timer
    addi t1, zero, 3
    sw t1, 4(t0)

    # Read initial time
    jal ra, timer_read_ms
    addi s0, a0, 0

wait_for_tick:
    jal ra, timer_read_ms
    beq a0, s0, wait_for_tick

done:
    jal zero, done


# timer_start()
# Resets and enables the timer.
timer_start:
    lui t0, 0x20000
    addi t0, t0, 16
    addi t1, zero, 3
    sw t1, 4(t0)
    jalr zero, 0(ra)


# timer_read_ms()
# Returns elapsed milliseconds in a0.
timer_read_ms:
    lui t0, 0x20000
    addi t0, t0, 16
    lw a0, 0(t0)
    jalr zero, 0(ra)
