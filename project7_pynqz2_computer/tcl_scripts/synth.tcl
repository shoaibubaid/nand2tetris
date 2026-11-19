set project_file "/home/vembu/shoaib/nand2tetris/project7_pynqz2_computer/vivado_project/pong_computer.xpr"

open_project $project_file

set_property verilog_define XILINX [get_filesets sources_1]

puts "Starting full FPGA synthesis..."

synth_design -top top -part xc7z020clg400-1

puts "Generating utilization report..."
report_utilization -file /home/vembu/shoaib/synthesis_utilization.rpt

puts "Generating timing summary..."
report_timing_summary -file /home/vembu/shoaib/synthesis_timing.rpt

write_checkpoint -force /home/vembu/shoaib/synthesized_design.dcp

puts "Full synthesis completed."

close_project
