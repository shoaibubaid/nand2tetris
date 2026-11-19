
# #!/bin/bash

# set -e

# echo "Compiling RV32I CPU..."

# iverilog -g2012 -Wall -s rectangle_tb -o rectangle_sim \
#     chips/arithmetic/*.v \
#     chips/logic/*.v \
#     chips/memory/*.v \
#     chips/sequential/*.v \
#     rtl/*.v \
#     testbench/rectangle_tb.v

# echo "Compilation successful."
# echo "Running rectangle generator..."

# vvp rectangle_sim


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



# iverilog -g2012 -Wall -s address_decoder_tb -o address_decoder_sim \
#                      rtl/address_decoder.v \
#                      testbench/address_decoder_tb.v

# vvp address_decoder_sim



# iverilog -g2012 -o memory_subsystem_test \
#     testbench/memory_subsystem_tb.v \
#     rtl/memory_subsystem.v \
#     rtl/address_decoder.v \
#     rtl/data_memory.v \
#     rtl/main_ram.v

# vvp memory_subsystem_test




# iverilog -g2012 -o framebuffer_test \
#     testbench/framebuffer_tb.v \
#     rtl/framebuffer.v

# vvp framebuffer_test



# iverilog -g2012 -o memory_subsystem_test \
#     testbench/memory_subsystem_tb.v \
#     rtl/memory_subsystem.v \
#     rtl/address_decoder.v \
#     rtl/data_memory.v \
#     rtl/framebuffer.v \
#     rtl/main_ram.v

# vvp memory_subsystem_test



# iverilog -g2012 -o cpu_framebuffer_test \
#     testbench/cpu_framebuffer_tb.v \
#     ../../project1_booleanlogic/gates/mux.v \
#     ../../project1_booleanlogic/gates/and_gate.v \
#     ../../project1_booleanlogic/gates/not_gate.v \
#     ../../project1_booleanlogic/gates/nand_gate.v \
#     ../../project1_booleanlogic/gates/or_gate.v \
#     ../../project3_memory/chips/dff.v \
#     ../../project3_memory/chips/register.v \
#     rtl/cpu.v \
#     rtl/instruction_memory.v \
#     rtl/instruction_decoder.v \
#     rtl/control_unit.v \
#     rtl/register_file.v \
#     rtl/immediate_generator.v \
#     rtl/alu_control.v \
#     rtl/branch_unit.v \
#     rtl/data_memory.v \
#     rtl/memory_subsystem.v \
#     rtl/address_decoder.v \
#     rtl/framebuffer.v \
#     rtl/main_ram.v \
#     rtl/next_pc_logic.v \
#     chips/arithmetic/add32.v \
#     chips/arithmetic/alu32.v \
#     chips/arithmetic/inc32.v \
#     chips/logic/mux32.v \
#     chips/sequential/pc32.v \
#     chips/sequential/register32.v

# vvp cpu_framebuffer_test




# iverilog -g2012 -s cpu_assembler_tb -o cpu_assembler_test \
#     testbench/cpu_assembler_tb.v \
#     ../../project1_booleanlogic/gates/mux.v \
#     ../../project1_booleanlogic/gates/and_gate.v \
#     ../../project1_booleanlogic/gates/not_gate.v \
#     ../../project1_booleanlogic/gates/nand_gate.v \
#     ../../project1_booleanlogic/gates/or_gate.v \
#     ../../project3_memory/chips/dff.v \
#     ../../project3_memory/chips/register.v \
#     rtl/cpu.v \
#     rtl/instruction_memory.v \
#     rtl/instruction_decoder.v \
#     rtl/control_unit.v \
#     rtl/register_file.v \
#     rtl/immediate_generator.v \
#     rtl/alu_control.v \
#     rtl/branch_unit.v \
#     rtl/data_memory.v \
#     rtl/memory_subsystem.v \
#     rtl/address_decoder.v \
#     rtl/framebuffer.v \
#     rtl/main_ram.v \
#     rtl/peripherals/keyboard_fifo.v \
#     rtl/peripherals/usb_keyboard_bridge.v \
#     rtl/peripherals/keyboard_controller.v \
#     rtl/peripherals/timer.v \
#     rtl/next_pc_logic.v \
#     chips/arithmetic/add32.v \
#     chips/arithmetic/alu32.v \
#     chips/arithmetic/inc32.v \
#     chips/logic/mux32.v \
#     chips/sequential/pc32.v \
#     chips/sequential/register32.v

# vvp cpu_function_test




# iverilog -g2012 -s cpu_drawrectangle_tb -o cpu_drawrectangle_test \
#     testbench/cpu_drawrectangle_tb.v \
#     ../../project1_booleanlogic/gates/mux.v \
#     ../../project1_booleanlogic/gates/and_gate.v \
#     ../../project1_booleanlogic/gates/not_gate.v \
#     ../../project1_booleanlogic/gates/nand_gate.v \
#     ../../project1_booleanlogic/gates/or_gate.v \
#     ../../project3_memory/chips/dff.v \
#     ../../project3_memory/chips/register.v \
#     rtl/cpu.v \
#     rtl/instruction_memory.v \
#     rtl/instruction_decoder.v \
#     rtl/control_unit.v \
#     rtl/register_file.v \
#     rtl/immediate_generator.v \
#     rtl/alu_control.v \
#     rtl/branch_unit.v \
#     rtl/data_memory.v \
#     rtl/memory_subsystem.v \
#     rtl/address_decoder.v \
#     rtl/framebuffer.v \
#     rtl/main_ram.v \
#     rtl/peripherals/keyboard_fifo.v \
#     rtl/peripherals/usb_keyboard_bridge.v \
#     rtl/peripherals/keyboard_controller.v \
#     rtl/peripherals/timer.v \
#     rtl/next_pc_logic.v \
#     chips/arithmetic/add32.v \
#     chips/arithmetic/alu32.v \
#     chips/arithmetic/inc32.v \
#     chips/logic/mux32.v \
#     chips/sequential/pc32.v \
#     chips/sequential/register32.v

