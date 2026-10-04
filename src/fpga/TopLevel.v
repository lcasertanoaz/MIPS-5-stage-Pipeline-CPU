`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// top_module (FPGA)
//
// Effort Split: Lucius (IFU, IDU, EXU, PipeReg, ALU, Controllers, TopLevel &
//                      CPU wiring), Ben (IFU, MEM, DataMem), Julia (WB, RegFile)
//
// 100 MHz board Clk into a clock divider for the CPU (ClkOut)
// Passes Reset straight into the CPU (PC resets to 0 in IFU)
// Shows PC[15:0] and last RF write data [15:0] on the 8-digit 7-seg display
// using Two4DigitDisplay (100 MHz for display refresh)
//
// Input : Clk (board 100 MHz), Reset (btnu)
// Output: out7[6:0] (segments a-g), en_out[7:0] (digit enables)
//
////////////////////////////////////////////////////////////////////////////////

module top_module(Clk, Reset, out7, en_out);

    input wire Clk;
    input wire Reset;
    output wire [6:0] out7;
    output wire [7:0] en_out;
    
    wire [31:0] out_PC;
    wire [31:0] out_write_data;
    wire [31:0] out_v0;
    wire [31:0] out_v1;
    wire ClkOut;
    wire out_regwrite;
    wire [4:0] out_write_reg;
    
    ClkDiv Clkdiv(Clk, 1'b0, ClkOut);
    CPU Cpu(
        .Clk(ClkOut), 
        .Reset(Reset), 
        .out_PC(out_PC), 
        .out_write_data(out_write_data),
        .out_regwrite(out_regwrite),
        .out_write_reg(out_write_reg),
        .out_v0(out_v0), 
        .out_v1(out_v1)
    );
    Two4DigitDisplay Display(
        .Clk(Clk), 
        .NumberA(out_v1[15:0]), 
        .NumberB(out_v0[15:0]), 
        .out7(out7), 
        .en_out(en_out)
    );


endmodule
