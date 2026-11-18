
# encoder.py
#
# Encodes R-type and I-type arithmetic instructions
# supported by our custom RISC-V CPU.

# --------------------------------------------------
# Opcodes
# --------------------------------------------------

OP_R_TYPE = 0b0110011
OP_I_TYPE = 0b0010011


# --------------------------------------------------
# R-type instruction definitions
# mnemonic: (funct3, funct7)
# --------------------------------------------------

R_TYPE = {
    "add":  (0b000, 0b0000000),
    "sub":  (0b000, 0b0100000),
    "sll":  (0b001, 0b0000000),
    "slt":  (0b010, 0b0000000),
    "sltu": (0b011, 0b0000000),
    "xor":  (0b100, 0b0000000),
    "srl":  (0b101, 0b0000000),
    "sra":  (0b101, 0b0100000),
    "or":   (0b110, 0b0000000),
    "and":  (0b111, 0b0000000),
}


# --------------------------------------------------
# I-type arithmetic instruction definitions
# mnemonic: funct3
# --------------------------------------------------

I_TYPE = {
    "addi": 0b000,
    "slti": 0b010,
    "sltiu": 0b011,
    "xori": 0b100,
    "ori":  0b110,
    "andi": 0b111,
}


# --------------------------------------------------
# Shift immediate instructions
# mnemonic: (funct3, funct7)
# --------------------------------------------------

SHIFT_I_TYPE = {
    "slli": (0b001, 0b0000000),
    "srli": (0b101, 0b0000000),
    "srai": (0b101, 0b0100000),
}


# --------------------------------------------------
# Register parser
# --------------------------------------------------


REGISTER_ALIASES = {
    "zero": 0,
    "ra": 1,
    "sp": 2,
    "gp": 3,
    "tp": 4,
    "t0": 5,
    "t1": 6,
    "t2": 7,
    "s0": 8,
    "fp": 8,
    "s1": 9,
    "a0": 10,
    "a1": 11,
    "a2": 12,
    "a3": 13,
    "a4": 14,
    "a5": 15,
    "a6": 16,
    "a7": 17,
    "s2": 18,
    "s3": 19,
    "s4": 20,
    "s5": 21,
    "s6": 22,
    "s7": 23,
    "s8": 24,
    "s9": 25,
    "s10": 26,
    "s11": 27,
    "t3": 28,
    "t4": 29,
    "t5": 30,
    "t6": 31,
}

def parse_register(register):
    register = register.strip().lower()

    if register in REGISTER_ALIASES:
        return REGISTER_ALIASES[register]

    if register.startswith("x"):
        try:
            number = int(register[1:])
            if 0 <= number <= 31:
                return number
        except ValueError:
            pass

    raise ValueError(
        f"Invalid register '{register}'. "
        "Use x0-x31 or a valid RISC-V ABI register name."
    )



# --------------------------------------------------
# Immediate parser
# --------------------------------------------------

def parse_integer(value):
    value = value.strip().lower()

    try:
        return int(value, 0)
    except ValueError:
        raise ValueError(f"Invalid immediate '{value}'.")


# --------------------------------------------------
# R-type encoder
#
# Format:
# funct7 | rs2 | rs1 | funct3 | rd | opcode
#   7    |  5  |  5  |   3    |  5 |   7
# --------------------------------------------------

def encode_r_type(mnemonic, rd, rs1, rs2):

    mnemonic = mnemonic.lower()

    if mnemonic not in R_TYPE:
        raise ValueError(
            f"Unsupported R-type instruction: {mnemonic}"
        )

    rd = parse_register(rd)
    rs1 = parse_register(rs1)
    rs2 = parse_register(rs2)

    funct3, funct7 = R_TYPE[mnemonic]

    instruction = (
        (funct7 << 25) |
        (rs2 << 20) |
        (rs1 << 15) |
        (funct3 << 12) |
        (rd << 7) |
        OP_R_TYPE
    )

    return instruction


# --------------------------------------------------
# I-type encoder
#
# Format:
# immediate[11:0] | rs1 | funct3 | rd | opcode
#       12        |  5  |   3    |  5 |   7
# --------------------------------------------------

def encode_i_type(mnemonic, rd, rs1, immediate):

    mnemonic = mnemonic.lower()

    if mnemonic not in I_TYPE:
        raise ValueError(
            f"Unsupported I-type instruction: {mnemonic}"
        )

    rd = parse_register(rd)
    rs1 = parse_register(rs1)
    immediate = parse_integer(immediate)

    if not -2048 <= immediate <= 2047:
        raise ValueError(
            f"I-type immediate out of range: {immediate}"
        )

    immediate &= 0xFFF
    funct3 = I_TYPE[mnemonic]

    instruction = (
        (immediate << 20) |
        (rs1 << 15) |
        (funct3 << 12) |
        (rd << 7) |
        OP_I_TYPE
    )

    return instruction


# --------------------------------------------------
# Shift immediate encoder
#
# Shift immediate:
# funct7 | shamt
#   7    |   5
# --------------------------------------------------

