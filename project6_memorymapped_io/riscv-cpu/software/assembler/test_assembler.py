
# test_assembler.py

from encoder import encode_instruction


def check(mnemonic, operands, expected):

    actual = encode_instruction(mnemonic, operands)

    if actual != expected:
        print(f"FAIL: {mnemonic} {operands}")
        print(f"Expected: 0x{expected:08X}")
        print(f"Actual:   0x{actual:08X}")
        return False

    print(
        f"PASS: {mnemonic.upper():6} "
        f"{', '.join(operands):20} "
        f"0x{actual:08X}"
    )

    return True


def check_invalid(mnemonic, operands):

    try:
        encode_instruction(mnemonic, operands)

        print(f"FAIL: Expected rejection: {mnemonic} {operands}")
        return False

    except ValueError:
        print(f"PASS: Invalid instruction rejected: {mnemonic} {operands}")
        return True


def main():

    print("----------------------------------------")
    print("COMPLETE ASSEMBLER ENCODER TESTS")
    print("----------------------------------------")

    errors = 0

    # ----------------------------------------
    # R-type tests
    # ----------------------------------------

    r_tests = [
        ("add",  ["x7", "x5", "x6"], 0x006283B3),
        ("sub",  ["x7", "x5", "x6"], 0x406283B3),
        ("sll",  ["x7", "x5", "x6"], 0x006293B3),
        ("slt",  ["x7", "x5", "x6"], 0x0062A3B3),
        ("sltu", ["x7", "x5", "x6"], 0x0062B3B3),
        ("xor",  ["x7", "x5", "x6"], 0x0062C3B3),
        ("srl",  ["x7", "x5", "x6"], 0x0062D3B3),
        ("sra",  ["x7", "x5", "x6"], 0x4062D3B3),
        ("or",   ["x7", "x5", "x6"], 0x0062E3B3),
        ("and",  ["x7", "x5", "x6"], 0x0062F3B3),
    ]

    print("\nR-TYPE TESTS")

    for mnemonic, operands, expected in r_tests:

        if not check(mnemonic, operands, expected):
            errors += 1

    # ----------------------------------------
    # I-type arithmetic tests
    # ----------------------------------------

    i_tests = [
        ("addi",  ["x5", "x0", "10"],    0x00A00293),
        ("slti",  ["x5", "x6", "-1"],    0xFFF32293),
        ("sltiu", ["x5", "x6", "10"],    0x00A33293),
        ("xori",  ["x7", "x5", "0x55"],  0x0552C393),
        ("ori",   ["x7", "x5", "0x55"],  0x0552E393),
        ("andi",  ["x7", "x5", "0x55"],  0x0552F393),
    ]

    print("\nI-TYPE TESTS")

    for mnemonic, operands, expected in i_tests:

        if not check(mnemonic, operands, expected):
            errors += 1

    # ----------------------------------------
    # Shift immediate tests
    # ----------------------------------------

    shift_tests = [
        ("slli", ["x7", "x5", "3"], 0x00329393),
        ("srli", ["x7", "x5", "3"], 0x0032D393),
        ("srai", ["x7", "x5", "3"], 0x4032D393),
    ]

    print("\nSHIFT IMMEDIATE TESTS")

    for mnemonic, operands, expected in shift_tests:

        if not check(mnemonic, operands, expected):
            errors += 1

    # ----------------------------------------
    # Invalid input tests
    # ----------------------------------------

    print("\nINVALID INPUT TESTS")

    invalid_tests = [
        ("add",  ["x32", "x5", "x6"]),
        ("add",  ["x7", "x5", "x33"]),
        ("addi", ["x5", "x0", "2048"]),
        ("addi", ["x5", "x0", "-2049"]),
        ("slli", ["x7", "x5", "32"]),
        ("srai", ["x7", "x5", "-1"]),
        ("unknown", ["x1", "x2", "x3"]),
    ]

    for mnemonic, operands in invalid_tests:

        if not check_invalid(mnemonic, operands):
            errors += 1

    # ----------------------------------------
    # Load instruction tests
    # ----------------------------------------

    load_tests = [
        ("lb",  ["x5", "12(x6)"], 0x00C30283),
        ("lh",  ["x5", "12(x6)"], 0x00C31283),
        ("lw",  ["x5", "12(x6)"], 0x00C32283),
        ("lbu", ["x5", "12(x6)"], 0x00C34283),
        ("lhu", ["x5", "12(x6)"], 0x00C35283),
        ("lw",  ["x5", "-4(x6)"], 0xFFC32283),
    ]

    print("\nLOAD TESTS")

    for mnemonic, operands, expected in load_tests:
        if not check(mnemonic, operands, expected):
            errors += 1

    # ----------------------------------------
    # Store instruction tests
    # ----------------------------------------

    store_tests = [
        ("sb", ["x5", "8(x6)"],  0x00530423),
        ("sh", ["x5", "8(x6)"],  0x00531423),
        ("sw", ["x5", "8(x6)"],  0x00532423),
        ("sw", ["x5", "-8(x6)"], 0xFE532C23),
    ]

    print("\nSTORE TESTS")

    for mnemonic, operands, expected in store_tests:
        if not check(mnemonic, operands, expected):
            errors += 1

    # ----------------------------------------
    # Invalid memory operand tests
    # ----------------------------------------

    print("\nINVALID MEMORY TESTS")

    invalid_memory_tests = [
        ("lw", ["x5", "2048(x6)"]),
        ("sw", ["x5", "-2049(x6)"]),
        ("lw", ["x5", "12x6"]),
        ("sw", ["x32", "8(x6)"]),
    ]

    for mnemonic, operands in invalid_memory_tests:
        if not check_invalid(mnemonic, operands):
            errors += 1


    # ----------------------------------------
    # Branch tests
    # ----------------------------------------

    branch_tests = [
        ("beq",  ["x5", "x6", "16"], 0x00628863),
        ("bne",  ["x5", "x6", "16"], 0x00629863),
        ("blt",  ["x5", "x6", "16"], 0x0062C863),
        ("bge",  ["x5", "x6", "16"], 0x0062D863),
        ("bltu", ["x5", "x6", "16"], 0x0062E863),
        ("bgeu", ["x5", "x6", "16"], 0x0062F863),
        ("beq",  ["x5", "x6", "-16"], 0xFE6288E3),
    ]

    print("\nBRANCH TESTS")

    for mnemonic, operands, expected in branch_tests:
        if not check(mnemonic, operands, expected):
            errors += 1

    # ----------------------------------------
    # Jump tests
    # ----------------------------------------

    jump_tests = [
        ("jal",  ["x1", "16"], 0x010000EF),
        ("jal",  ["x0", "0"],  0x0000006F),
        ("jalr", ["x1", "0(x5)"], 0x000280E7),
        ("jalr", ["x0", "0(x1)"], 0x00008067),
    ]

    print("\nJUMP TESTS")

    for mnemonic, operands, expected in jump_tests:
        if not check(mnemonic, operands, expected):
            errors += 1

    # ----------------------------------------
    # Invalid branch and jump tests
    # ----------------------------------------

    invalid_control_tests = [
        ("beq", ["x5", "x6", "3"]),
        ("beq", ["x5", "x6", "4096"]),
        ("jal", ["x1", "1048576"]),
        ("jal", ["x1", "3"]),
        ("jalr", ["x1", "2048(x5)"]),
    ]

    print("\nINVALID BRANCH/JUMP TESTS")

    for mnemonic, operands in invalid_control_tests:
        if not check_invalid(mnemonic, operands):
            errors += 1

    # ----------------------------------------
    # U-type tests
    # ----------------------------------------

    u_tests = [
        ("lui",   ["x2", "4"], 0x00004137),
        ("lui",   ["x5", "0x12345"], 0x123452B7),
        ("auipc", ["x5", "4"], 0x00004297),
    ]

    print("\nU-TYPE TESTS")

    for mnemonic, operands, expected in u_tests:
        if not check(mnemonic, operands, expected):
            errors += 1


    invalid_u_tests = [
        ("lui", ["x32", "4"]),
        ("lui", ["x2", "1048576"]),
    ]
    
    print("\nINVALID U-TYPE TESTS")

    for mnemonic, operands in invalid_u_tests:
        if not check_invalid(mnemonic, operands):
            errors += 1
    # ----------------------------------------
    # Final result
    # ----------------------------------------

    print("\n----------------------------------------")

    if errors == 0:
        print("ALL ENCODER TESTS PASSED")
    else:
        print(f"ENCODER TESTS FAILED: {errors} errors")

    print("----------------------------------------")

    


if __name__ == "__main__":
    main()

    

