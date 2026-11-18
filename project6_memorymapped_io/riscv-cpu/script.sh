
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


# iverilog -g2012 -Wall -s data_memory_tb -o data_memory_sim \
#                      rtl/main_ram.v \
#                      rtl/data_memory.v \
#                      testbench/data_memory_tb.v

# vvp data_memory_sim




# iverilog -g2012 -Wall -s cpu_memory_tb -o cpu_memory_sim \
#     rtl/*.v \
#     chips/arithmetic/*.v \
#     chips/logic/*.v \
#     testbench/cpu_memory_tb.v

# vvp cpu_memory_sim




# iverilog -g2012 -Wall -s cpu_memory_full_tb -o cpu_memory_full_sim \
#     rtl/*.v \
#     chips/arithmetic/*.v \
#     chips/logic/*.v \
#     testbench/cpu_memory_full_tb.v


# vvp cpu_memory_full_sim
