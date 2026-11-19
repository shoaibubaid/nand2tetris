# MAIN

    lui  sp, 4

    jal  ra, keyboard_available

done:
    jal  zero, done


# keyboard_available()
#
# Return:
# a0 = 1 if event available
# a0 = 0 otherwise

keyboard_available:

    # Keyboard controller base address
    lui  t0, 0x20000

    # Read KEY_STATUS at offset 4
    lw   a0, 4(t0)

    # Extract FIFO not-empty bit
    andi a0, a0, 1

    # Return
    jalr zero, 0(ra)