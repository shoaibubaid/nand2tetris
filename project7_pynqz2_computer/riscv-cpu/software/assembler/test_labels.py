
from assembler import assemble


expected = [
    0x00300293,
    0xFFF28293,
    0xFE029EE3,
    0x0000006F,
]

actual = assemble("labels_demo.asm")

if actual == expected:
    print("\nALL LABEL RESOLUTION TESTS PASSED")
else:
    print("\nLABEL RESOLUTION TEST FAILED")
    print("Expected:", [f"{x:08x}" for x in expected])
    print("Actual:  ", [f"{x:08x}" for x in actual])
