
# Initialize stack pointer
    lui  sp, 4

# Pass 10 as the first argument
    addi a0, zero, 10

# Call the function
    jal  ra, double_value

# Execution resumes here after return
after_call:
    jal  zero, after_call

# Function: double_value(a0)
double_value:
    add  a0, a0, a0
    jalr zero, 0(ra)