# vvp cpu_drawrectangle_test


# iverilog -g2012 -s cpu_pong_tb -o cpu_pong_test \
#     testbench/cpu_pong_tb.v \
#     ../../project1_booleanlogic/gates/mux.v \
#     ../../project1_booleanlogic/gates/and_gate.v \
#     ../../project1_booleanlogic/gates/not_gate.v \
#     ../../project1_booleanlogic/gates/nand_gate.v \
#     ../../project1_booleanlogic/gates/or_gate.v \
#     ../../project3_memory/chips/dff.v \
#     ../../project3_memory/chips/register.v \
#     rtl/cpu.v \
#     rtl/instruction_memory.v \
#     rtl/instruction_decoder.v \
#     rtl/control_unit.v \
#     rtl/register_file.v \
#     rtl/immediate_generator.v \
#     rtl/alu_control.v \
#     rtl/branch_unit.v \
#     rtl/data_memory.v \
#     rtl/memory_subsystem.v \
#     rtl/address_decoder.v \
#     rtl/framebuffer.v \
#     rtl/main_ram.v \
#     rtl/peripherals/keyboard_fifo.v \
#     rtl/peripherals/usb_keyboard_bridge.v \
#     rtl/peripherals/keyboard_controller.v \
#     rtl/peripherals/timer.v \
#     rtl/next_pc_logic.v \
#     chips/arithmetic/add32.v \
#     chips/arithmetic/alu32.v \
#     chips/arithmetic/inc32.v \
#     chips/logic/mux32.v \
#     chips/sequential/pc32.v \
#     chips/sequential/register32.v




# iverilog -g2012 -s cpu_pong_tb -o cpu_pong_test \
#     testbench/cpu_pong_tb.v \
#     ../../project1_booleanlogic/gates/mux.v \
#     ../../project1_booleanlogic/gates/and_gate.v \
#     ../../project1_booleanlogic/gates/not_gate.v \
#     ../../project1_booleanlogic/gates/nand_gate.v \
#     ../../project1_booleanlogic/gates/or_gate.v \
#     ../../project3_memory/chips/dff.v \
#     ../../project3_memory/chips/register.v \
#     rtl/cpu.v \
#     rtl/instruction_memory.v \
#     rtl/instruction_decoder.v \
#     rtl/control_unit.v \
#     rtl/register_file.v \
#     rtl/immediate_generator.v \
#     rtl/alu_control.v \
#     rtl/branch_unit.v \
#     rtl/data_memory.v \
#     rtl/memory_subsystem.v \
#     rtl/address_decoder.v \
#     rtl/framebuffer.v \
#     rtl/main_ram.v \
#     rtl/peripherals/keyboard_fifo.v \
#     rtl/peripherals/usb_keyboard_bridge.v \
#     rtl/peripherals/keyboard_controller.v \
#     rtl/peripherals/timer.v \
#     rtl/next_pc_logic.v \
#     chips/arithmetic/add32.v \
#     chips/arithmetic/alu32.v \
#     chips/arithmetic/inc32.v \
#     chips/logic/mux32.v \
#     chips/sequential/pc32.v \
#     chips/sequential/register32.v


iverilog -g2012 -s cpu_pong_tb -o cpu_pong_interactive \
    testbench/cpu_pong_interactive_tb.v \
    ../../project1_booleanlogic/gates/mux.v \
    ../../project1_booleanlogic/gates/and_gate.v \
    ../../project1_booleanlogic/gates/not_gate.v \
    ../../project1_booleanlogic/gates/nand_gate.v \
    ../../project1_booleanlogic/gates/or_gate.v \
    ../../project3_memory/chips/dff.v \
    ../../project3_memory/chips/register.v \
    rtl/cpu.v \
    rtl/instruction_memory.v \
    rtl/instruction_decoder.v \
    rtl/control_unit.v \
    rtl/register_file.v \
    rtl/immediate_generator.v \
    rtl/alu_control.v \
    rtl/branch_unit.v \
    rtl/data_memory.v \
    rtl/memory_subsystem.v \
    rtl/address_decoder.v \
    rtl/framebuffer.v \
    rtl/main_ram.v \
    rtl/peripherals/keyboard_fifo.v \
    rtl/peripherals/usb_keyboard_bridge.v \
    rtl/peripherals/keyboard_controller.v \
    rtl/peripherals/timer.v \
    rtl/next_pc_logic.v \
    chips/arithmetic/add32.v \
    chips/arithmetic/alu32.v \
    chips/arithmetic/inc32.v \
    chips/logic/mux32.v \
    chips/sequential/pc32.v \
    chips/sequential/register32.v

    
python3 testbench/pong_pygame.py
vvp -M. -m pong_vpi cpu_pong_interactive