`timescale 1ns / 1ps
`default_nettype none

////////////////////////////////////////////////////////////////////////////////
// ALUControl
//
// Decodes ALUOp + funct (and RotRbit/shift info) into a 4-bit control code
// for ALU32Bit, pure combinational
//
// Inputs : ALUOp[3:0], funct[5:0], RotRbit, shamt[4:0]
//
// Outputs: ALUCtrl[3:0]  (selects the ALU operation)
////////////////////////////////////////////////////////////////////////////////

module ALUControl(
  input  wire [3:0] ALUOp,      // from Controller
  input  wire [5:0] funct,      // instr[5:0] (ID/EX)
  input  wire       rbit,       // instr[21]  (ID/EX)  1 = ROTR when funct==SRL
  output reg [3:0] ALUControl
);

  localparam [3:0]
    ALU_ADD=4'b0000, ALU_SUB=4'b0001, ALU_AND=4'b0010, ALU_OR =4'b0011,
    ALU_XOR=4'b0100, ALU_NOR=4'b0101, ALU_SLL=4'b0110, ALU_SRL=4'b0111,
    ALU_SLT=4'b1000, ALU_ROTR=4'b1001, ALU_MUL=4'b1010, ALU_PASS=4'b1011,
    ALU_RTY=4'b1111;

  // standard funct codes (R-type, OP=000000)
  localparam [5:0]
    F_SLL = 6'b000000,
    F_SRL = 6'b000010,
    F_JR  = 6'b001000, // handled in controller (JumpReg)
    F_ADD = 6'b100000,
    F_SUB = 6'b100010,
    F_AND = 6'b100100,
    F_OR  = 6'b100101,
    F_XOR = 6'b100110,
    F_NOR = 6'b100111,
    F_SLT = 6'b101010;

  always @(*) begin
    if (ALUOp != ALU_RTY) begin
      ALUControl = ALUOp;  // lw/sw/immediates/branches pass straight through
    end else begin
      case (funct)
        F_ADD: ALUControl = ALU_ADD;
        F_SUB: ALUControl = ALU_SUB;
        F_AND: ALUControl = ALU_AND;
        F_OR : ALUControl = ALU_OR;
        F_XOR: ALUControl = ALU_XOR;
        F_NOR: ALUControl = ALU_NOR;
        F_SLT: ALUControl = ALU_SLT;
        F_SLL: ALUControl = ALU_SLL;
        F_SRL: ALUControl = rbit ? ALU_ROTR : ALU_SRL; // R-bit picks ROTR vs SRL
        default: ALUControl = ALU_ADD;
      endcase
    end
  end

endmodule
