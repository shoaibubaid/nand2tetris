set project_file "/home/vembu/shoaib/nand2tetris/project7_pynqz2_computer/vivado_project/pong_computer.xpr"

open_project $project_file
open_checkpoint /home/vembu/shoaib/synthesized_design.dcp

opt_design
place_design
route_design

report_timing_summary -file /home/vembu/shoaib/routed_timing.rpt
report_utilization -file /home/vembu/shoaib/routed_utilization.rpt

write_checkpoint -force /home/vembu/shoaib/routed_design.dcp
write_bitstream -force /home/vembu/shoaib/pong.bit

close_project