def encode_shift_i_type(mnemonic, rd, rs1, shamt):

    mnemonic = mnemonic.lower()

    if mnemonic not in SHIFT_I_TYPE:
        raise ValueError(
            f"Unsupported shift instruction: {mnemonic}"
        )

    rd = parse_register(rd)
    rs1 = parse_register(rs1)
    shamt = parse_integer(shamt)

    if not 0 <= shamt <= 31:
        raise ValueError(
            f"Shift amount must be between 0 and 31: {shamt}"
        )

    funct3, funct7 = SHIFT_I_TYPE[mnemonic]

    immediate = (funct7 << 5) | shamt

    instruction = (
        (immediate << 20) |
        (rs1 << 15) |
        (funct3 << 12) |
        (rd << 7) |
        OP_I_TYPE
    )

    return instruction


# --------------------------------------------------
# Public encoder interface
# --------------------------------------------------

def encode_instruction(mnemonic, operands):

    mnemonic = mnemonic.lower()

    if mnemonic in R_TYPE:
        if len(operands) != 3:
            raise ValueError(
                f"{mnemonic} expects 3 operands: rd, rs1, rs2"
            )

        return encode_r_type(
            mnemonic,
            operands[0],
            operands[1],
            operands[2]
        )

    elif mnemonic in I_TYPE:
        if len(operands) != 3:
            raise ValueError(
                f"{mnemonic} expects 3 operands: rd, rs1, immediate"
            )

        return encode_i_type(
            mnemonic,
            operands[0],
            operands[1],
            operands[2]
        )

    elif mnemonic in SHIFT_I_TYPE:
        if len(operands) != 3:
            raise ValueError(
                f"{mnemonic} expects 3 operands: rd, rs1, shamt"
            )

        return encode_shift_i_type(
            mnemonic,
            operands[0],
            operands[1],
            operands[2]
        )

    
    elif mnemonic in LOAD_TYPE:
        if len(operands) != 2:
            raise ValueError(
                f"{mnemonic} expects: rd, offset(rs1)"
            )

        return encode_load(
            mnemonic,
            operands[0],
            operands[1]
        )

    elif mnemonic in STORE_TYPE:
        if len(operands) != 2:
            raise ValueError(
                f"{mnemonic} expects: rs2, offset(rs1)"
            )

        return encode_store(
            mnemonic,
            operands[0],
            operands[1]
        )


    elif mnemonic in BRANCH_TYPE:
        if len(operands) != 3:
            raise ValueError(
                f"{mnemonic} expects: rs1, rs2, offset"
            )

        return encode_branch(
            mnemonic,
            operands[0],
            operands[1],
            operands[2]
        )

    elif mnemonic == "jal":
        if len(operands) != 2:
            raise ValueError("jal expects: rd, offset")

        return encode_jal(
            operands[0],
            operands[1]
        )

    elif mnemonic == "jalr":
        if len(operands) != 2:
            raise ValueError("jalr expects: rd, offset(rs1)")

        offset, rs1 = parse_memory_operand(operands[1])

        return encode_jalr(
            operands[0],
            f"x{rs1}",
            offset
        )

    elif mnemonic in U_TYPE:
        if len(operands) != 2:
            raise ValueError(
                f"{mnemonic} expects: rd, immediate"
            )

        return encode_u_type(
            mnemonic,
            operands[0],
            operands[1]
        )

    else:
        raise ValueError(
            f"Unsupported instruction: {mnemonic}"
        )


# --------------------------------------------------
# Standalone demonstration
# --------------------------------------------------

if __name__ == "__main__":

    examples = [
        ("add",  ["x7", "x5", "x6"]),
        ("sub",  ["x7", "x5", "x6"]),
        ("addi", ["x5", "x0", "10"]),
        ("slti", ["x5", "x6", "-1"]),
        ("xori", ["x7", "x5", "0x55"]),
        ("slli", ["x7", "x5", "3"]),
        ("srai", ["x7", "x5", "3"]),
    ]

    for mnemonic, operands in examples:

        machine_code = encode_instruction(
            mnemonic,
            operands
        )

        print(
            f"{mnemonic.upper():6} "
            f"{', '.join(operands):20} "
            f"0x{machine_code:08X}"
        )


OP_LOAD  = 0b0000011
OP_STORE = 0b0100011

LOAD_TYPE = {
    "lb":  0b000,
    "lh":  0b001,
    "lw":  0b010,
    "lbu": 0b100,
    "lhu": 0b101,
}

STORE_TYPE = {
    "sb": 0b000,
    "sh": 0b001,
    "sw": 0b010,
}


import re



def parse_memory_operand(operand):
    operand = operand.strip()

    match = re.fullmatch(r"([+-]?(?:0[xX][0-9a-fA-F]+|\d+))\s*\(\s*([A-Za-z0-9]+)\s*\)", operand)

    if not match:
        raise ValueError(f"Invalid memory operand: {operand}")

    offset = parse_integer(match.group(1))
    rs1 = parse_register(match.group(2))

    return offset, rs1




