`timescale 1ns / 1ps
////////////////////////////////////////////////////////////////////////////////
// cpu_sva: SystemVerilog assertions for the pipelined CPU.
//
// Each rule is an immediate assertion evaluated on every clock edge, using
// values sampled just before the edge (the same view the pipeline registers
// see). Values from the previous cycle are kept in registers, so no
// property/sequence constructs are needed.
//
// Instantiated by tb/tb_vbsme.v when USE_SVA is defined
// (python scripts/run_regression.py --sva).
//
// Design under check: RAW hazards are resolved by stalling (no EX forwarding).
// Write-back results bypass into ID, so only producers in EX or MEM force a
// stall. Branches and jumps resolve in ID and squash the fetched instruction.
////////////////////////////////////////////////////////////////////////////////
module cpu_sva (
    input wire        Clk,
    input wire        Reset,
    input wire [31:0] IF_ID_Instruction,
    input wire        ID_EX_RegWrite,
    input wire [4:0]  EX_WriteReg,        // destination of the instruction in EX
    input wire        EX_MEM_RegWrite,
    input wire [4:0]  EX_MEM_WriteReg,    // destination of the instruction in MEM
    input wire        PCWrite,
    input wire        IF_ID_Write,
    input wire        ID_EX_Bubble,
    input wire        ID_EX_MemRead,
    input wire        ID_EX_MemWrite,
    input wire [31:0] IF_PC4,
    input wire        ID_PCSrc,
    input wire [31:0] reg0                // register file entry $zero
);
    // Which source registers does the instruction in ID actually read?
    wire [5:0] op    = IF_ID_Instruction[31:26];
    wire [5:0] funct = IF_ID_Instruction[5:0];
    wire [4:0] rs    = IF_ID_Instruction[25:21];
    wire [4:0] rt    = IF_ID_Instruction[20:16];

    wire is_shift = (op == 6'h00) && (funct == 6'h00 || funct == 6'h02 || funct == 6'h03);
    wire reads_rs = !(op == 6'h02 || op == 6'h03 || op == 6'h0F) && !is_shift;  // not j, jal, lui, shifts
    wire reads_rt = ((op == 6'h00) && (funct != 6'h08))                           // R-type except jr
                  || op == 6'h04 || op == 6'h05                                    // beq, bne
                  || op == 6'h28 || op == 6'h29 || op == 6'h2B                     // sb, sh, sw
                  || op == 6'h1C;                                                  // mul

    // Dependence on the instruction in EX, or in MEM
    wire hz_ex  = ID_EX_RegWrite  && (EX_WriteReg     != 5'd0) &&
                  ((reads_rs && EX_WriteReg     == rs) || (reads_rt && EX_WriteReg     == rt));
    wire hz_mem = EX_MEM_RegWrite && (EX_MEM_WriteReg != 5'd0) &&
                  ((reads_rs && EX_MEM_WriteReg == rs) || (reads_rt && EX_MEM_WriteReg == rt));
    wire raw_hazard = hz_ex | hz_mem;

    // Results read by tb_vbsme at the end of the run
    integer checks = 0, fails = 0;
    integer cov_stall = 0, cov_load_use = 0, cov_mem_dep = 0, cov_branch = 0;

    // Previous-cycle values
    reg        armed = 1'b0;
    reg [31:0] prev_instr = 32'b0, prev_pc4 = 32'b0;
    reg        prev_ifid_write = 1'b1, prev_pcwrite = 1'b1, prev_bubble = 1'b0;

    always @(posedge Clk) begin
        if (!Reset && armed) begin

            // 1. Any RAW dependency on an instruction in EX or MEM must stall
            if (raw_hazard) begin
                checks = checks + 1;
                a_raw_stall: assert (!PCWrite && !IF_ID_Write && ID_EX_Bubble)
                    else begin
                        fails = fails + 1;
                        $error("FAIL: RAW hazard in ID without a stall (rs=%0d rt=%0d)", rs, rt);
                    end
            end

            // 2. A bubble is a real no-op: nothing writes a register or memory in EX
            if (prev_bubble) begin
                checks = checks + 1;
                a_bubble_nop: assert (!ID_EX_RegWrite && !ID_EX_MemWrite && !ID_EX_MemRead)
                    else begin
                        fails = fails + 1;
                        $error("FAIL: bubble carried live control signals into EX");
                    end
            end

            // 3. IF/ID holds its instruction during a stall
            if (!prev_ifid_write) begin
                checks = checks + 1;
                a_ifid_hold: assert (IF_ID_Instruction === prev_instr)
                    else begin
                        fails = fails + 1;
                        $error("FAIL: IF/ID changed during a stall");
                    end
            end

            // 4. The PC holds during a stall
            if (!prev_pcwrite) begin
                checks = checks + 1;
                a_pc_hold: assert (IF_PC4 === prev_pc4)
                    else begin
                        fails = fails + 1;
                        $error("FAIL: PC advanced during a stall");
                    end
            end

            // 5. $zero always reads as 0
            checks = checks + 1;
            a_zero_reg: assert (reg0 === 32'b0)
                else begin
                    fails = fails + 1;
                    $error("FAIL: $zero was modified");
                end

            // Coverage: shows the program actually exercised each case
            if (!PCWrite)                  cov_stall    = cov_stall + 1;
            if (!PCWrite && ID_EX_MemRead) cov_load_use = cov_load_use + 1;
            if (hz_mem)                    cov_mem_dep  = cov_mem_dep + 1;
            if (ID_PCSrc && PCWrite)       cov_branch   = cov_branch + 1;
        end

        armed           = !Reset;
        prev_instr      = IF_ID_Instruction;
        prev_pc4        = IF_PC4;
        prev_ifid_write = IF_ID_Write;
        prev_pcwrite    = PCWrite;
        prev_bubble     = ID_EX_Bubble;
    end
endmodule
