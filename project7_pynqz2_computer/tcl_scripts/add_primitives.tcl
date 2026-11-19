set project_file "/home/vembu/shoaib/nand2tetris/project7_pynqz2_computer/vivado_project/pong_computer.xpr"

open_project $project_file

set primitive_file "/home/vembu/shoaib/nand2tetris/project7_pynqz2_computer/riscv-cpu/chips/logic/primitives.v"

if {[llength [get_files -quiet $primitive_file]] == 0} {
    add_files -fileset sources_1 $primitive_file
}

update_compile_order -fileset sources_1

puts "===== PRIMITIVES FILE STATUS ====="
puts [get_files $primitive_file]

save_project -name pong_computer
close_project
