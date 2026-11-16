# Computes RAM[0] = 2 + 3
# x0 is a special register that is always 0.

.text
.globl main

main:
    addi x1, x0, 2       # x1 = 2
    addi x2, x0, 3       # x2 = 3
    add  x3, x1, x2      # x3 = x1 + x2 = 5
    sw   x3, 2(x0)       # RAM[0] = x3

end:
    jal x0, end