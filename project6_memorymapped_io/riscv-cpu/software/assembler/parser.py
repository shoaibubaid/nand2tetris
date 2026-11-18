
# parser.py

def remove_comment(line):
    """
    Remove everything after #.
    """
    return line.split("#", 1)[0].strip()


def parse_line(line):
    """
    Parse one assembly line.

    Example:
        'addi x5, x0, 10'

    Returns:
        ('addi', ['x5', 'x0', '10'])

    Empty/comment-only lines return None.
    """

    line = remove_comment(line)

    if not line:
        return None

    # Split instruction from its operands.
    parts = line.split(None, 1)

    mnemonic = parts[0].lower()

    if len(parts) == 1:
        operands = []
    else:
        operand_text = parts[1]

        # Split operands using commas.
        operands = [
            operand.strip()
            for operand in operand_text.split(",")
        ]

        # Reject missing operands.
        if any(not operand for operand in operands):
            raise ValueError(
                f"Invalid operand list: {line}"
            )

    return mnemonic, operands


def parse_file(filename):
    """
    Parse an entire assembly source file.

    Returns a list of:
        (line_number, mnemonic, operands)
    """

    instructions = []

    with open(filename, "r") as source:

        for line_number, line in enumerate(source, start=1):

            try:
                parsed = parse_line(line)

                if parsed is None:
                    continue

                mnemonic, operands = parsed

                instructions.append(
                    (line_number, mnemonic, operands)
                )

            except ValueError as error:
                raise ValueError(
                    f"Line {line_number}: {error}"
                )

    return instructions




import re


LABEL_PATTERN = re.compile(
    r"^([A-Za-z_][A-Za-z0-9_]*):"
)


def parse_source_line(line):
    """
    Parse a source line that may contain a label.

    Examples:
        loop:
        loop: addi x5, x5, -1
        bne x5, x0, loop

    Returns:
        (label, mnemonic, operands)

    Any missing field is None.
    """

    line = remove_comment(line)

    if not line:
        return None, None, None

    label = None

    match = LABEL_PATTERN.match(line)

    if match:
        label = match.group(1)
        line = line[match.end():].strip()

    if not line:
        return label, None, None

    mnemonic, operands = parse_line(line)

    return label, mnemonic, operands


def parse_program(filename):
    """
    Parse the entire source file.

    Returns:
        A list of:
        (line_number, label, mnemonic, operands)
    """

    program = []

    with open(filename, "r") as source:

        for line_number, line in enumerate(source, start=1):

            label, mnemonic, operands = parse_source_line(line)

            if label is None and mnemonic is None:
                continue

            program.append(
                (line_number, label, mnemonic, operands)
            )

    return program
