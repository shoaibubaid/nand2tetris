
# assembler.py

from parser import parse_program
from encoder import encode_instruction


def assemble(input_file):

    program = parse_program(input_file)

    # ========================================
    # PASS 1: Build the symbol table
    # ========================================

    symbols = {}
    instructions = []

    pc = 0

    for line_number, label, mnemonic, operands in program:

        # Record label address.
        if label is not None:

            if label in symbols:
                raise ValueError(
                    f"Line {line_number}: "
                    f"Duplicate label '{label}'"
                )

            symbols[label] = pc

        # Label-only lines do not contain instructions.
        if mnemonic is None:
            continue

        instructions.append(
            (line_number, pc, mnemonic, operands)
        )

        pc += 4

    print("SYMBOL TABLE")
    print("----------------------------------------")

    for label, address in symbols.items():
        print(f"{label:15} 0x{address:08X}")

    # ========================================
    # PASS 2: Generate machine code
    # ========================================

    machine_code = []

    print("\nGENERATED INSTRUCTIONS")
    print("----------------------------------------")

    for line_number, pc, mnemonic, operands in instructions:

        operands = operands.copy()

        try:

            # Resolve branch labels.
            if mnemonic in (
                "beq", "bne", "blt",
                "bge", "bltu", "bgeu"
            ):

                target = operands[2]

                if target in symbols:
                    offset = symbols[target] - pc
                    operands[2] = str(offset)

            # Resolve JAL labels.
            elif mnemonic == "jal":

                target = operands[1]

                if target in symbols:
                    offset = symbols[target] - pc
                    operands[1] = str(offset)

            encoded = encode_instruction(mnemonic, operands)

            machine_code.append(encoded)

            print(
                f"0x{pc:08X}: "
                f"{mnemonic:6} "
                f"{', '.join(operands):15} "
                f"0x{encoded:08X}"
            )

        except ValueError as error:

            raise ValueError(
                f"Line {line_number}: {error}"
            )

    return machine_code


def write_hex(machine_code, output_file):

    with open(output_file, "w") as output:

        for instruction in machine_code:
            output.write(f"{instruction:08x}\n")

    print(f"\nGenerated HEX file: {output_file}")
    print(f"Instructions written: {len(machine_code)}")



if __name__ == "__main__":

    # input_file = "labels_demo.asm"
    # output_file = "program.hex"

    # input_file = "function_demo.asm"
    # output_file = "program.hex"

    # input_file = "nested_function_demo.asm"
    # output_file = "program.hex"

    # input_file = "stack_frame_demo.asm"
    # output_file = "program.hex"

    # input_file = "multiple_arguments_demo.asm"
    # output_file = "program.hex"

    # input_file = "draw_pixel_demo.asm"
    # output_file = "program.hex"

    # input_file = "draw_rectangle_demo.asm"
    # output_file = "program.hex"


    # input_file = "clear_screen_demo.asm"
    # output_file = "program.hex"

    # input_file = "keyboard_demo.asm"
    # output_file = "program.hex"

    # input_file = "read_key_demo.asm"
    # output_file = "program.hex"

    # input_file = "timer_demo.asm"
    # output_file = "program.hex"

    # input_file = "keyboard_square.asm"
    # output_file = "program.hex"

    input_file = "pong.asm"
    output_file = "pong.hex"

    result = assemble(input_file)

    write_hex(result, output_file)

