
# Draw a 16-pixel-wide rectangle.
# Height is stored in R0.

.data
R0: .word 10

.text
.globl main

main:
    la   t0, R0
    lw   s0, 0(t0)          # s0 = height

    ble  s0, x0, END        # If height <= 0, stop

    li   s1, 0              # y = 0
    li   s3, 16             # Rectangle width
    li   s4, 0x003FFFF3     # Blue colour

OUTER:
    li   s2, 0              # x = 0

INNER:
    li   a0, 0x100          # Set pixel service

    slli a1, s2, 16         # x occupies upper 16 bits
    or   a1, a1, s1         # y occupies lower 16 bits

    mv   a2, s4             # Pixel colour
    ecall                   # Draw pixel

    addi s2, s2, 1          # x++
    addi s4, s4, 2
    blt  s2, s3, INNER      # Continue until x = 16

    addi s1, s1, 1          # y++
    addi s4, s4, 2
    blt  s1, s0, OUTER      # Continue until y = height

END:
    jal x0, END
