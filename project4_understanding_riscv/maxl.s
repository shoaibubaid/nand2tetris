# Computes RAM[2] = max(RAM[0], RAM[1])
# Assumes 32-bit signed integers.

.text
.globl main

main:
    lw   x5, 0(x0)       # x5 = RAM[0]
    lw   x6, 4(x0)       # x6 = RAM[1]

    blt  x6, x5, 12      # If R1 < R0, jump 12 bytes ahead

    sw   x6, 8(x0)       # RAM[2] = R1
    jal  x0, 8           # Jump to infinite loop

    sw   x5, 8(x0)       # RAM[2] = R0

    jal  x0, 0           # Infinite loop