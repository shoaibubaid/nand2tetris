| Module | Responsibility |
|---|---|
| `register_file.v` | Implements x0–x31 |
| `immediate_generator.v` | Extracts and sign-extends immediates |
| `instruction_decoder.v` | Extracts opcode and instruction fields |
| `alu_control.v` | Determines the ALU operation |
| `control_unit.v` | Generates CPU control signals |
| `branch_unit.v` | Evaluates branch conditions |
| `instruction_memory.v` | Supplies instructions |
| `data_memory.v` | Handles loads and stores |
| `next_pc_logic.v` | Determines the next PC |
| `cpu.v` | Connects the processor datapath |
| `top.v` | Top-level computer interface |



# Documentation
- [immediate_generator](../docs/immediate_generator.md) 

