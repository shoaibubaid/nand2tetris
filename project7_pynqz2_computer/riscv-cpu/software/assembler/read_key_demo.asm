
# =================================
# MAIN
# =================================

    lui  sp, 4

wait_for_key:

    jal  ra, keyboard_available

    # No event? Keep polling.
    beq  a0, zero, wait_for_key

    # Read the event
    jal  ra, read_key_event

done:
    jal  zero, done


# =================================
# keyboard_available()
#
# a0 = 1 if event available
# a0 = 0 otherwise
# =================================

keyboard_available:

    lui  t0, 0x20000

    lw   a0, 4(t0)

    andi a0, a0, 1

    jalr zero, 0(ra)


# =================================
# read_key_event()
#
# Returns complete 9-bit event in a0.
# =================================

read_key_event:

    lui  t0, 0x20000

    # Read KEY_DATA.
    # Reading this register pops one FIFO event.
    lw   a0, 0(t0)

    jalr zero, 0(ra)
