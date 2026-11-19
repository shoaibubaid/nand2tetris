# Initialize registers
addi x5, x0, 100
addi x6, x0, 200

# Store and load
sw   x5, 0(x0)
sw   x6, 4(x0)

lw   x7, 0(x0)
lw   x8, 4(x0)

# Byte and halfword operations
sb   x5, 8(x0)
lb   x9, 8(x0)
lbu  x10, 8(x0)

sh   x6, 12(x0)
lh   x11, 12(x0)
lhu  x12, 12(x0)