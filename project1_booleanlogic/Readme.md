# project 1 : Boolen Logic
Build these chips/ Gates
Build the Nand gate first and then use that to build the remaining.

- Nand (given)
- Not
- And
- Or
- Xor
- Mux
- DMux
- Not16
- And16
- Or16
- Mux16
- Or8Way
- Mux4Way16
- Mux8Way16
- DMux4Way
- DMux8Way


```
iverilog -o sim gates/nand_gate.v test/nand_testbench.v
vvp sim
```