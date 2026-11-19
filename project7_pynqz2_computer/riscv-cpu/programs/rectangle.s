
    # Rectangle generator for our RV32I CPU
    # Height = 10 rows
    #
    # t0 (x5)  = rectangle height
    # t1 (x6)  = current row counter
    # t2 (x7)  = framebuffer address
    # t3 (x28) = pixel pattern (0xFFFFFFFF)

    addi t0, zero, 10
    addi t1, zero, 0
    addi t2, zero, 0
    addi t3, zero, -1

rectangle_loop:
    sh   t3, 0(t2)       # Write 0xFFFF (16 pixels)
    addi t2, t2, 64      # Move to next screen row
    addi t1, t1, 1       # Increment row counter
    blt  t1, t0, rectangle_loop

done:
    jal  zero, done      # Stop by looping forever
