set project_file "/home/vembu/shoaib/nand2tetris/project7_pynqz2_computer/vivado_project/pong_computer.xpr"

open_project $project_file
open_checkpoint /home/vembu/shoaib/placed_design.dcp

puts "Extracting 10 worst setup paths..."

report_timing -setup -max_paths 10 -path_type full \
    -file /home/vembu/shoaib/critical_paths.rpt

puts "Report generated."

close_project
