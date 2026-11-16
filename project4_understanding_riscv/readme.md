- Learn registers, arithmetic, memory access, branches and jumps in RISC-V.
- Write small assembly programs: addition, multiplication, loops, arrays and functions.
- Understand how RISC-V instructions are encoded into 32-bit machine instructions.
- Experiment with an assembler and simulator.
- Eventually write a small Python assembler of your own.



To make the cpu, we need to understand that the ALU has to do these operations

- ADD	
- SUB	
- AND
- OR
- XOR	
- SLL (shift left logical)	
- SRL (shift Right logical)
- SRA (shift Right Arithmetic)
- SLT (Set less than (signed) : if x less than y , then out = 1 else 0)	
- SLTU (Set less than (unsigned) : if x less than y , then out = 1 else 0)	

so, what we do is, assign a control input for each of the operation 
so that the cpu knows how output is related to x and y

eg. if 0000, then out = x+y, if 0010, then out = x&y etc

What about branch instructions?
The processor needs to determine whether x1 == x2.

We can reuse the ALU:
x1-x2=0

If the result is zero, the branch is taken.

Similarly:

Branch instruction - 	Required condition
- BEQ	- Equal
- BNE	- Not equal
- BLT	- Signed less than
- BGE	- Signed greater than or equal
- BLTU	- Unsigned less than
- BGEU	- Unsigned greater than or equal
