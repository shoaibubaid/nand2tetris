# Project 6 — Phase 2: Peripheral Architecture

## Objective

The objective of Phase 2 was to extend the basic RISC-V CPU developed in Project 5 into a complete computer by introducing memory-mapped peripherals.

The CPU should be able to communicate with RAM, a framebuffer, a keyboard and a timer through a common memory interface.

The architecture is designed to support both:
- Simulation using Icarus Verilog.
- FPGA deployment on the PYNQ-Z2.

The CPU-facing memory interface remains consistent across these environments.

---

# 1. Memory-Mapped I/O (MMIO) and Address Decoder

### Objective

Introduce a unified address space through which the CPU can access different memory regions and peripherals.

### Memory map

| Address range | Size | Device |
|---|---:|---|
| `0x00000000 – 0x00003FFF` | 16 KB | Main RAM |
| `0x10000000 – 0x10012BFF` | 75 KiB | Framebuffer |
| `0x20000000 – 0x2000000F` | 16 B | Keyboard |
| `0x20000010 – 0x2000001F` | 16 B | Timer |

### Implemented modules

- `rtl/address_decoder.v`
- `rtl/memory_subsystem.v`

### Address decoder responsibilities

- Decode the CPU address.
- Generate individual peripheral select signals.
- Generate the appropriate address offsets.
- Identify invalid addresses.

### Memory subsystem responsibilities

- Route CPU requests to the selected peripheral.
- Collect peripheral responses.
- Multiplex read data.
- Return ready and access-error signals to the CPU.

### Verification

- Address decoder testbench.
- Memory subsystem interconnect tests.
- Tests for valid and invalid address regions.

**Status: Complete and simulation tested.**

---

# 2. Framebuffer and Pixel Addressing

### Objective

Create a memory region that stores pixel information and can be accessed by both the CPU and the video controller.

### Framebuffer specifications

| Property | Value |
|---|---|
| Resolution | 320 × 240 |
| Pixel format | RGB332 |
| Bits per pixel | 8 |
| Total storage | 76,800 bytes |
| Total size | 75 KiB |
| Base address | `0x10000000` |
| End address | `0x10012BFF` |
| 32-bit words | 19,200 |

### Pixel addressing

The address of a pixel is calculated using:

```text
pixel_offset = y * 320 + x
```

Since four 8-bit pixels fit into one 32-bit word:

```text
word_index = pixel_offset >> 2
byte_lane  = pixel_offset & 3
```

The framebuffer uses little-endian byte ordering.

### Implemented module

`rtl/framebuffer.v`

### Features

- CPU read and write access.
- Byte, halfword and word operations.
- Byte-lane selection.
- Read-modify-write for partial writes.
- Alignment and bounds checking.
- Independent video read port.

The video read port allows the display pipeline to fetch pixels independently of CPU memory transactions.

### Verification

- Framebuffer read/write tests.
- Byte-lane verification.
- Partial-write preservation.
- Alignment and bounds checking.
- Video read-port verification.
- CPU framebuffer access test.

**Status: Complete and simulation tested.**

---

# 3. Video Controller and HDMI Pipeline

### Objective

Generate a video signal using the framebuffer so that the computer can display graphics on a physical monitor.

The design uses a 320 × 240 framebuffer scaled to a 640 × 480 output resolution.

### 3.1 Video timing

Implemented module:

`rtl/video/video_timing.v`

Output resolution: 640 × 480.

Horizontal timing:

| Parameter | Pixels |
|---|---:|
| Visible | 640 |
| Front porch | 16 |
| Sync | 96 |
| Back porch | 48 |
| Total | 800 |

Vertical timing:

| Parameter | Lines |
|---|---:|
| Visible | 480 |
| Front porch | 10 |
| Sync | 2 |
| Back porch | 33 |
| Total | 525 |

Additional characteristics:
- Active-low HSYNC.
- Active-low VSYNC.
- Horizontal and vertical pixel counters.
- Active-video indication.

### 3.2 Video controller

Implemented module:

`rtl/video/video_controller.v`

Responsibilities:

- Generate framebuffer pixel addresses.
- Scale 320 × 240 framebuffer coordinates to 640 × 480 output coordinates.
- Convert RGB332 framebuffer pixels into RGB888.
- Generate black pixels during blanking.
- Align pixel data and synchronization signals.

### 3.3 TMDS encoder

Implemented module:

`rtl/video/tmds_encoder.v`

Responsibilities:

