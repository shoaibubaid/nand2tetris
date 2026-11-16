- The computer can be viewed as a set of chips, connected by pathways (buses).
- basic loop is fetch an instruction by supplying an address
- execute the instruction and figure out the address of next instruction

- PC tells the next address and it travels through a one way address bus from cpu to memory
- now, the instruction from that address reaches the cpu from in a one way instruction bus from memory to cpu
- The instruction specifies which ALU operation to use, which registers to use etc.

Now, we are going to build this RISCV-RV321 architecure using the concepts that we have used before
but in phases. first we need to make some changes. Make all the hardware 32 bit compatible