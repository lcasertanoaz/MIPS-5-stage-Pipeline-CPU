`timescale 1ns / 1ps
`default_nettype none

///////////////////////////////////////////////////////////////////////////////////////////////////
// CPU (Pipeline Top): connects IFU -> IF/ID -> ID -> ID/EX -> EX -> EX/MEM -> MEM -> MEM/WB -> WB
//
// Effort Split: Lucius (CPU, IFU, IDU, EXU, PipeReg, ALU, HazardUnit and Controllers), Ben (CPU, IFU, MEM, DataMem), Julia (WB, RegFile) 
//
// Reset: only the ProgramCounter (in IFU) is reset to 0, pipe regs are not
//
// Debug outputs: out_PC (current PC), out_write_data (RF write data),
//                out_regwrite (RF WE), out_write_reg (RF dest reg)
//
// display outputs: current PC and data being written to RF
//////////////////////////////////////////////////////////////////////////////////////////////////

module CPU (
    input  wire        Clk,
    input  wire        Reset,
    output wire  [31:0] out_PC,         // PC shown on FPGA 
    output wire  [31:0] out_write_data, // value written to RF
    output wire         out_regwrite,
    output wire  [4:0]  out_write_reg,
    output wire  [31:0] out_v0,
    output wire  [31:0] out_v1
);

    // ----------------------------------------------------------------
    // IF stage
    // ----------------------------------------------------------------
    wire [31:0] IF_Instruction;
    wire [31:0] IF_PC4;

    // from ID
    wire        ID_PCSrc;
    wire [31:0] ID_new_PC;

    InstructionFetchUnit ifu (
        .IF_Instruction(IF_Instruction),
        .IF_PC4       (IF_PC4),
        .Reset        (Reset),
        .Clk          (Clk),
        .ID_PCSrc     (ID_PCSrc),
        .ID_new_PC    (ID_new_PC),
        .ID_stall     (ID_stall)
    );

    // ----------------------------------------------------------------
    // IF/ID pipeline reg (instr + PC+4)
    // ----------------------------------------------------------------
    wire [31:0] IF_ID_Instruction;
    wire [31:0] IF_ID_PC4;

    PipeReg #(64) IF_ID (
        .Clk  (Clk),
        .Reset(Reset),
        .stall(~IF_ID_Write),
        .in   ({{32{~ID_PCSrc}} & IF_Instruction, IF_PC4}),
        .out  ({IF_ID_Instruction, IF_ID_PC4})
    );

    // ----------------------------------------------------------------
    // ID stage
    // ----------------------------------------------------------------
    wire [31:0] ID_rs_val;
    wire [31:0] ID_rt_val;
    wire [31:0] ID_ext_imm;
    wire [4:0]  ID_rt;
    wire [4:0]  ID_rd;
    wire [4:0]  ID_shamt;
    wire [5:0]  ID_funct;
    wire [3:0]  ID_ALUOp;
    wire        ID_ALUSrc;
    wire        ID_RotRbit;
    wire        ID_RegDst;
    wire        ID_MemRead;
    wire        ID_MemWrite;
    wire [1:0]  ID_MemSize;
    wire        ID_MemSign;
    wire        ID_MemtoReg;
    wire        ID_RegWrite;
    wire        ID_isJAL;

    // from WB stage
    wire [4:0]  MEM_WB_WriteReg;
    wire [31:0] WB_WriteData;
    wire        MEM_WB_RegWrite;

    InstructionDecodeUnit idu (
        .Clk              (Clk),
        .IF_ID_Instruction(IF_ID_Instruction),
        .IF_ID_PC4        (IF_ID_PC4),

        // WB -> RF writeback
        .WB_WriteData     (WB_WriteData),
        .WB_WriteReg      (MEM_WB_WriteReg),
        .WB_RegWrite      (MEM_WB_RegWrite),

        // to IF
        .ID_PCSrc         (ID_PCSrc),
        .ID_new_PC        (ID_new_PC),

        // to ID/EX
        .ID_rs_val        (ID_rs_val),
        .ID_rt_val        (ID_rt_val),
        .ID_ext_imm       (ID_ext_imm),
        .ID_rt            (ID_rt),
        .ID_rd            (ID_rd),
        .ID_shamt         (ID_shamt),
        .ID_funct         (ID_funct),
        .ID_ALUOp         (ID_ALUOp),
        .ID_RegDst        (ID_RegDst),
        .ID_ALUSrc        (ID_ALUSrc),
        .ID_MemWrite      (ID_MemWrite),
        .ID_MemRead       (ID_MemRead),
        .ID_MemSize       (ID_MemSize),
        .ID_MemSign       (ID_MemSign),
        .ID_MemtoReg      (ID_MemtoReg),
        .ID_RegWrite      (ID_RegWrite),
        .ID_RotRbit       (ID_RotRbit),
        .ID_isJAL         (ID_isJAL),
        .v0               (out_v0),
        .v1               (out_v1)
    );

    wire PCWrite, IF_ID_Write, ID_EX_Bubble;

    HazardDetectionUnit hzu (
        .IF_ID_Instruction (IF_ID_Instruction),
        
        .ID_EX_WriteReg    (EX_WriteReg),
        .ID_EX_RegWrite    (ID_EX_RegWrite),
        
        .EX_MEM_WriteReg   (EX_MEM_WriteReg),
        .EX_MEM_RegWrite   (EX_MEM_RegWrite),
        
        .ID_EX_MemWrite    (ID_EX_MemWrite),
        .EX_MEM_MemWrite   (EX_MEM_MemWrite),
        
        .PCWrite           (PCWrite),
        .IF_ID_Write       (IF_ID_Write),
        .ID_EX_Bubble      (ID_EX_Bubble)
    );
    
    wire ID_stall = ~PCWrite;

    // ----------------------------------------------------------------
    // ID/EX pipeline reg
    //
    // need to carry everything the EX/MEM/WB stages later need:
    //   - 4 data words: rs, rt, ext_imm, PC+4      -> 128
    //   - 3 register nums: rt, rd, shamt           -> 15
    //   - funct (for ALUControl)                   -> 6
    //   - ALUOp (4)                                -> 4
    //   - ALUSrc, RotRbit, RegDst                  -> 3
    //   - MemRead, MemWrite, MemtoReg, RegWrite    -> 4
    //   - isJAL                                    -> 1
    //   - MemSize (2), MemSign (1)                 -> 3
    // total = 128 + 15 + 6 + 4 + 3 + 4 + 1 + 3 = 164
    // ----------------------------------------------------------------
    wire [31:0] ID_EX_rs_val;
    wire [31:0] ID_EX_rt_val;
    wire [31:0] ID_EX_imm;
    wire [31:0] ID_EX_PC4;
    wire [4:0]  ID_EX_rt;
    wire [4:0]  ID_EX_rd;
    wire [4:0]  ID_EX_shamt;
    wire [5:0]  ID_EX_funct;
    wire [3:0]  ID_EX_ALUOp;
    wire        ID_EX_ALUSrc;
    wire        ID_EX_RotRbit;
    wire        ID_EX_RegDst;
    wire        ID_EX_MemRead;
    wire        ID_EX_MemWrite;
    wire        ID_EX_MemtoReg;
    wire        ID_EX_RegWrite;
    wire        ID_EX_isJAL;
    wire [1:0]  ID_EX_MemSize;
    wire        ID_EX_MemSign;

    PipeReg #(164) ID_EX (
        .Clk  (Clk),
        .Reset(Reset),
        .stall(1'b0),
        .in   (ID_EX_Bubble ? 164'd0 : {    // Pass 0 when stalling
            ID_rs_val,        // 32
            ID_rt_val,        // 32
            ID_ext_imm,       // 32
            IF_ID_PC4,        // 32
            ID_rt,            // 5
            ID_rd,            // 5
            ID_shamt,         // 5
            ID_funct,         // 6
            ID_ALUOp,         // 4
            ID_ALUSrc,        // 1
            ID_RotRbit,       // 1
            ID_RegDst,        // 1
            ID_MemRead,       // 1
            ID_MemWrite,      // 1
            ID_MemtoReg,      // 1
            ID_RegWrite,      // 1
            ID_isJAL,         // 1
            ID_MemSize,       // 2
            ID_MemSign        // 1
        }),
        .out  ({
            ID_EX_rs_val,
            ID_EX_rt_val,
            ID_EX_imm,
            ID_EX_PC4,
            ID_EX_rt,
            ID_EX_rd,
            ID_EX_shamt,
            ID_EX_funct,
            ID_EX_ALUOp,
            ID_EX_ALUSrc,
            ID_EX_RotRbit,
            ID_EX_RegDst,
            ID_EX_MemRead,
            ID_EX_MemWrite,
            ID_EX_MemtoReg,
            ID_EX_RegWrite,
            ID_EX_isJAL,
            ID_EX_MemSize,
            ID_EX_MemSign
        })
    );

    // ----------------------------------------------------------------
    // EX stage
    // ----------------------------------------------------------------
    wire [31:0] EX_ALUResult;
    wire [4:0]  EX_WriteReg;
    wire        EX_Zero;   // branch is in ID, so unused

    ExecutionUnit exu (
        .ID_EX_rs_val (ID_EX_rs_val),
        .ID_EX_rt_val (ID_EX_rt_val),
        .ID_EX_imm    (ID_EX_imm),      
        .ID_EX_PC4    (ID_EX_PC4),
        .ID_EX_rs     (5'b0),           // not used in ExecutionUnit
        .ID_EX_rt     (ID_EX_rt),
        .ID_EX_rd     (ID_EX_rd),
        .ID_EX_shamt  (ID_EX_shamt),
        .ID_EX_funct  (ID_EX_funct),
        .ID_EX_ALUSrc (ID_EX_ALUSrc),
        .ID_EX_ALUOp  (ID_EX_ALUOp),
        .ID_EX_RotRbit(ID_EX_RotRbit),
        .ID_EX_RegDst (ID_EX_RegDst),
        .ID_EX_isJAL  (ID_EX_isJAL),

        .EX_ALUResult (EX_ALUResult),
        .EX_WriteReg  (EX_WriteReg),
        .EX_Zero      (EX_Zero)
    );

    // ----------------------------------------------------------------
    // EX/MEM pipeline reg
    // store what MEM needs:
    //  ALUResult (32)
    //  rt_val    (32)
    //  destReg    (5)
    //  MemRead    (1)
    //  MemWrite   (1)
    //  MemtoReg   (1)
    //  RegWrite   (1)
    //  MemSize    (2)
    //  MemSign    (1)
    // total = 32+32+5+1+1+1+1+2+1+32 = 108
    // ----------------------------------------------------------------
    wire [31:0] EX_MEM_ALUResult;
    wire [31:0] EX_MEM_rt_val;
    wire [4:0]  EX_MEM_WriteReg;
    wire        EX_MEM_MemRead;
    wire        EX_MEM_MemWrite;
    wire        EX_MEM_MemtoReg;
    wire        EX_MEM_RegWrite;
    wire [1:0]  EX_MEM_MemSize;
    wire        EX_MEM_MemSign;
    wire [31:0] EX_MEM_PC4;

    PipeReg #(108) EX_MEM (
        .Clk  (Clk),
        .Reset(Reset),
        .stall(1'b0),
        .in   ({
            EX_ALUResult,
            ID_EX_rt_val,
            ID_EX_PC4,
            EX_WriteReg,
            ID_EX_MemRead,
            ID_EX_MemWrite,
            ID_EX_MemtoReg,
            ID_EX_RegWrite,
            ID_EX_MemSize,
            ID_EX_MemSign
        }),
        .out  ({
            EX_MEM_ALUResult,
            EX_MEM_rt_val,
            EX_MEM_PC4,
            EX_MEM_WriteReg,
            EX_MEM_MemRead,
            EX_MEM_MemWrite,
            EX_MEM_MemtoReg,
            EX_MEM_RegWrite,
            EX_MEM_MemSize,
            EX_MEM_MemSign
        })
    );

    // decode size for memory
    wire EX_MEM_HalfControl = (EX_MEM_MemSize == 2'b01);
    wire EX_MEM_ByteControl = (EX_MEM_MemSize == 2'b00);

    // ----------------------------------------------------------------
    // MEM stage
    // ----------------------------------------------------------------
    wire [31:0] MEM_ReadData;

    MemoryUnit dm (
        .EX_MEM_Address    (EX_MEM_ALUResult),
        .EX_MEM_WriteData  (EX_MEM_rt_val),
        .Clk               (Clk),
        .EX_MEM_MemWrite   (EX_MEM_MemWrite),
        .EX_MEM_MemRead    (EX_MEM_MemRead),
        .EX_MEM_HalfControl(EX_MEM_HalfControl),
        .EX_MEM_ByteControl(EX_MEM_ByteControl),
        .MEM_ReadData      (MEM_ReadData)
    );

    // ----------------------------------------------------------------
    // MEM/WB pipeline reg
    // carries: ReadData, ALUResult, writeReg, MemtoReg, RegWrite
    // 32 + 32 + 5 + 1 + 1 + 32 = 103
    // ----------------------------------------------------------------
    wire [31:0] MEM_WB_ReadData;
    wire [31:0] MEM_WB_ALUResult;
    wire        MEM_WB_MemtoReg;
    wire [31:0] MEM_WB_PC4;

    PipeReg #(103) MEM_WB (
        .Clk  (Clk),
        .Reset(Reset),
        .stall(1'b0),
        .in   ({
            MEM_ReadData,
            EX_MEM_ALUResult,
            EX_MEM_PC4,
            EX_MEM_WriteReg,
            EX_MEM_MemtoReg,
            EX_MEM_RegWrite
        }),
        .out  ({
            MEM_WB_ReadData,
            MEM_WB_ALUResult,
            MEM_WB_PC4,
            MEM_WB_WriteReg,
            MEM_WB_MemtoReg,
            MEM_WB_RegWrite
        })
    );

    // ----------------------------------------------------------------
    // WB stage
    // ----------------------------------------------------------------
    WriteBack wb (
        .MemtoReg (MEM_WB_MemtoReg),
        .ALUResult(MEM_WB_ALUResult),
        .MemData  (MEM_WB_ReadData),
        .WriteData(WB_WriteData)
    );

    // Registers to hold the last completed writeback for display
    reg [31:0] display_PC_reg;
    reg [31:0] display_data_reg;

    always @(posedge Clk or posedge Reset) begin
        if (Reset) begin
            display_PC_reg   <= 32'd0;
            display_data_reg <= 32'd0;
        end else if (MEM_WB_RegWrite) begin
            // Update PC and data together when an instruction writes
            display_PC_reg   <= MEM_WB_PC4 - 32'd4;
            display_data_reg <= WB_WriteData;
        end
        // else: hold previous PC/data during stalls/non-writes
    end

    assign out_PC         = display_PC_reg;
    assign out_write_data = display_data_reg;
    assign out_regwrite   = MEM_WB_RegWrite;
    assign out_write_reg  = MEM_WB_WriteReg;

endmodule