- Convert 8-bit RGB data into 10-bit TMDS symbols.
- Perform transition minimization.
- Maintain running disparity.
- Generate HDMI control symbols during blanking.

### 3.4 TMDS serializer

Implemented module:

`rtl/video/tmds_serializer.v`

Responsibilities:

- Serialize 10-bit TMDS symbols.
- Support behavioral simulation.
- Provide a Xilinx OSERDESE2 implementation branch.

The intended serialization uses a serial clock five times the pixel clock, transmitting on both edges.

### 3.5 HDMI clock generation

Implemented module:

`rtl/video/hdmi_clock_gen.v`

Uses an MMCM and clock buffers to generate:
- Pixel clock.
- High-speed serializer clock.
- Clock-lock indication.

The initial configuration targets a 25 MHz pixel clock and 125 MHz serializer clock.

### 3.6 HDMI physical interface

Implemented module:

`rtl/video/hdmi_phy.v`

Responsibilities:

- Connect the three TMDS data lanes.
- Generate the TMDS clock lane.
- Provide differential output buffers for Xilinx hardware.

### 3.7 Video system integration

Implemented module:

`rtl/video/video_system.v`

Integrates:
- Video controller.
- Three TMDS encoders.
- Three TMDS serializers.
- HDMI physical interface.

### Verification

- Video timing boundary tests.
- Frame rollover tests.
- Framebuffer pixel-address tests.
- RGB conversion tests.
- TMDS control-symbol tests.
- TMDS video-data tests.
- Serializer behavioral tests.
- Video system elaboration and compilation.

**Status: RTL components implemented and simulation tested individually; video system compilation successful.**

**Hardware verification remains pending.** The actual PYNQ-Z2 clock source, HDMI pin assignments, OSERDESE2 implementation and monitor compatibility must be verified before claiming physical HDMI output works.

---

# 4. USB Keyboard Input

### Objective

Allow a physical USB keyboard to communicate with the RISC-V CPU.

The selected architecture uses the Zynq ARM Processing System to handle USB host functionality. The ARM side forwards keyboard events to the programmable logic, where the RISC-V CPU accesses them through MMIO.

### Architecture

```text
USB Keyboard
     |
     v
Zynq ARM Processing System
     |
     | Linux USB HID
     v
PS-to-PL Event Interface
     |
     v
USB Keyboard Bridge
     |
     | Clock Domain Crossing
     v
Keyboard FIFO
     |
     v
Keyboard MMIO Controller
     |
     v
RISC-V CPU
```

The ARM processor handles USB host communication; the game logic and software execute on the RISC-V CPU.

### 4.1 Keyboard event format

Each keyboard event uses 9 bits:

| Bits | Meaning |
|---|---|
| `[8]` | Key pressed/released |
| `[7:0]` | USB HID usage code |

Examples:

| Event | Value |
|---|---|
| W pressed | `0x11A` |
| W released | `0x01A` |
| Up arrow pressed | `0x152` |

### 4.2 Keyboard FIFO

Implemented module:

`rtl/peripherals/keyboard_fifo.v`

Features:
- 16 entries.
- 9-bit event storage.
- Circular read/write pointers.
- FIFO count.
- Full and empty indicators.
- Sticky overflow flag.
- Overflow clearing.
- Simultaneous push/pop handling.

### 4.3 USB keyboard bridge

Implemented module:

`rtl/peripherals/usb_keyboard_bridge.v`

Responsibilities:
- Transfer keyboard events between PS and CPU clock domains.
- Use request/acknowledgment toggle handshaking.
- Synchronize control signals.
- Hold event data stable until acknowledged.
- Support CPU-side backpressure.

### 4.4 Keyboard MMIO controller

Implemented module:

`rtl/peripherals/keyboard_controller.v`

Register map:

| Address | Register | Function |
|---|---|---|
| `0x20000000` | KEY_DATA | Read and pop one keyboard event |
| `0x20000004` | KEY_STATUS | FIFO status |

KEY_STATUS:

| Bit | Meaning |
|---|---|
| `[0]` | FIFO non-empty |
| `[1]` | FIFO overflow |
| `[6:2]` | FIFO count |
| `[7]` | Reserved |
| `[31:8]` | Reserved |

Features:
- Read keyboard events.
- Pop FIFO entries on KEY_DATA reads.
- Report FIFO status.
- Clear overflow through KEY_STATUS writes.
- Reject invalid accesses.
- Prevent repeated FIFO pops while a request is held.

### Verification

- FIFO unit tests.
- CDC bridge tests using independent clocks.
- Backpressure tests.
- Keyboard controller MMIO tests.
- FIFO overflow and clearing tests.
- Full memory subsystem keyboard integration tests.

