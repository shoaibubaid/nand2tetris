so far we have designed a processor capable of doing math 
in this project, we will add inputs and outputs.
so the remaining things to be done are


- Complete and verify the RV32I instruction subset (completed till project 5)
- Build a reliable memory system (start from here)
- Implement memory-mapped I/O
- Build the framebuffer: Reserve memory for pixels. Define how the CPU writes individual pixels and how the display reads them.
- Build the display interface: Write a Python program that reads framebuffer contents and displays them on your computer screen.
- Implement keyboard input: Capture keyboard events in Python and expose the key state through memory-mapped registers.
- Implement a timer:Provide a timer or frame-tick register so the game can update at a predictable rate.
- Establish software infrastructure: Set up an assembler workflow, stack, function calls and basic program organization.
- Write Pong in RISC-V assembly: Implement ball movement, paddle movement, collision detection, scoring and game-state updates.
- Integrate and play Pong:Load the game into instruction memory, execute it on your processor, accept keyboard input and display the framebuffer.



### Phase 1 — Memory architecture
Starting here
1. Build a reliable memory system.
2. Integrate the existing 16 KB RAM hierarchy.
3. Implement a multi-cycle memory controller.
4. Introduce CPU stall/ready handling.
5. Verify load/store instructions and memory integrity.

### Phase 2 — Peripheral architecture
1. Implement memory-mapped I/O and address decoding.
2. Design the framebuffer and pixel addressing scheme.
3. Implement the video controller.  
4. Implement keyboard input.
5. Implement the timer.

### Phase 3 — Software infrastructure
1. Establish an assembler and machine-code generation workflow.
2. Implement stack management and function calls.
3. Build reusable assembly routines for graphics, input and timing.

### Phase 4 — Pong
1. Implement ball movement and paddle movement.
2. Implement collision detection and scoring.
3. Render the game using framebuffer writes.
4. Integrate keyboard input and game timing.
5. Play Pong interactively in simulation.