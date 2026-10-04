`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Computer Architecture
// 
// Module - ALU32Bit_tb.v
// Description - Test the 'ALU32Bit.v' module.
////////////////////////////////////////////////////////////////////////////////

module ALU32Bit_tb(); 

	reg [3:0] ALUControl;   // control bits for ALU operation
	reg [31:0] A, B;	        // inputs

	wire [31:0] ALUResult;	// answer
	wire Zero;	        // Zero=1 if ALUResult == 0

    ALU32Bit u0(
        .ALUControl(ALUControl), 
        .A(A), 
        .B(B), 
        .ALUResult(ALUResult), 
        .Zero(Zero)
    );

	initial begin
	  // default inputs
	  ALUControl = 4'b0000; A = 32'h0; B = 32'h0;
	  #1;
	
	  // add 
	  ALUControl = 4'b0000; A = 32'h0000_0001; B = 32'h0000_0002; #1;
	  $display("ADD  A=%h B=%h -> R=%h Z=%b", A, B, ALUResult, Zero);
	
	  // sub 
	  ALUControl = 4'b0001; A = 32'h0000_0005; B = 32'h0000_0005; #1;
	  $display("SUB  A=%h B=%h -> R=%h Z=%b", A, B, ALUResult, Zero);
	
	  // and / or / xor / nor
	  ALUControl = 4'b0010; A = 32'hF0F0_1234; B = 32'h0FF0_F00F; #1;
	  $display("AND  A=%h B=%h -> R=%h Z=%b", A, B, ALUResult, Zero);
	
	  ALUControl = 4'b0011; A = 32'h00F0_0000; B = 32'h0000_00F0; #1;
	  $display("OR   A=%h B=%h -> R=%h Z=%b", A, B, ALUResult, Zero);
	
	  ALUControl = 4'b0100; A = 32'hAAAA_AAAA; B = 32'h5555_5555; #1;
	  $display("XOR  A=%h B=%h -> R=%h Z=%b", A, B, ALUResult, Zero);
	
	  ALUControl = 4'b0101; A = 32'h0000_0000; B = 32'hFFFF_FFFF; #1;
	  $display("NOR  A=%h B=%h -> R=%h Z=%b", A, B, ALUResult, Zero);
	
	  // shifts
	  ALUControl = 4'b0110; A = 32'h0000_0001; B = 32'h0000_0004; #1;
	  $display("SLL  A=%h sh=%0d -> R=%h Z=%b", A, B[4:0], ALUResult, Zero);
	
	  ALUControl = 4'b0111; A = 32'h8000_0000; B = 32'h0000_0001; #1;
	  $display("SRL  A=%h sh=%0d -> R=%h Z=%b", A, B[4:0], ALUResult, Zero);
	
	  // slt (signed)
	  ALUControl = 4'b1000; A = 32'hFFFF_FFFF; B = 32'h0000_0001; #1;
	  $display("SLT  A=%h B=%h -> R=%h Z=%b", A, B, ALUResult, Zero);
	
	  // rotr (check sh=0 and sh>0)
	  ALUControl = 4'b1001; A = 32'h1234_5678; B = 32'h0000_0000; #1;
	  $display("ROTR A=%h sh=%0d -> R=%h Z=%b", A, B[4:0], ALUResult, Zero);
	
	  ALUControl = 4'b1001; A = 32'h8000_0001; B = 32'h0000_0001; #1;
	  $display("ROTR A=%h sh=%0d -> R=%h Z=%b", A, B[4:0], ALUResult, Zero);
	
	  // mul
	  ALUControl = 4'b1010; A = 32'h0000_0010; B = 32'h0000_0003; #1;
	  $display("MUL  A=%h B=%h -> R=%h Z=%b", A, B, ALUResult, Zero);
	
	  // passa
	  ALUControl = 4'b1011; A = 32'h0000_0000; B = 32'hDEAD_BEEF; #1;
	  $display("PASS A=%h      -> R=%h Z=%b", A, ALUResult, Zero);
	
	  ALUControl = 4'b1011; A = 32'h0000_0005; B = 32'h0000_0000; #1;
	  $display("PASS A=%h      -> R=%h Z=%b", A, ALUResult, Zero);
	
	  $display("ALU32Bit_tb done.");
	  $finish;
	end


endmodule

