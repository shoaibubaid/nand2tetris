# Phase 1 : Summary

## 1. What Was Lacking in Project 5?

The original CPU was designed around a simple, single-cycle memory model.

There were four main limitations:

| Original limitation | Why it was a problem |
|---|---|
| Memory tightly coupled to CPU | CPU directly interacted with the data memory implementation. |
| Simple memory access | Memory operations were not managed through a multi-cycle request/response protocol. |
| No CPU waiting mechanism | CPU couldn't safely wait for a memory operation taking multiple cycles. |
| Limited memory architecture | No clean boundary between memory control and the physical RAM implementation. |

These limitations would become increasingly problematic when building a complete computer with peripherals, framebuffer and external memory-mapped devices.

## 2. What Did We Build?

The resulting architecture is:

```text
             +------------------+
             |        CPU       |
             |                  |
             | Instruction Exec|
             | ALU / Registers  |
             +--------+---------+
                      |
                      |
             +--------v---------+
             | Memory Controller|
             |  data_memory.v   |
             |                  |
             | FSM              |
             | Load/Store Logic |
             | Address Validation|
             | Read-Modify-Write|
             +--------+---------+
                      |
                      |
             +--------v---------+
             |    RAM Wrapper   |
             |    main_ram.v    |
             +--------+---------+
                      |
                      |
             +--------v---------+
             |     16 KB RAM    |
             |   4096 x 32-bit  |
             +------------------+
```

### A. Memory Controller – `data_memory.v`

Introduced a four-state finite state machine:

- `IDLE`: Accept and validate a memory request.
- `READ`: Read the existing RAM word.
- `WRITE`: Write the modified or new word.
- `DONE`: Signal completion to the CPU.

Implemented:

- `LB`, `LBU`, `LH`, `LHU`, `LW`
- `SB`, `SH`, `SW`
- Signed and unsigned load extension.
- Alignment checking.
- Address-range checking.
- Read-modify-write for byte and halfword stores.

**What does this fix?**

The CPU no longer needs to understand the internal details of every memory operation. The controller handles the complexity.

### B. RAM Wrapper – `main_ram.v`

Introduced an abstraction between the controller and actual RAM.

It supports:
- Behavioral RAM for lightweight simulation.
- Structural RAM through the existing `ram4k_32` hierarchy.

**What does this fix?**

The underlying RAM implementation can be changed without rewriting the memory controller.

This will be useful when moving from simulation to FPGA memory resources.

Note: Behavioral RAM has been tested. Structural RAM integration is not yet verified.

### C. CPU Stall/Ready Mechanism – `cpu.v`

Introduced another FSM inside the CPU:

| State | Responsibility |
|---|---|
| `CPU_RUN` | Execute instructions |
| `CPU_MEM_WAIT` | Wait for memory completion |
| `CPU_MEM_RELEASE` | Release the memory request |

Modified:
- PC update logic.
- Memory request generation.
- Register-file write enable.
- Load-result write-back timing.

**What does this fix?**

Previously, the CPU assumed every instruction completed in one cycle.

Now, it can wait for memory operations without accidentally executing subsequent instructions or advancing the PC prematurely.

### D. Verification

Tested the memory controller independently and then integrated it with the CPU.

Tests covered:

- All eight supported load/store instructions.
- Signed and unsigned loads.
- Partial stores and preservation of adjacent bytes.
- Misaligned accesses.
- Out-of-range accesses at the controller level.
- Consecutive memory operations.
- Load-dependent arithmetic.
- CPU PC stability during memory waits.

The uninitialized-byte issue in the expanded test also helped verify that partial stores preserve existing bytes rather than silently clearing them.

---

## 3. What Does Phase 1 Enable?

The most important outcome is architectural.

The CPU now has a memory interface that can support devices beyond ordinary RAM.

Proposed memory map for Phase 2:

| Address region | Device |
|---|---|
| `0x00000000 – 0x00003FFF` | Main RAM |
| `0x10000000 – 0x10012BFF` | Framebuffer |
| `0x20000000 – 0x2000000F` | Keyboard |
| `0x20000010 – 0x2000001F` | Timer |

These address ranges are proposed, not yet implemented.

The next architectural component will be an address decoder that determines which device receives each CPU request.

---

## 4. Final Phase 1 Status

| Step | Task | Status |
|---|---|---|
| 1 | Build reliable memory system | Implemented and behaviorally tested |
| 2 | Integrate existing 16 KB RAM hierarchy | Wrapper implemented; structural verification pending |
| 3 | Implement multi-cycle memory controller | Tested |
| 4 | Introduce CPU stall/ready handling | Tested |
| 5 | Verify load/store and memory integrity | Core tests passed |

### Remaining verification

Although the planned behavioral verification is complete, the following remain future work:

- Full structural RAM verification.
- Exhaustive memory error-path verification.

---

## 5. Next: Phase 2 – Peripheral Architecture

The next five steps, following the agreed roadmap:

1. Implement memory-mapped I/O and address decoding.
2. Design framebuffer and pixel addressing scheme.
3. Implement video controller.
4. Implement keyboard input.
5. Implement timer.

### Big Picture

Phase 1 taught the CPU to communicate with memory over a multi-cycle interface.

Phase 2 will teach it to communicate with the outside world.

**This is the transition from a processor to a computer.**
