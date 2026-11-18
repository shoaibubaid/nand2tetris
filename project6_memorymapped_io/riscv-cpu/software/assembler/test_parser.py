
# test_parser.py

from parser import parse_line


def check(line, expected):

    actual = parse_line(line)

    if actual == expected:
        print(f"PASS: {line!r}")
    else:
        print(f"FAIL: {line!r}")
        print(f"Expected: {expected}")
        print(f"Actual:   {actual}")


def check_invalid(line):

    try:
        parse_line(line)
        print(f"FAIL: Expected invalid input: {line!r}")

    except ValueError:
        print(f"PASS: Invalid input rejected: {line!r}")


def main():

    print("--------------------------------")
    print("ASSEMBLY PARSER TESTS")
    print("--------------------------------")

    # Normal instructions
    check(
        "addi x5, x0, 10",
        ("addi", ["x5", "x0", "10"])
    )

    check(
        "add x7, x5, x6",
        ("add", ["x7", "x5", "x6"])
    )

    # Whitespace handling
    check(
        "    addi    x5,   x0,   10   ",
        ("addi", ["x5", "x0", "10"])
    )

    check(
        "\tadd x7, x5, x6",
        ("add", ["x7", "x5", "x6"])
    )

    # Case handling
    check(
        "ADDI X5, X0, 10",
        ("addi", ["X5", "X0", "10"])
    )

    # Comments
    check(
        "addi x5, x0, 10 # initialize x5",
        ("addi", ["x5", "x0", "10"])
    )

    # Empty and comment-only lines
    check("", None)
    check("     ", None)
    check("# this is a comment", None)

    # Missing operands
    check_invalid("add x5,,x6")
    check_invalid("add x5, x6,")
    check_invalid("add ,x5,x6")

    print("--------------------------------")
    print("PARSER TESTS COMPLETED")
    print("--------------------------------")


if __name__ == "__main__":
    main()
