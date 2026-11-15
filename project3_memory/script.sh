#!/bin/bash

sources=$(find chips \
    ../project2_booleanarithmetic/chips \
    ../project1_booleanlogic/gates \
    -name "*.v")

test="$1"

iverilog -g2012 -o sim $sources "$test" && vvp sim