`timescale 1ns / 1ps
`default_nettype none

module WriteBack(
    //control signal: 1 = from memory, 0 = from ALU
    input  wire MemtoReg, 
    //result from ALU          
    input  wire [31:0] ALUResult, 
    //data read from Data Memory   
    input  wire [31:0] MemData,        
    output reg  [31:0] WriteData
);

    //select between ALU result and memory output
    always @(*) begin
        case (MemtoReg)
            1'b0:    WriteData <= ALUResult;
            1'b1:    WriteData <= MemData;
            default: WriteData <= 32'hXXXX_XXXX;
        endcase
    end

endmodule

