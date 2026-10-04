`timescale 1ns / 1ps
`default_nettype none

////////////////////////////////////////////////////////////////////////////////
// ExecutionUnit (EX)
//
// Executes ALU/rotate ops and chooses the destination register
// SrcB comes from rt_val or imm (ALUSrc), JAL forces $ra, Zero flag returned
//
// Inputs : ID_EX_rs_val, ID_EX_rt_val, ID_EX_imm, ID_EX_PC4, ID_EX_rt, ID_EX_rd,
//          ID_EX_shamt, ID_EX_funct, ID_EX_ALUOp, ID_EX_ALUSrc,
//          ID_EX_RotRbit, ID_EX_RegDst, ID_EX_isJAL
//
// Outputs: EX_ALUResult, EX_WriteReg, EX_Zero
////////////////////////////////////////////////////////////////////////////////


module ExecutionUnit(
    // from ID/EX pipeline reg
    input  wire [31:0] ID_EX_rs_val,
    input  wire [31:0] ID_EX_rt_val,
    input  wire [31:0] ID_EX_imm,
    input  wire [31:0] ID_EX_PC4,
    input  wire [4:0]  ID_EX_rs,
    input  wire [4:0]  ID_EX_rt,
    input  wire [4:0]  ID_EX_rd,
    input  wire [4:0]  ID_EX_shamt,
    input  wire [5:0]  ID_EX_funct,
    input  wire        ID_EX_ALUSrc,
    input  wire [3:0]  ID_EX_ALUOp,
    input  wire        ID_EX_RotRbit,
    input  wire        ID_EX_RegDst,
    input  wire        ID_EX_isJAL,   // for jal

    // outputs to EX/MEM
    output reg  [31:0] EX_ALUResult,
    output reg  [4:0]  EX_WriteReg,
    output wire        EX_Zero
);

    // ALU control
    wire [3:0] alu_ctrl;
    ALUControl alu_ctl(
        .ALUOp      (ID_EX_ALUOp),
        .funct      (ID_EX_funct),
        .rbit       (ID_EX_RotRbit),
        .ALUControl (alu_ctrl)
    );

    // choose B (rt or imm)
    reg  [31:0] B;
    always @(*) begin
        if (ID_EX_ALUSrc)
            B = ID_EX_imm;
        else
            B = ID_EX_rt_val;
    end

    // actual ALU
    wire [31:0] alu_result;
    wire        alu_zero;  // must be a wire for ALU to drive it

    ALU32Bit alu(
        .ALUControl (alu_ctrl),
        .A          (ID_EX_rs_val),
        .B          (B),
        .shamt      (ID_EX_shamt),
        .ALUResult  (alu_result),
        .Zero       (alu_zero)
    );

    // final ALU result (handle jal)
    always @(*) begin
        if (ID_EX_isJAL)
            EX_ALUResult = ID_EX_PC4;  // write PC+4 to $ra
        else
            EX_ALUResult = alu_result;
    end

    // destination register (handle jal, rd/rt)
    always @(*) begin
        if (ID_EX_isJAL) begin
            EX_WriteReg = 5'd31;              // $ra
        end else if (ID_EX_RegDst) begin
            EX_WriteReg = ID_EX_rd;           // R-type
        end else begin
            EX_WriteReg = ID_EX_rt;           // I-type
        end
    end

    // pass ALU zero flag out
    assign EX_Zero = alu_zero;

endmodule
