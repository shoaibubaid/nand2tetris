
# =================================
# MAIN
# =================================

    lui  sp, 4

    # Call clear_screen()
    jal  ra, clear_screen

done:
    jal  zero, done


# =================================
# clear_screen()
#
# Clears all 320x240 pixels.
# Uses SW to clear 4 pixels at once.
# =================================

clear_screen:

    # t0 = framebuffer base address
    lui  t0, 0x10000

    # t1 = 19200
    # 19200 = 0x4B00
    lui  t1, 5
    addi t1, t1, -1280

clear_loop:

    # Write four zero-valued pixels
    sw   zero, 0(t0)

    # Advance by 4 bytes
    addi t0, t0, 4

    # Decrement remaining word count
    addi t1, t1, -1

    # Continue until all words are cleared
    bne  t1, zero, clear_loop

    # Return to caller
    jalr zero, 0(ra)
