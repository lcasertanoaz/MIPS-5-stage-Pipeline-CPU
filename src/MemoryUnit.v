`timescale 1ns / 1ps
`default_nettype none

////////////////////////////////////////////////////////////////////////////////
// Computer Architecture
// Module - MemoryUnit.v
// Description - Thin wrapper around DataMemory (32-bit, lw/sw/lh/sh/lb/sb).
//
// INPUTS:
// Clk, EX_MEM_MemWrite, EX_MEM_MemRead, EX_MEM_HalfControl, EX_MEM_ByteControl
// EX_MEM_Address (byte addr), EX_MEM_WriteData
//
// OUTPUTS:-
// MEM_ReadData
//
// FUNCTIONALITY:
// Pass-through wrapper that instantiates DataMemory and forwards all signals.
// No extra logic: writes occur on posedge when MemWrite=1; reads reflect DataMemory.
// Addressing/size-select/sign-extension behavior is handled inside DataMemory.
////////////////////////////////////////////////////////////////////////////////

module MemoryUnit(
    input  wire        Clk,
    input  wire        EX_MEM_MemWrite,
    input  wire        EX_MEM_MemRead,
    input  wire        EX_MEM_HalfControl,
    input  wire        EX_MEM_ByteControl,
    input  wire [31:0] EX_MEM_Address,
    input  wire [31:0] EX_MEM_WriteData,
    output wire [31:0] MEM_ReadData
);

    DataMemory dm (
        .EX_MEM_Address     (EX_MEM_Address),
        .EX_MEM_WriteData   (EX_MEM_WriteData),
        .Clk                (Clk),
        .EX_MEM_MemWrite    (EX_MEM_MemWrite),
        .EX_MEM_MemRead     (EX_MEM_MemRead),
        .EX_MEM_HalfControl (EX_MEM_HalfControl),
        .EX_MEM_ByteControl (EX_MEM_ByteControl),
        .MEM_ReadData       (MEM_ReadData)
    );

endmodule