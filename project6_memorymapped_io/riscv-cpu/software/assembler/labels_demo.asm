# Countdown program

    addi x5, x0, 3

loop:
    addi x5, x5, -1
    bne  x5, x0, loop

done:
    jal  x0, done