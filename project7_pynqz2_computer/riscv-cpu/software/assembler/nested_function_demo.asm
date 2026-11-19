
# Initialize stack pointer
    lui  sp, 4

# main passes 5 to outer()
    addi a0, zero, 5
    jal  ra, outer

# Execution returns here
done:
    jal  zero, done


# outer(a0)
outer:
    # Save return address
    addi sp, sp, -4
    sw   ra, 0(sp)

    # Call inner()
    jal  ra, inner

    # Restore original return address
    lw   ra, 0(sp)
    addi sp, sp, 4

    # Add 1 to result
    addi a0, a0, 1

    # Return to main
    jalr zero, 0(ra)


# inner(a0)
inner:
    # Add 2 to argument
    addi a0, a0, 2

    # Return to outer
    jalr zero, 0(ra)