Verified W key press and release events successfully travelling through the integrated path.

**Status: Complete and integration tested in simulation.**

---

# 5. Timer

### Objective

Provide a hardware timer that allows software to measure elapsed time independently of CPU instruction execution.

This is important for implementing consistent game timing in Pong.

### Implemented module

`rtl/peripherals/timer.v`

The timer uses a configurable clock frequency:

```verilog
parameter integer CLK_HZ = 100_000_000
```

The timer maintains a 32-bit millisecond counter.

### Timer register map

| Address | Register | Function |
|---|---|---|
| `0x20000010` | TIME | Current elapsed milliseconds |
| `0x20000014` | CONTROL | Enable and reset |
| `0x20000018` | PRESCALER | Clock cycles per millisecond |
| `0x2000001C` | STATUS | Timer status |

### Register behavior

CONTROL:

- Bit 0: Enable timer.
- Bit 1: Reset counter when written as 1.

PRESCALER:

- Configures clock cycles per millisecond.
- Default value is `CLK_HZ / 1000`.
- Zero is rejected.

STATUS:

- Bit 0: Timer enabled.
- Bit 1: Sticky tick flag.
- Writing bit 1 as 1 clears the tick flag.

TIME is read-only.

All timer accesses require aligned 32-bit word operations.

### Verification

Standalone timer tests verified:

- Default prescaler.
- Enable and disable.
- Millisecond counting.
- Sticky tick flag.
- Tick flag clearing.
- Counter reset.
- Restart after reset.
- Read-only register protection.
- Invalid prescaler rejection.
- Invalid access width and offset rejection.

Timer integration tests verified:

- MMIO address decoding.
- Timer register reads and writes.
- Timer counting through the memory subsystem.
- Status reporting.
- Tick flag clearing.
- Invalid address handling.

**Status: Complete and integration tested in simulation.**

---

# 6. Final Memory Subsystem

The final `rtl/memory_subsystem.v` integrates all the peripherals.

### Connected components

| Component | Module |
|---|---|
| Address decoder | `address_decoder.v` |
| Main RAM controller | `data_memory.v` |
| Framebuffer | `framebuffer.v` |
| USB keyboard bridge | `usb_keyboard_bridge.v` |
| Keyboard controller | `keyboard_controller.v` |
| Keyboard FIFO | `keyboard_fifo.v` |
| Timer | `timer.v` |

### CPU-facing interface

The existing CPU memory interface remains:

```verilog
input wire req;
input wire mem_read;
input wire mem_write;
input wire [31:0] address;
input wire [31:0] write_data;
input wire [2:0] funct3;

output wire ready;
output wire [31:0] read_data;
output wire access_error;
```

The memory subsystem performs address decoding, request routing, response selection and error reporting.

### Verification completed

- Address decoder tests.
- RAM and framebuffer tests.
- Framebuffer CPU access tests.
- Keyboard FIFO, bridge and controller tests.
- Keyboard memory subsystem integration tests.
- Timer standalone tests.
- Timer memory subsystem integration tests.
- Complete memory subsystem elaboration.

---

# Phase 2 Completion Summary

| Step | Deliverable | Status |
|---|---|---|
| 1 | MMIO and address decoder | Complete |
| 2 | Framebuffer and pixel addressing | Complete |
| 3 | Video controller and HDMI pipeline | Simulation tested |
| 4 | USB keyboard input | Integration tested |
| 5 | Timer | Integration tested |

## Result

At the end of Phase 2, the RISC-V computer has a unified memory subsystem containing:

1. Main RAM.
2. Framebuffer.
3. Video output pipeline.
4. USB keyboard event interface.
5. Keyboard FIFO and MMIO registers.
6. Hardware timer.

The peripheral architecture is implemented and the relevant simulation tests have passed.

The design has not yet been verified as a complete physical FPGA system. In particular, the HDMI physical interface, FPGA clocking, BRAM inference, CDC implementation constraints and actual USB-to-PL bridge remain to be validated on hardware.

---

# Next Phase

## Phase 3 — Software Infrastructure

Planned tasks:

1. Establish assembler and machine-code generation workflow.
2. Implement stack management and function calls.
3. Build reusable assembly routines for graphics, input and timing.

The goal is to make it practical to write larger programs for the custom RISC-V CPU without manually encoding every instruction.

Phase 3 will prepare the software foundation required for Phase 4: implementing and playing Pong on the custom computer.