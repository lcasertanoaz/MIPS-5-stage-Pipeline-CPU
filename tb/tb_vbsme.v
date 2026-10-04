`timescale 1ns / 1ps
////////////////////////////////////////////////////////////////////////////////
// tb_vbsme: self-checking full-CPU testbench
//
// Runs the VBSME program in mem/instruction_memory.mem (5 test cases) and
// checks the (row, col) result in $v0/$v1 after each call returns.
// A result is sampled each time the next `jal vbsme` reaches ID (vbsme clears
// $v0/$v1 on entry, so they still hold the previous answer), and once more
// when the program reaches its final `j end_program` loop.
//
// Also reports total cycles, instructions issued, stall cycles, and CPI.
// Prints "TEST PASSED" or lines containing "FAIL" for the regression script.
////////////////////////////////////////////////////////////////////////////////
module tb_vbsme;
    parameter integer    MAX_CYCLES = 50000000;
    parameter [31:0]     JAL_VBSME  = 32'h0c00001a;  // jal vbsme
    parameter [31:0]     END_LOOP   = 32'h08000019;  // j end_program
    parameter integer    NUM_TESTS  = 5;

    reg Clk = 1'b0;
    reg Reset = 1'b1;

    wire [31:0] out_PC, out_write_data, out_v0, out_v1;
    wire        out_regwrite;
    wire [4:0]  out_write_reg;

    CPU dut (
        .Clk(Clk), .Reset(Reset),
        .out_PC(out_PC), .out_write_data(out_write_data),
        .out_regwrite(out_regwrite), .out_write_reg(out_write_reg),
        .out_v0(out_v0), .out_v1(out_v1)
    );

    always #10 Clk = ~Clk;

`ifdef USE_SVA
    // SystemVerilog assertions (verif/cpu_sva.sv), wired to the CPU's internal signals
    cpu_sva u_sva (
        .Clk              (Clk),
        .Reset            (Reset),
        .IF_ID_Instruction(dut.IF_ID_Instruction),
        .ID_EX_RegWrite   (dut.ID_EX_RegWrite),
        .EX_WriteReg      (dut.EX_WriteReg),
        .EX_MEM_RegWrite  (dut.EX_MEM_RegWrite),
        .EX_MEM_WriteReg  (dut.EX_MEM_WriteReg),
        .PCWrite          (dut.PCWrite),
        .IF_ID_Write      (dut.IF_ID_Write),
        .ID_EX_Bubble     (dut.ID_EX_Bubble),
        .ID_EX_MemRead    (dut.ID_EX_MemRead),
        .ID_EX_MemWrite   (dut.ID_EX_MemWrite),
        .IF_PC4           (dut.IF_PC4),
        .ID_PCSrc         (dut.ID_PCSrc),
        .reg0             (dut.idu.rf.registers[0])
    );
`endif

    // Expected (row, col) per test, from the comments in sw/vbsme_lab7.s
    reg [31:0] exp_v0 [0:NUM_TESTS-1];
    reg [31:0] exp_v1 [0:NUM_TESTS-1];
    initial begin
        exp_v0[0] = 3;  exp_v1[0] = 2;    // 16x16 frame, 8x4 window
        exp_v0[1] = 16; exp_v1[1] = 0;    // 32x32 frame, 8x16 window
        exp_v0[2] = 12; exp_v1[2] = 0;    // 16x16 frame, 4x8 window
        exp_v0[3] = 8;  exp_v1[3] = 3;    // 16x16 frame, 8x8 window
        exp_v0[4] = 17; exp_v1[4] = 16;   // 32x32 frame, 4x4 window
    end

    integer cycles = 0, issued = 0, stalls = 0, calls = 0, errors = 0;
    reg     prev_jal = 1'b0;
    wire    jal_in_id = (dut.IF_ID_Instruction == JAL_VBSME);

    task check_result(input integer t);
        begin
            if (out_v0 !== exp_v0[t] || out_v1 !== exp_v1[t]) begin
                $display("FAIL: test %0d got (%0d, %0d), expected (%0d, %0d)",
                         t + 1, out_v0, out_v1, exp_v0[t], exp_v1[t]);
                errors = errors + 1;
            end else
                $display("ok   test %0d -> (%0d, %0d)", t + 1, out_v0, out_v1);
        end
    endtask

    // Performance counters + per-test checks
    always @(posedge Clk) begin
        if (!Reset) begin
            cycles = cycles + 1;
            if (!dut.PCWrite) stalls = stalls + 1;
            if (dut.IF_ID_Write && dut.IF_ID_Instruction != 32'b0) issued = issued + 1;
            if (jal_in_id && !prev_jal) begin
                if (calls > 0) check_result(calls - 1);
                calls = calls + 1;
            end
            prev_jal = jal_in_id;
        end
    end

    // Reset, run to the end loop, final check
    initial begin
        repeat (3) @(posedge Clk);
        #1 Reset = 1'b0;

        while (dut.IF_ID_Instruction !== END_LOOP && cycles < MAX_CYCLES)
            @(posedge Clk);

        if (cycles >= MAX_CYCLES) begin
            $display("FAIL: timeout after %0d cycles (program never reached end loop)", cycles);
            $finish;
        end

        repeat (10) @(posedge Clk);   // drain the pipeline
        if (calls != NUM_TESTS) begin
            $display("FAIL: expected %0d vbsme calls, saw %0d", NUM_TESTS, calls);
            errors = errors + 1;
        end
        check_result(NUM_TESTS - 1);

`ifdef USE_SVA
        errors = errors + u_sva.fails;
        $display("assertions: %0d checks, %0d failures | coverage: stall_cycles=%0d load_stalls=%0d mem_dep_stalls=%0d taken_branches=%0d",
                 u_sva.checks, u_sva.fails, u_sva.cov_stall, u_sva.cov_load_use,
                 u_sva.cov_mem_dep, u_sva.cov_branch);
`endif

        $display("cycles=%0d  issued=%0d  stall_cycles=%0d (%0d%%)  CPI~%0d.%02d",
                 cycles, issued, stalls, (stalls * 100 + cycles / 2) / cycles,
                 (cycles * 100 + issued / 2) / issued / 100,
                 ((cycles * 100 + issued / 2) / issued) % 100);
        if (errors == 0) $display("TEST PASSED: all %0d VBSME results match", NUM_TESTS);
        else             $display("FAIL: %0d mismatches", errors);
        $finish;
    end
endmodule
