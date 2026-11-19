set project_file "/home/vembu/shoaib/nand2tetris/project7_pynqz2_computer/vivado_project/pong_computer.xpr"

open_project $project_file

puts "Opening synthesized checkpoint..."
open_checkpoint /home/vembu/shoaib/synthesized_design.dcp

puts "Starting optimization..."
opt_design

puts "Starting placement..."
place_design

puts "Generating post-placement timing report..."
report_timing_summary -file /home/vembu/shoaib/placement_timing.rpt

puts "Generating post-placement utilization report..."
report_utilization -file /home/vembu/shoaib/placement_utilization.rpt

write_checkpoint -force /home/vembu/shoaib/placed_design.dcp

puts "Placement completed."

close_project
