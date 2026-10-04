`timescale 1ns / 1ps
`default_nettype none

////////////////////////////////////////////////////////////////////////////////
// Controller (Main Control Unit)
//
// Decodes the instruction (opcode, and funct for R-type) and drives the
// datapath control signals. Purely combinational, default = NOP
//
// Inputs : opcode (and funct if needed)
//
// Outputs: RegDst, ALUSrc, ALUOp[3:0], MemRead, MemWrite,
//          MemtoReg, RegWrite, MemSize[1:0], MemSign, RotRbit, isJAL
//
// Notes:   Branch/jump target/PCSrc are formed in ID using these flags
////////////////////////////////////////////////////////////////////////////////

module Controller(
  input wire [31:0] instr,

  // EX (ID/EX)
  output reg       RegDst,       // 1=rd, 0=rt
  output reg       ALUSrc,       // 1=imm, 0=rt
  output reg [3:0] ALUOp,        // to ALUControl / ALU

  // M (EX/MEM)
  output reg       MemWrite,
  output reg       MemRead,
  output reg [1:0] MemSize,     // 00=byte, 01=half, 10=word
  output reg       MemSign,     // 1=signed (lb/lh/lw), 0=zero (lbu/lhu if used)

  // WB (MEM/WB)
  output reg       MemtoReg,     // 1=memory, 0=ALU
  output reg       RegWrite,

  // Branch/Jump (ID and/or EX logic)
  output reg [2:0] BranchType,   // 000 none, 001 eq, 010 ne, 011 lez, 100 gtz, 101 ltz, 110 gez
  output reg       Jump,         // j/jal
  output reg       JumpReg,      // jr
  output reg       JALControl,

  // Immediate/shift helpers
  output reg       ExtSel,       // 1=sign-extend, 0=zero-extend (andi/ori/xori)
  output wire      RotRbit       // instr[21] for SRL vs ROTR
);

  // ===== fields =====
  wire [5:0] op    = instr[31:26];
  wire [4:0] rt    = instr[20:16];
  wire [5:0] funct = instr[5:0];
  assign RotRbit   = instr[21];

  // ===== ALU codes =====
  localparam [3:0]
    ALU_ADD  = 4'b0000,
    ALU_SUB  = 4'b0001,
    ALU_AND  = 4'b0010,
    ALU_OR   = 4'b0011,
    ALU_XOR  = 4'b0100,
    ALU_NOR  = 4'b0101,
    ALU_SLL  = 4'b0110,
    ALU_SRL  = 4'b0111,
    ALU_SLT  = 4'b1000,
    ALU_ROTR = 4'b1001,   // only used when RotRbit=1 with SRL funct
    ALU_MUL  = 4'b1010,   // SPECIAL2 MUL (low 32)
    ALU_PASS = 4'b1011,   // pass A (for sign/zero branches)
    ALU_RTY  = 4'b1111;   // R-type -> ALUControl will decode funct

  // ===== branch encodings =====
  localparam [2:0]
    BR_NONE = 3'b000, BR_EQ = 3'b001, BR_NE = 3'b010,
    BR_LEZ  = 3'b011, BR_GTZ= 3'b100, BR_LTZ= 3'b101, BR_GEZ=3'b110;

  // ===== standard MIPS opcodes (bits 31:26) =====
  localparam [5:0]
    OP_SPECIAL  = 6'b000000, // R-type
    OP_REGIMM   = 6'b000001, // BLTZ/BGEZ (uses rt)
    OP_J        = 6'b000010,
    OP_JAL      = 6'b000011,
    OP_BEQ      = 6'b000100,
    OP_BNE      = 6'b000101,
    OP_BLEZ     = 6'b000110,
    OP_BGTZ     = 6'b000111,
    OP_ADDI     = 6'b001000,
    OP_SLTI     = 6'b001010,
    OP_ANDI     = 6'b001100,
    OP_ORI      = 6'b001101,
    OP_XORI     = 6'b001110,
    OP_LB       = 6'b100000,
    OP_LH       = 6'b100001,
    OP_LW       = 6'b100011,
    OP_SB       = 6'b101000,
    OP_SH       = 6'b101001,
    OP_SW       = 6'b101011,
    OP_SPECIAL2 = 6'b011100; // MUL (r2/r6)

  // REGIMM rt codes (bits 20:16) for OP_REGIMM
  localparam [4:0]
    RT_BLTZ     = 5'b00000,
    RT_BGEZ     = 5'b00001;

  // ===== defaults (NOP) =====
  always @(*) begin
    RegDst     = 1'b0;
    ALUSrc     = 1'b0;
    ALUOp      = ALU_ADD;
    MemWrite   = 1'b0;
    MemRead    = 1'b0;
    MemSize    = 2'b10;    // word
    MemSign    = 1'b1;     // signed loads by default
    MemtoReg   = 1'b0;
    RegWrite   = 1'b0;
    BranchType = BR_NONE;
    Jump       = 1'b0;
    JumpReg    = 1'b0;
    JALControl = 1'b0;
    ExtSel     = 1'b1;     // sign-extend immediates by default



    if (instr == 32'b0) begin
        // guard against NOPs 
    end else begin
        case (op)
    
          // ---------------- R-type (SPECIAL) ----------------
          OP_SPECIAL: begin
            RegDst   = 1'b1;   // rd
            ALUSrc   = 1'b0;   // register operand
            RegWrite = 1'b1;
            ALUOp    = ALU_RTY;  // let ALUControl decide by funct
    
            // JR is an R-type control-flow exception
            if (funct == 6'b001000) begin // JR
              JumpReg  = 1'b1;
              RegWrite = 1'b0;
              RegDst   = 1'b0;
            end
          end
    
          // ---------------- R-type in SPECIAL2 (MUL low 32) ----------------
          OP_SPECIAL2: begin
            // MUL (funct=000010) -> write rd = low 32 of rs*rt
            if (funct == 6'b000010) begin
              RegDst   = 1'b1;
              ALUSrc   = 1'b0;
              RegWrite = 1'b1;
              ALUOp    = ALU_MUL;
            end
          end
    
          // ---------------- immediates ----------------
          OP_ADDI:  begin RegDst=0; ALUSrc=1; ALUOp=ALU_ADD; RegWrite=1; ExtSel=1; end
          OP_SLTI:  begin RegDst=0; ALUSrc=1; ALUOp=ALU_SLT; RegWrite=1; ExtSel=1; end
          OP_ANDI:  begin RegDst=0; ALUSrc=1; ALUOp=ALU_AND; RegWrite=1; ExtSel=0; end
          OP_ORI:   begin RegDst=0; ALUSrc=1; ALUOp=ALU_OR;  RegWrite=1; ExtSel=0; end
          OP_XORI:  begin RegDst=0; ALUSrc=1; ALUOp=ALU_XOR; RegWrite=1; ExtSel=0; end
    
          // ---------------- loads (signed) ----------------
          OP_LB: begin
            RegDst=0; ALUSrc=1; ALUOp=ALU_ADD; MemRead=1; MemtoReg=1; RegWrite=1;
            MemSize=2'b00; MemSign=1; ExtSel=1;
          end
          OP_LH: begin
            RegDst=0; ALUSrc=1; ALUOp=ALU_ADD; MemRead=1; MemtoReg=1; RegWrite=1;
            MemSize=2'b01; MemSign=1; ExtSel=1;
          end
          OP_LW: begin
            RegDst=0; ALUSrc=1; ALUOp=ALU_ADD; MemRead=1; MemtoReg=1; RegWrite=1;
            MemSize=2'b10; MemSign=1; ExtSel=1;
          end
    
          // ---------------- stores ----------------
          OP_SB: begin ALUSrc=1; ALUOp=ALU_ADD; MemWrite=1; MemSize=2'b00; ExtSel=1; end
          OP_SH: begin ALUSrc=1; ALUOp=ALU_ADD; MemWrite=1; MemSize=2'b01; ExtSel=1; end
          OP_SW: begin ALUSrc=1; ALUOp=ALU_ADD; MemWrite=1; MemSize=2'b10; ExtSel=1; end
    
          // ---------------- branches ----------------
          OP_BEQ:  begin ALUOp=ALU_SUB; BranchType=BR_EQ;  end
          OP_BNE:  begin ALUOp=ALU_SUB; BranchType=BR_NE;  end
          OP_BLEZ: begin ALUOp=ALU_PASS; BranchType=BR_LEZ; end
          OP_BGTZ: begin ALUOp=ALU_PASS; BranchType=BR_GTZ; end
    
          OP_REGIMM: begin
            ALUOp = ALU_PASS;
            if      (rt == RT_BLTZ) BranchType = BR_LTZ;
            else if (rt == RT_BGEZ) BranchType = BR_GEZ;
          end
    
          // ---------------- jumps ----------------
          OP_J:   begin Jump = 1'b1; end
          OP_JAL: begin Jump = 1'b1; RegWrite = 1'b1; JALControl = 1'b1; end   // write $ra with PC+8 outside
    
          default: ;
        endcase
     end
  end

endmodule

