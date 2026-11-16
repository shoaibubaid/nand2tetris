# RISC-V Instruction Decoder (RV32I)

## 1. Introduction

The instruction decoder is responsible for extracting individual fields from a 32-bit RISC-V instruction.

An instruction contains information such as:

- Which operation the CPU should perform.
- Which registers are used as operands.
- Which register should receive the result.
- Whether the instruction contains an immediate value.
- Which instruction format is being used.

The decoder extracts these fields. Other CPU modules, such as the control unit, ALU control, register file, and immediate generator, interpret and use them.

**Important:** The instruction decoder extracts information; it does not execute the instruction.

---

## 2. RV32I Instruction Structure

RV32I uses fixed-length 32-bit instructions.

There are six instruction formats:

1. R-type
2. I-type
3. S-type
4. B-type
5. U-type
6. J-type

The different formats organize the 32 bits differently depending on the requirements of the instruction.

### 2.1 R-type

Used for register-to-register arithmetic and logical operations.

Examples:
- `add`
- `sub`
- `and`
- `or`
- `xor`
- `sll`
- `srl`
- `sra`
- `slt`
- `sltu`

| Field | Bits | Width |
|---|---|---:|
| funct7 | [31:25] | 7 |
| rs2 | [24:20] | 5 |
| rs1 | [19:15] | 5 |
| funct3 | [14:12] | 3 |
| rd | [11:7] | 5 |
| opcode | [6:0] | 7 |

### 2.2 I-type

Used for immediate arithmetic, loads, and register-indirect jumps.

Examples:
- `addi`
- `andi`
- `ori`
- `xori`
- `lw`
- `jalr`

| Field | Bits | Width |
|---|---|---:|
| immediate[11:0] | [31:20] | 12 |
| rs1 | [19:15] | 5 |
| funct3 | [14:12] | 3 |
| rd | [11:7] | 5 |
| opcode | [6:0] | 7 |

### 2.3 S-type

Used for store instructions.

Examples:
- `sw`
- `sh`
- `sb`

The immediate is divided into two parts.

| Field | Bits | Width |
|---|---|---:|
| immediate[11:5] | [31:25] | 7 |
| rs2 | [24:20] | 5 |
| rs1 | [19:15] | 5 |
| funct3 | [14:12] | 3 |
| immediate[4:0] | [11:7] | 5 |
| opcode | [6:0] | 7 |

### 2.4 B-type

Used for conditional branch instructions.

Examples:
- `beq`
- `bne`
- `blt`
- `bge`
- `bltu`
- `bgeu`

The immediate is distributed across multiple instruction fields.

| Field | Bits | Width |
|---|---|---:|
| immediate[12] | [31] | 1 |
| immediate[10:5] | [30:25] | 6 |
| rs2 | [24:20] | 5 |
| rs1 | [19:15] | 5 |
| funct3 | [14:12] | 3 |
| immediate[4:1] | [11:8] | 4 |
| immediate[11] | [7] | 1 |
| opcode | [6:0] | 7 |

### 2.5 U-type

Used for instructions that operate on upper immediate values.

Examples:
- `lui`
- `auipc`

| Field | Bits | Width |
|---|---|---:|
| immediate[31:12] | [31:12] | 20 |
| rd | [11:7] | 5 |
| opcode | [6:0] | 7 |

### 2.6 J-type

Used for jump instructions.

Example:
- `jal`

| Field | Bits | Width |
|---|---|---:|
| immediate[20] | [31] | 1 |
| immediate[10:1] | [30:21] | 10 |
| immediate[11] | [20] | 1 |
| immediate[19:12] | [19:12] | 8 |
| rd | [11:7] | 5 |
| opcode | [6:0] | 7 |

---

## 3. Fixed Bit Positions

One of the important design decisions in RISC-V is that several fields occupy fixed bit positions across different instruction formats.

For example:

| Instruction bits | R-type | I-type | S-type | B-type |
|---|---|---|---|---|
| [6:0] | opcode | opcode | opcode | opcode |
| [11:7] | rd | rd | imm[4:0] | imm[4:1], imm[11] |
| [14:12] | funct3 | funct3 | funct3 | funct3 |
| [19:15] | rs1 | rs1 | rs1 | rs1 |
| [24:20] | rs2 | imm[4:0] | rs2 | rs2 |
| [31:25] | funct7 | immediate | immediate | immediate |

This consistency makes instruction decoding relatively simple.

However, the meaning of a field depends on the instruction format.

For example, bits [11:7] represent the destination register (`rd`) in an R-type instruction, but they represent part of the immediate in an S-type instruction.

Therefore, extracting a field does not necessarily mean that the field is meaningful for every instruction.

---

## 4. Identifying the Instruction Format

The instruction format is primarily identified using the 7-bit opcode in bits [6:0].

### 4.1 Important RV32I Opcodes

| Opcode (binary) | Instruction category | Format |
|---|---|---|
| `0110011` | Register-register operations | R |
| `0010011` | Immediate arithmetic/logical operations | I |
| `0000011` | Load instructions | I |
| `0100011` | Store instructions | S |
| `1100011` | Conditional branches | B |
| `0110111` | Load upper immediate (`lui`) | U |
| `0010111` | Add upper immediate to PC (`auipc`) | U |
| `1101111` | Jump and link (`jal`) | J |
| `1100111` | Jump and link register (`jalr`) | I |

