`timescale 1ns / 1ps
`default_nettype none

////////////////////////////////////////////////////////////////////////////////
// InstructionDecodeUnit (ID)
//
// Decodes IF/ID instruction + PC+4, reads the register file, makes immediates,
// computes branch/jump decisions and target, and generates control signals
//
// Inputs : Clk, IF_ID_Instruction, IF_ID_PC4, WB_WriteData, WB_WriteReg, WB_RegWrite
//
// Outputs: ID_rs_val, ID_rt_val, ID_ext_imm, ID_rt, ID_rd, ID_shamt, ID_funct,
//          ID_ALUOp, ID_ALUSrc, ID_RegDst, ID_MemRead, ID_MemWrite, ID_MemSize,
//          ID_MemSign, ID_MemtoReg, ID_RegWrite, ID_RotRbit, ID_isJAL,
//          ID_PCSrc, ID_new_PC
////////////////////////////////////////////////////////////////////////////////

module InstructionDecodeUnit(
    input wire Clk,

    // from IF/ID
    input wire [31:0] IF_ID_Instruction,
    input wire [31:0] IF_ID_PC4,

    // from WB stage
    input wire [31:0] WB_WriteData,
    input wire [4:0]  WB_WriteReg,
    input wire        WB_RegWrite,

    // to IF
    output wire       ID_PCSrc,     // 1 -> IF loads new PC
    output reg [31:0] ID_new_PC,    // branch / jump / jr target

    // to ID/EX
    output wire [31:0] ID_rs_val,
    output wire [31:0] ID_rt_val,
    output reg  [31:0] ID_ext_imm,
    output wire [4:0]  ID_rt,
    output wire [4:0]  ID_rd,
    output wire [4:0]  ID_shamt,
    output wire [5:0]  ID_funct,
    output wire [3:0]  ID_ALUOp,
    output wire        ID_RegDst,
    output wire        ID_ALUSrc,
    output wire        ID_MemWrite,
    output wire        ID_MemRead,
    output wire [1:0]  ID_MemSize,
    output wire        ID_MemSign,
    output wire        ID_MemtoReg,
    output wire        ID_RegWrite,
    output wire        ID_RotRbit,
    output wire        ID_isJAL,     // extra flag for EX to force $ra = PC+4
    output wire [31:0] v0,
    output wire [31:0] v1
);

    // ------------------------------
    // split instruction
    // ------------------------------
    wire [5:0] op     = IF_ID_Instruction[31:26];
    wire [4:0] rs     = IF_ID_Instruction[25:21];
    wire [4:0] rt     = IF_ID_Instruction[20:16];
    wire [4:0] rd     = IF_ID_Instruction[15:11];
    wire [4:0] shamt  = IF_ID_Instruction[10:6];
    wire [5:0] funct  = IF_ID_Instruction[5:0];
    wire [15:0] imm   = IF_ID_Instruction[15:0];
    wire [25:0] jidx  = IF_ID_Instruction[25:0];

    assign ID_rt    = rt;
    assign ID_rd    = rd;
    assign ID_shamt = shamt;
    assign ID_funct = funct;

    // ------------------------------
    // run controller
    // ------------------------------
    wire        c_RegDst;
    wire        c_ALUSrc;
    wire [3:0]  c_ALUOp;
    wire        c_MemWrite;
    wire        c_MemRead;
    wire [1:0]  c_MemSize;
    wire        c_MemSign;
    wire        c_MemtoReg;
    wire        c_RegWrite;
    wire [2:0]  c_BranchType;
    wire        c_Jump;
    wire        c_JumpReg;
    wire        c_JALControl;
    wire        c_ExtSel;
    wire        c_RotRbit;

    Controller ctrl (
        .instr      (IF_ID_Instruction),
        .RegDst     (c_RegDst),
        .ALUSrc     (c_ALUSrc),
        .ALUOp      (c_ALUOp),
        .MemWrite   (c_MemWrite),
        .MemRead    (c_MemRead),
        .MemSize    (c_MemSize),
        .MemSign    (c_MemSign),
        .MemtoReg   (c_MemtoReg),
        .RegWrite   (c_RegWrite),
        .BranchType (c_BranchType),
        .Jump       (c_Jump),
        .JumpReg    (c_JumpReg),
        .JALControl (c_JALControl), 
        .ExtSel     (c_ExtSel),
        .RotRbit    (c_RotRbit)
    );

    // expose to output
    assign ID_RegDst   = c_RegDst;
    assign ID_ALUSrc   = c_ALUSrc;
    assign ID_ALUOp    = c_ALUOp;
    assign ID_MemWrite = c_MemWrite;
    assign ID_MemRead  = c_MemRead;
    assign ID_MemSize  = c_MemSize;
    assign ID_MemSign  = c_MemSign;
    assign ID_MemtoReg = c_MemtoReg;
    assign ID_RegWrite = c_RegWrite;
    assign ID_RotRbit  = c_RotRbit;
    assign ID_isJAL    = c_JALControl;

    // ------------------------------
    // register file
    // ------------------------------
    wire [31:0] rf_rs_raw, rf_rt_raw;

    RegisterFile rf (
        .ReadRegister1 (rs),
        .ReadRegister2 (rt),
        .WriteRegister (WB_WriteReg),
        .WriteData     (WB_WriteData),
        .RegWrite      (WB_RegWrite),
        .Clk           (Clk),
        .ReadData1     (rf_rs_raw),
        .ReadData2     (rf_rt_raw),
        .v0            (v0),
        .v1            (v1)
    );
    
    wire wb_hits_rs = WB_RegWrite && (WB_WriteReg != 5'd0) && (WB_WriteReg == rs);
    wire wb_hits_rt = WB_RegWrite && (WB_WriteReg != 5'd0) && (WB_WriteReg == rt);
    
    assign ID_rs_val = wb_hits_rs ? WB_WriteData : rf_rs_raw;
    assign ID_rt_val = wb_hits_rt ? WB_WriteData : rf_rt_raw;

    // ------------------------------
    // imm extend (from controller ExtSel)
    // ------------------------------
    wire [31:0] signext_wire;
    SignExtension se (
        .in(imm), 
        .out(signext_wire)
    );

    always @(*) begin
        ID_ext_imm = c_ExtSel ? signext_wire : {16'b0, imm};
    end

    // ------------------------------
    // branch / jump / jr (dealt with in ID)
    // ------------------------------
    // branch conditions from rs / rt
    wire eq   = (ID_rs_val == ID_rt_val);
    wire ne   = ~eq;
    wire z    = (ID_rs_val == 32'b0);
    wire neg  = ID_rs_val[31];

    // decode by BranchType from controller
    // 000 none, 001 eq, 010 ne, 011 lez, 100 gtz, 101 ltz, 110 gez
    reg take_branch;
    always @(*) begin
        case (c_BranchType)
            3'b001: take_branch =  eq;                 // beq
            3'b010: take_branch =  ne;                 // bne
            3'b011: take_branch = (neg | z);           // blez
            3'b100: take_branch = (~neg & ~z);         // bgtz
            3'b101: take_branch =  neg;                // bltz
            3'b110: take_branch = ~neg;                // bgez
            default: take_branch = 1'b0;
        endcase
    end


    wire [31:0] br_target = IF_ID_PC4 + (signext_wire << 2);    // branch target = PC+4 + (signext(imm) << 2)
    wire [31:0] j_target  = {IF_ID_PC4[31:28], jidx, 2'b00};    // jump target
    wire [31:0] jr_target = ID_rs_val;                          // jr target

    // final PC select (ID_PCSrc=1 if any control-flow is taken)
    assign ID_PCSrc = (take_branch) | c_Jump | c_JumpReg;

    always @(*) begin
        if (c_JumpReg)
            ID_new_PC = jr_target;
        else if (c_Jump)
            ID_new_PC = j_target;
        else
            ID_new_PC = br_target;
    end

endmodule
