# 5-Stage Pipelined MIPS CPU (Verilog)

A 5-stage pipelined MIPS processor (IF / ID / EX / MEM / WB) written in Verilog,
verified in simulation, and deployed to a Xilinx FPGA. It runs a variable
block-size motion estimation (VBSME) program written in MIPS assembly and
reports the best-match location for each test frame on the board's display.

Built by a three-person team in a university computer architecture course
(Fall 2025). Each source file lists who worked on it.

<!-- Add a block diagram here: docs/pipeline.png -->

## Design

| Feature | Implementation |
| --- | --- |
| Pipeline | IF, ID, EX, MEM, WB with registered stage boundaries (`PipeReg`) |
| Data hazards | `HazardDetectionUnit` freezes the PC and IF/ID and inserts a bubble into ID/EX when the instruction in ID reads a register being written by the instruction in EX or MEM |
| Write-back bypass | Results in WB are bypassed directly into ID, so they never cause a stall |
| Control hazards | Branches and jumps resolve in ID; the instruction fetched behind a taken branch is squashed (1-cycle penalty, no delay slot) |
| Memory ordering | Loads stall while a store is still in EX or MEM |
| ISA | add/sub/and/or/xor/nor/slt, shifts and rotate, mul, immediates, lw/lh/lb and sw/sh/sb (sign-extended loads), beq, bne, blez, bgtz, bltz, bgez, j, jal, jr |
| FPGA | Clock divider and 8-digit 7-segment display (`src/fpga/`) |

## Verification

Four self-checking testbenches, run together by a Python regression script
(Vivado simulator). Each prints `TEST PASSED` or `FAIL: ...`.

| Testbench | What it checks | Result |
| --- | --- | --- |
| `tb/tb_vbsme.v` | Full CPU: runs 5 VBSME test cases and compares each (row, col) result to the expected answer; reports cycles, stall cycles and CPI | 5 / 5 match |
| `tb/tb_alu.v` | All 12 ALU operations and the Zero flag, including wraparound, signed compare and rotate | 18 checks |
| `tb/tb_regfile.v` | Reset values, writes, write-enable, hardwired `$zero`, `$v0`/`$v1` debug ports | 37 checks |
| `tb/tb_datamemory.v` | Word, halfword and byte stores with masking; sign-extended loads | 8 checks |

Original exploratory testbenches are kept in `tb/legacy/`.

```bash
# Windows: first run Vivado's settings64.bat in the same terminal
python scripts/run_regression.py

python scripts/run_regression.py -k alu     # one testbench
python scripts/run_regression.py --sva      # also compile verif/*.sv (work in progress)
```

## Results

| Metric | Value |
| --- | --- |
| Regression (Vivado xsim) | 4 / 4 testbenches passing |
| VBSME workload, 5 test cases | 2,053,738 cycles |
| Stall cycles (PC frozen) | 692,604 (34%) |
| Instructions issued (non-NOP) | 1,167,865 |
| CPI | 1.76 |

About a third of all cycles are hazard stalls, mainly from RAW dependencies that
are resolved by stalling instead of forwarding. This is the baseline for the
forwarding work below.

## Repository layout

```
src/        CPU RTL
src/fpga/   Board top level, clock divider, 7-segment display, constraints
tb/         Self-checking testbenches (legacy/ = original ones)
verif/      SystemVerilog assertions (work in progress)
mem/        Instruction and data memory images (tests/ = alternate programs)
sw/         VBSME assembly and memory-image generator
scripts/    Regression runner
docs/       Diagrams and reports
```

## Next steps

- Add EX-stage forwarding (EX/MEM and MEM/WB to EX) so only load-use hazards stall, and re-measure CPI against the 1.76 baseline
- Get the SystemVerilog assertions in `verif/cpu_sva.sv` running in the regression
- Record Fmax and utilization from Vivado implementation