The opcode identifies the broad instruction category and, for these base RV32I instructions, determines the instruction format.

### 4.2 Identifying the Specific Operation

The opcode alone is not always enough to identify the exact instruction.

For example, consider:

```asm
add x3, x1, x2
sub x3, x1, x2
and x3, x1, x2
or  x3, x1, x2
```

All four instructions use the same opcode:

```text
0110011
```

To distinguish them, the CPU also examines `funct3` and `funct7`.

| Instruction | Opcode | funct3 | funct7 |
|---|---|---|---|
| ADD | `0110011` | `000` | `0000000` |
| SUB | `0110011` | `000` | `0100000` |
| AND | `0110011` | `111` | `0000000` |
| OR | `0110011` | `110` | `0000000` |

Thus:

- **Opcode:** identifies the broad instruction category.
- **funct3:** distinguishes operations within a category.
- **funct7:** provides additional operation information where required.

---

## 5. Example: Decoding an ADD Instruction

Consider:

```asm
add x3, x1, x2
```

Its 32-bit machine instruction is:

```text
0000000 00010 00001 000 00011 0110011
```

Breaking it into fields:

| Field | Extracted value | Meaning |
|---|---|---|
| opcode | `0110011` | R-type operation |
| rd | `00011` | x3 |
| funct3 | `000` | ADD/SUB operation group |
| rs1 | `00001` | x1 |
| rs2 | `00010` | x2 |
| funct7 | `0000000` | ADD |

The decoder extracts these fields.

The register file reads x1 and x2, the ALU performs addition, and the result is written into x3.

---

## 6. Instruction Decoder Verilog Implementation

File: `rtl/instruction_decoder.v`

```verilog
module instruction_decoder(
    input wire [31:0] instruction,

    output wire [6:0] opcode,
    output wire [4:0] rd,
    output wire [2:0] funct3,
    output wire [4:0] rs1,
    output wire [4:0] rs2,
    output wire [6:0] funct7
);

    assign opcode = instruction[6:0];
    assign rd     = instruction[11:7];
    assign funct3 = instruction[14:12];
    assign rs1    = instruction[19:15];
    assign rs2    = instruction[24:20];
    assign funct7 = instruction[31:25];

endmodule
```

### 6.1 Why Is the Implementation So Simple?

The decoder uses direct bit slicing.

For example:

```verilog
assign opcode = instruction[6:0];
```

This extracts the seven least significant bits of the instruction.

Similarly:

```verilog
assign rs1 = instruction[19:15];
```

This extracts the five-bit source register index.

There is no clock or sequential logic because instruction decoding is combinational.

The outputs change whenever the input instruction changes.

**Note:** The decoder extracts all these fields regardless of instruction type. The control logic determines which fields are meaningful and should be used.

---

## 7. Connection With Other CPU Modules

The instruction decoder is an important interface between instruction memory and the rest of the processor.

Its outputs are used by several modules.

| Module | Fields used | Purpose |
|---|---|---|
| Register file | rs1, rs2, rd | Select source and destination registers |
| Main control unit | opcode | Generate CPU control signals |
| ALU control | funct3, funct7, operation class | Select ALU operation |
| Immediate generator | Full instruction and immediate format selection | Reconstruct immediate value |

### 7.1 Overall Flow

```text
             Instruction Memory
                     |
                     | 32-bit instruction
                     v
             Instruction Decoder
                     |
          +----------+----------+
          |          |          |
          v          v          v
      Register    Main       Immediate
       File       Control    Generator
          |          |          |
          +----------+----------+
                     |
                     v
                ALU Control
                     |
                     v
                    ALU
```

The main control unit examines the opcode and generates signals such as:

- `RegWrite`
- `MemRead`
- `MemWrite`
- `MemToReg`
- `ALUSrc`
- `Branch`
- `Jump`
- `ImmSrc`

For example, a B-type branch instruction causes the control unit to select the B-type immediate format.

---

## 8. Important Design Distinction

There are two related but different tasks:

### Instruction Format Identification

Determines whether the instruction is:

- R-type
- I-type
- S-type
- B-type
- U-type
- J-type

This is primarily determined by the opcode.

### Instruction Operation Identification

Determines the actual operation:

- ADD
- SUB
- LW
- SW
- BEQ
- JAL
- etc.

This is determined by the opcode and, where necessary, `funct3` and `funct7`.

The instruction decoder extracts the fields. The control logic interprets them.

---

## 9. Summary

The RISC-V instruction decoder is relatively simple because of the consistent bit positions used across instruction formats.

Key points:

1. RV32I instructions are 32 bits wide.
2. There are six instruction formats: R, I, S, B, U, and J.
3. The opcode is always located in bits [6:0].
4. Several fields maintain fixed bit positions across formats.
5. The meaning of a field depends on the instruction format.
6. The opcode identifies the broad instruction category and format.
7. `funct3` and `funct7` help distinguish specific operations.
8. The decoder extracts fields; the control unit interprets them.
9. Instruction decoding is combinational logic.

### Next Implementation Steps

After the instruction decoder, the next modules to implement are:

1. **ALU Control:** Determines which ALU operation to execute.
2. **Main Control Unit:** Generates the control signals that coordinate the CPU datapath.
3. **Branch Unit:** Evaluates branch conditions such as equality and signed/unsigned comparisons.

These modules will allow us to begin integrating the individual components into our RV32I processor.