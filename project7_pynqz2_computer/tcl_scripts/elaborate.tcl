set project_file "/home/vembu/shoaib/nand2tetris/project7_pynqz2_computer/vivado_project/pong_computer.xpr"

open_project $project_file

set_property verilog_define XILINX [get_filesets sources_1]

puts "Starting RTL elaboration..."

synth_design -rtl -top top -part xc7z020clg400-1

puts ""
puts "RTL elaboration completed."

close_project
