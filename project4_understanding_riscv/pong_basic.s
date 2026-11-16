
.text
.globl main

main:
    # Allocate 16 bytes on the stack
    addi sp, sp, -16

    # Save return address
    sw ra, 12(sp)

    # Pass arguments: a0 = 2, a1 = 3
    li a0, 2
    li a1, 3

    # Call compute(2, 3)
    jal ra, compute

    # Function result is returned in a0
    sw a0, 0(sp)

done:
    j done


# compute(a0, a1)
# Returns (a0 + a1) + 1 in a0
compute:
    # Create this function's stack frame
    addi sp, sp, -16

    # Save return address because we will call another function
    sw ra, 12(sp)

    # Call add(a0, a1)
    jal ra, add

    # Increment the returned result
    addi a0, a0, 1

    # Restore return address
    lw ra, 12(sp)

    # Destroy this function's stack frame
    addi sp, sp, 16

    # Return to caller
    ret


# add(a0, a1)
# Returns a0 + a1 in a0
add:
    add a0, a0, a1
    ret
