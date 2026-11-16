# Computes RAM[2] = max(RAM[0], RAM[1])

.data
R0: .word 36       # Input 1
R1: .word 25       # Input 2
R2: .word 0        # Output

.text
.globl main

main:
    la   t0, R0        # t0 = address of R0

    lw   t1, 0(t0)     # t1 = RAM[0]
    lw   t2, 4(t0)     # t2 = RAM[1]

    bge  t1, t2, ITSR0 # If R0 >= R1, goto ITSR0

    addi t3, t2, 0     # t3 = R1
    jal  x0, OUTPUT   # Jump to OUTPUT

ITSR0:
    addi t3, t1, 0     # t3 = R0

OUTPUT:
    sw   t3, 8(t0)     # RAM[2] = t3

END:
    jal  x0, END       # Infinite loop