`timescale 1ns / 1ps
`default_nettype none

////////////////////////////////////////////////////////////////////////////////
// Computer Architecture
// Module - InstructionFetchUnit.v
// Description - IF stage: PC update (seq/branch) and instruction fetch.
//
// INPUTS:
// Reset, Clk, ID_PCSrc (0: PC+4, 1: ID_new_PC), ID_new_PC (target)
//
// OUTPUTS:-
// IF_Instruction (word @ PC), IF_PC4 (PC+4)
//
// FUNCTIONALITY:
// Compute PC+4; nextPC = (ID_PCSrc ? ID_new_PC : PC+4).
// ProgramCounter loads nextPC; InstructionMemory reads at PC.
// Exposes PC+4 to pipeline as IF_PC4.
// InstructionFetchUnit (IF)
//
// Picks next PC (PC+4 or ID_new_PC via ID_PCSrc), updates ProgramCounter
// (Reset -> PC=0), and fetches the instruction, also exposes PC+4
//
// Inputs : Reset, Clk, ID_PCSrc, ID_new_PC
//
// Outputs: IF_Instruction, IF_PC4
////////////////////////////////////////////////////////////////////////////////


module InstructionFetchUnit(IF_Instruction, IF_PC4, Reset, Clk, ID_PCSrc, ID_new_PC, ID_stall);
    input  wire        Reset;
    input  wire        Clk;
    input  wire        ID_stall;
    input  wire        ID_PCSrc;      // 0: PC+4  1: branch/jump
    input  wire [31:0] ID_new_PC;     // target

    output wire [31:0] IF_Instruction;
    output wire [31:0] IF_PC4;
   // Current PC
    wire [31:0] PC;

    // PC + 4
    wire [31:0] PC4;
    assign PC4 = PC + 4;

    // Expose PC+4 to pipeline
    assign IF_PC4 = PC4;

    // Next PC select
    reg [31:0] nextPC;

    // PCSrc selects  PC+4 or branch/jump
    always @(*) begin
        case (ID_PCSrc)
            1'b0: nextPC <= PC4;
            1'b1: nextPC <= ID_new_PC; 
            default: nextPC <= 32'bX;
        endcase
    end

    ProgramCounter pc(
        .Reset(Reset),
        .Clk(Clk),
        .ID_stall(ID_stall),
        .Address(nextPC),
        .PCResult(PC)
    );

    InstructionMemory imem(
        .Address(PC),
        .Instruction(IF_Instruction)
    );
endmodule
