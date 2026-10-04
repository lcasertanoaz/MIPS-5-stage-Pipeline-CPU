`timescale 1ns / 1ps
//============================================================
// Testbench for WriteBack.v
//============================================================

module WriteBack_tb;

    reg MemtoReg;
    reg [31:0] ALUResult;
    reg [31:0] MemData;

    wire [31:0] WriteData;

    WriteBack uut (
        .MemtoReg(MemtoReg),
        .ALUResult(ALUResult),
        .MemData(MemData),
        .WriteData(WriteData)
    );

    initial begin
        $display("Starting WriteBack testbench");

        //ALUResult selected
        MemtoReg = 0;
        ALUResult = 32'hAAAA_BBBB;
        MemData = 32'h1111_2222;
        #10;
        $display("MemtoReg=0 | WriteData=%h (expect %h)", WriteData, ALUResult);

        //MemData selected
        MemtoReg = 1;
        #10;
        $display("MemtoReg=1 | WriteData=%h (expect %h)", WriteData, MemData);

        //Different values
        ALUResult = 32'hDEAD_BEEF;
        MemData = 32'hCAFE_FEED;
        #10;
        MemtoReg = 0;
        #10;
        $display("MemtoReg=0 | WriteData=%h (expect %h)", WriteData, ALUResult);
        MemtoReg = 1;
        #10;
        $display("MemtoReg=1 | WriteData=%h (expect %h)", WriteData, MemData);

        $display("Testbench completed.");
        $finish;
    end

endmodule