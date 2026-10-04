`timescale 1ns / 1ps
`default_nettype none

////////////////////////////////////////////////////////////////////////////////
// ALU32Bit
//
// Executes the operation selected by ALUCtrl on A/B, including shifts/rotates
// Sets Zero when the 32-bit result is 0, pure combinational
//
//
// Inputs : A[31:0], B[31:0], shamt[4:0], ALUCtrl[3:0]
//
// Outputs: Result[31:0], Zero
////////////////////////////////////////////////////////////////////////////////

module ALU32Bit(
    input  wire [3:0]  ALUControl,
    input  wire [31:0] A,
    input  wire [31:0] B,
    input  wire [4:0]  shamt,
    output reg  [31:0] ALUResult,
    output wire        Zero
);
    localparam [3:0]
        ALU_ADD   = 4'b0000,
        ALU_SUB   = 4'b0001,
        ALU_AND   = 4'b0010,
        ALU_OR    = 4'b0011,
        ALU_XOR   = 4'b0100,
        ALU_NOR   = 4'b0101,
        ALU_SLL   = 4'b0110,
        ALU_SRL   = 4'b0111,
        ALU_SLT   = 4'b1000,
        ALU_ROTR  = 4'b1001,
        ALU_MUL   = 4'b1010,
        ALU_PASSA = 4'b1011;

    always @(*) begin
        case (ALUControl)
            ALU_ADD:   ALUResult <= A + B;
            ALU_SUB:   ALUResult <= A - B;
            ALU_AND:   ALUResult <= A & B;
            ALU_OR:    ALUResult <= A | B;
            ALU_XOR:   ALUResult <= A ^ B;
            ALU_NOR:   ALUResult <= ~(A | B);
            ALU_SLL:   ALUResult <= B << shamt;
            ALU_SRL:   ALUResult <= B >> shamt;
            ALU_SLT:   ALUResult <= ($signed(A) < $signed(B)) ? 32'd1 : 32'd0;
            ALU_ROTR: begin
                if (shamt == 0)
                    ALUResult <= A;
                else
                    ALUResult = (A >> shamt) | (A << (32 - shamt));
            end
            ALU_MUL:   ALUResult <= A * B;   // low 32 bits
            ALU_PASSA: ALUResult <= A;
            default:   ALUResult <= 32'hXXXX_XXXX;
        endcase
    end

    assign Zero = (ALUResult == 32'd0);

endmodule
