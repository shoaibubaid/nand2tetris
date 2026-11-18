
# =================================
# MAIN
# =================================

    lui  sp, 4

    # First argument = 5
    addi a0, zero, 5

    # Initialize s0 with a recognizable value
    addi s0, zero, 77

    # Call outer(5)
    jal  ra, outer

done:
    jal  zero, done


# =================================
# outer(a0)
# =================================

outer:

    # Allocate 16-byte stack frame
    addi sp, sp, -16

    # Save return address
    sw   ra, 12(sp)

    # Save callee-saved register
    sw   s0, 8(sp)

    # Save local variable (original a0)
    sw   a0, 4(sp)

    # Modify s0 deliberately
    addi s0, zero, 123

    # Call inner()
    jal  ra, inner

    # Restore local variable into t0
    lw   t0, 4(sp)

    # Add original argument to inner's result
    add  a0, a0, t0

    # Restore original s0
    lw   s0, 8(sp)

    # Restore return address
    lw   ra, 12(sp)

    # Release stack frame
    addi sp, sp, 16

    # Return to main
    jalr zero, 0(ra)


# =================================
# inner(a0)
# =================================

inner:

    # Add 2 to argument
    addi a0, a0, 2

    # Return to outer
    jalr zero, 0(ra)