def encode_load(mnemonic, rd, memory_operand):

    mnemonic = mnemonic.lower()

    if mnemonic not in LOAD_TYPE:
        raise ValueError(f"Unsupported load: {mnemonic}")

    rd = parse_register(rd)
    offset, rs1 = parse_memory_operand(memory_operand)

    if not -2048 <= offset <= 2047:
        raise ValueError(f"Load offset out of range: {offset}")

    immediate = offset & 0xFFF
    funct3 = LOAD_TYPE[mnemonic]

    instruction = (
        (immediate << 20) |
        (rs1 << 15) |
        (funct3 << 12) |
        (rd << 7) |
        OP_LOAD
    )

    return instruction



def encode_store(mnemonic, rs2, memory_operand):

    mnemonic = mnemonic.lower()

    if mnemonic not in STORE_TYPE:
        raise ValueError(f"Unsupported store: {mnemonic}")

    rs2 = parse_register(rs2)
    offset, rs1 = parse_memory_operand(memory_operand)

    if not -2048 <= offset <= 2047:
        raise ValueError(f"Store offset out of range: {offset}")

    immediate = offset & 0xFFF

    imm_11_5 = (immediate >> 5) & 0x7F
    imm_4_0 = immediate & 0x1F

    funct3 = STORE_TYPE[mnemonic]

    instruction = (
        (imm_11_5 << 25) |
        (rs2 << 20) |
        (rs1 << 15) |
        (funct3 << 12) |
        (imm_4_0 << 7) |
        OP_STORE
    )

    return instruction




OP_BRANCH = 0b1100011
OP_JAL = 0b1101111
OP_JALR = 0b1100111

BRANCH_TYPE = {
    "beq":  0b000,
    "bne":  0b001,
    "blt":  0b100,
    "bge":  0b101,
    "bltu": 0b110,
    "bgeu": 0b111,
}


def encode_branch(mnemonic, rs1, rs2, offset):

    mnemonic = mnemonic.lower()

    if mnemonic not in BRANCH_TYPE:
        raise ValueError(f"Unsupported branch: {mnemonic}")

    rs1 = parse_register(rs1)
    rs2 = parse_register(rs2)
    offset = parse_integer(offset)

    if not -4096 <= offset <= 4094:
        raise ValueError("Branch offset out of range")

    if offset % 2 != 0:
        raise ValueError("Branch offset must be 2-byte aligned")

    immediate = offset & 0x1FFF

    imm_12 = (immediate >> 12) & 1
    imm_10_5 = (immediate >> 5) & 0x3F
    imm_4_1 = (immediate >> 1) & 0xF
    imm_11 = (immediate >> 11) & 1

    funct3 = BRANCH_TYPE[mnemonic]

    instruction = (
        (imm_12 << 31) |
        (imm_10_5 << 25) |
        (rs2 << 20) |
        (rs1 << 15) |
        (funct3 << 12) |
        (imm_4_1 << 8) |
        (imm_11 << 7) |
        OP_BRANCH
    )

    return instruction


def encode_jal(rd, offset):

    rd = parse_register(rd)
    offset = parse_integer(offset)

    if not -1048576 <= offset <= 1048574:
        raise ValueError("JAL offset out of range")

    if offset % 2 != 0:
        raise ValueError("JAL offset must be 2-byte aligned")

    immediate = offset & 0x1FFFFF

    imm_20 = (immediate >> 20) & 1
    imm_10_1 = (immediate >> 1) & 0x3FF
    imm_11 = (immediate >> 11) & 1
    imm_19_12 = (immediate >> 12) & 0xFF

    instruction = (
        (imm_20 << 31) |
        (imm_10_1 << 21) |
        (imm_11 << 20) |
        (imm_19_12 << 12) |
        (rd << 7) |
        OP_JAL
    )

    return instruction


def encode_jalr(rd, rs1, offset):

    rd = parse_register(rd)
    rs1 = parse_register(rs1)

    if not isinstance(offset, int):
        offset = parse_integer(offset)

    if not -2048 <= offset <= 2047:
        raise ValueError("JALR offset out of range")

    immediate = offset & 0xFFF

    instruction = (
        (immediate << 20) |
        (rs1 << 15) |
        (0b000 << 12) |
        (rd << 7) |
        OP_JALR
    )

    return instruction


OP_LUI   = 0b0110111
OP_AUIPC = 0b0010111


U_TYPE = {
    "lui": OP_LUI,
    "auipc": OP_AUIPC,
}


def encode_u_type(mnemonic, rd, immediate):

    mnemonic = mnemonic.lower()

    if mnemonic not in U_TYPE:
        raise ValueError(f"Unsupported U-type instruction: {mnemonic}")

    rd = parse_register(rd)
    immediate = parse_integer(immediate)

    if not -524288 <= immediate <= 1048575:
        raise ValueError("U-type immediate out of range")

    immediate &= 0xFFFFF

    instruction = (
        (immediate << 12) |
        (rd << 7) |
        U_TYPE[mnemonic]
    )

    return instruction

