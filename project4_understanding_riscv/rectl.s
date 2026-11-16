# Computes a rectangle of width 16 and height RAM[0].

.data
R0:     .word 10

.align 2
screen: .space 16384

.text
.globl main

main:
    la   t0, R0
    lw   t1, 0(t0)          # t1 = RAM[0]

    # If R0 <= 0, goto END
    bge  x0, t1, END

    # n = R0
    addi t2, t1, 0

    # addr = SCREEN
    la   t3, screen

    # Pattern = -1 (16 bits set)
    li   t4, -1

LOOP:
    # RAM[addr] = -1
    sh   t4, 0(t3)

    # addr = addr + 64 bytes
    addi t3, t3, 64

    # n = n - 1
    addi t2, t2, -1

    # If n > 0, goto LOOP
    blt  x0, t2, LOOP

END:
    jal  x0, END