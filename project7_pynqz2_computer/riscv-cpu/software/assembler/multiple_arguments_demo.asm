
# =================================
# MAIN
# =================================

    lui  sp, 4

    # Set up three arguments
    addi a0, zero, 7
    addi a1, zero, 11
    addi a2, zero, 13

    # Call sum_three(7, 11, 13)
    jal  ra, sum_three

# Execution returns here
done:
    jal  zero, done


# =================================
# sum_three(a0, a1, a2)
# =================================

sum_three:

    # a0 = a0 + a1
    add  a0, a0, a1

    # a0 = a0 + a2
    add  a0, a0, a2

    # Return result through a0
    jalr zero, 0(ra)
