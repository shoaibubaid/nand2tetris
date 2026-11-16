


# Draw a rectangle 16 pixels wide and R0 pixels high.

.data
R0:          .word 10          # Rectangle height
R1:          .word 0           # Not used
R2:          .word 0           # Not used

.align 2
screen:      .space 16384      # Simulated screen buffer (256 rows)

.text
.globl main

main:
    # Load R0
    la   t0, R0
    lw   t1, 0(t0)             # t1 = R0

    # If R0 <= 0, goto END
    bge  x0, t1, END

    # n = R0
    addi t2, t1, 0

    # addr = address of first screen row
    la   t3, screen

    # Pixel pattern = 0xFFFF (16 white/black bits)
    li   t4, -1

LOOP:
    # RAM[addr] = -1
    sh   t4, 0(t3)

    # addr = addr + 64 (next screen row)
    addi t3, t3, 64

    # n = n - 1
    addi t2, t2, -1

    # If n > 0, repeat
    bne  t2, x0, LOOP

END:
    jal  x0, END