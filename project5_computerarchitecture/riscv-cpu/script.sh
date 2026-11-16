
#!/bin/bash

set -e

echo "Compiling RV32I CPU..."

iverilog -g2012 -Wall -s rectangle_tb -o rectangle_sim \
    chips/arithmetic/*.v \
    chips/logic/*.v \
    chips/memory/*.v \
    chips/sequential/*.v \
    rtl/*.v \
    testbench/rectangle_tb.v

echo "Compilation successful."
echo "Running rectangle generator..."

vvp rectangle_sim
