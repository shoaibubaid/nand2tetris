# RISC-V RV32I Instruction Formats

All base RV32I instructions are 32 bits wide.

## 1. R-Type (Register Type)

Used for register-to-register arithmetic and logical operations.

Examples:
- `add x3, x1, x2`
- `sub x3, x1, x2`
- `and x3, x1, x2`
- `or x3, x1, x2`
- `xor x3, x1, x2`
- `sll x3, x1, x2`
- `srl x3, x1, x2`
- `sra x3, x1, x2`
- `slt x3, x1, x2`
- `sltu x3, x1, x2`

### Bit layout

| funct7 (7) | rs2 (5) | rs1 (5) | funct3 (3) | rd (5) | opcode (7) |
|---|---|---|---|---|---|
| 31:25 | 24:20 | 19:15 | 14:12 | 11:7 | 6:0 |

- `rs1`: First source register
- `rs2`: Second source register
- `rd`: Destination register
- `funct3`, `funct7`: Specify the operation
- `opcode`: Identifies the instruction category

**No immediate** field exists in R-type instructions.

---

## 2. I-Type (Immediate Type)

Used for immediate arithmetic, loads, and indirect jumps.

Examples:
- `addi x5, x6, 10`
- `andi x5, x6, 15`
- `ori x5, x6, 15`
- `xori x5, x6, 15`
- `lw x5, 12(x6)`
- `jalr x1, 0(x5)`

### Bit layout

| imm[11:0] (12) | rs1 (5) | funct3 (3) | rd (5) | opcode (7) |
|---|---|---|---|---|
| 31:20 | 19:15 | 14:12 | 11:7 | 6:0 |

- `imm[11:0]`: 12-bit immediate
- `rs1`: Source register
- `rd`: Destination register
- `funct3`: Specifies the operation
- `opcode`: Identifies the instruction category

The immediate is sign-extended to 32 bits.

---

## 3. S-Type (Store Type)

Used for storing register values into memory.

Examples:
- `sw x5, 12(x6)`
- `sh x5, 4(x6)`
- `sb x5, 2(x6)`

### Bit layout

| imm[11:5] (7) | rs2 (5) | rs1 (5) | funct3 (3) | imm[4:0] (5) | opcode (7) |
|---|---|---|---|---|---|
| 31:25 | 24:20 | 19:15 | 14:12 | 11:7 | 6:0 |

- `rs1`: Base address register
- `rs2`: Register containing data to store
- `imm[11:5]`, `imm[4:0]`: Split immediate
- `funct3`: Specifies store width
- `opcode`: Identifies a store instruction

The immediate is reconstructed and sign-extended to 32 bits.

---

## 4. B-Type (Branch Type)

Used for conditional branches.

Examples:
- `beq x1, x2, label`
- `bne x1, x2, label`
- `blt x1, x2, label`
- `bge x1, x2, label`
- `bltu x1, x2, label`
- `bgeu x1, x2, label`

### Bit layout

| imm[12] (1) | imm[10:5] (6) | rs2 (5) | rs1 (5) | funct3 (3) | imm[4:1] (4) | imm[11] (1) | opcode (7) |
|---|---|---|---|---|---|---|---|
| 31 | 30:25 | 24:20 | 19:15 | 14:12 | 11:8 | 7 | 6:0 |

- `rs1`, `rs2`: Registers being compared
- `funct3`: Determines the branch condition
- Immediate bits are scattered across the instruction

### Immediate reconstruction

```verilog
imm = {
    {19{instruction[31]}},
    instruction[31],
    instruction[7],
    instruction[30:25],
    instruction[11:8],
    1'b0
};
```

The immediate is a signed, PC-relative byte offset. Its least significant bit is always zero.

---

## 5. U-Type (Upper Immediate Type)

Used for loading upper immediate values and PC-relative upper immediate operations.

Examples:
- `lui x5, 0x12345`
- `auipc x5, 0x12345`

### Bit layout

| imm[31:12] (20) | rd (5) | opcode (7) |
|---|---|---|
| 31:12 | 11:7 | 6:0 |

- `imm[31:12]`: Upper 20-bit immediate
- `rd`: Destination register
- `opcode`: Identifies LUI or AUIPC

### Immediate reconstruction

```verilog
imm = {
    instruction[31:12],
    12'b0
};
```

The lower 12 bits are always zero.

---

## 6. J-Type (Jump Type)

Used for unconditional PC-relative jumps.

Example:
- `jal x1, function`
- `jal x0, loop`

### Bit layout

| imm[20] (1) | imm[10:1] (10) | imm[11] (1) | imm[19:12] (8) | rd (5) | opcode (7) |
|---|---|---|---|---|---|
| 31 | 30:21 | 20 | 19:12 | 11:7 | 6:0 |

- `rd`: Destination register for return address
- Immediate bits are scattered across the instruction
- `jal` saves `PC + 4` in `rd`
- The PC is updated using the signed immediate offset

### Immediate reconstruction

```verilog
imm = {
    {11{instruction[31]}},
    instruction[31],
    instruction[19:12],
    instruction[20],
    instruction[30:21],
    1'b0
};
```

The immediate is sign-extended and its least significant bit is zero.

---

## 7. Summary

| Format | Main purpose | Immediate width before extension |
|---|---|---:|
| R-Type | Register operations | No immediate |
| I-Type | Immediate operations, loads, JALR | 12 bits |
| S-Type | Stores | 12 bits |
| B-Type | Conditional branches | 13 bits (including implicit zero) |
| U-Type | Upper immediate operations | 32-bit value with 12 trailing zeros |
| J-Type | Unconditional jump | 21 bits (including implicit zero) |

## 8. Important Notes

1. All six formats are 32 bits wide.
2. R-type instructions do not contain an immediate.
3. I-type and S-type immediates are sign-extended.
4. B-type and J-type immediates have scattered bit positions.
5. B-type and J-type immediates have an implicit zero at bit 0.
6. U-type immediates have twelve trailing zeros.
7. The opcode identifies the broad instruction category, while funct3 and funct7 further distinguish operations.
