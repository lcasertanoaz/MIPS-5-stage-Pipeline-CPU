`timescale 1ns / 1ps
// tb_alu: self-checking test of ALU32Bit (all 12 operations + Zero flag)
module tb_alu;
    reg  [3:0]  ALUControl;
    reg  [31:0] A, B;
    reg  [4:0]  shamt;
    wire [31:0] ALUResult;
    wire        Zero;
    integer     errors = 0, tests = 0;

    ALU32Bit dut (.ALUControl(ALUControl), .A(A), .B(B), .shamt(shamt),
                  .ALUResult(ALUResult), .Zero(Zero));

    task check(input [3:0] op, input [31:0] a, input [31:0] b, input [4:0] sh,
               input [31:0] expected, input [8*5:1] name);
        begin
            ALUControl = op; A = a; B = b; shamt = sh; #1;
            tests = tests + 1;
            if (ALUResult !== expected || Zero !== (expected == 32'd0)) begin
                $display("FAIL: %s A=%h B=%h sh=%0d -> %h (Z=%b), expected %h",
                         name, a, b, sh, ALUResult, Zero, expected);
                errors = errors + 1;
            end
        end
    endtask

    initial begin
        check(4'b0000, 32'h0000_0001, 32'h0000_0002, 0, 32'h0000_0003, "ADD");
        check(4'b0000, 32'hFFFF_FFFF, 32'h0000_0001, 0, 32'h0000_0000, "ADD");   // wraps, Zero=1
        check(4'b0001, 32'h0000_0005, 32'h0000_0005, 0, 32'h0000_0000, "SUB");
        check(4'b0001, 32'h0000_0003, 32'h0000_0005, 0, 32'hFFFF_FFFE, "SUB");
        check(4'b0010, 32'hF0F0_1234, 32'h0FF0_F00F, 0, 32'h00F0_1004, "AND");
        check(4'b0011, 32'h00F0_0000, 32'h0000_00F0, 0, 32'h00F0_00F0, "OR");
        check(4'b0100, 32'hAAAA_AAAA, 32'h5555_5555, 0, 32'hFFFF_FFFF, "XOR");
        check(4'b0101, 32'h0000_0000, 32'hFFFF_FFFF, 0, 32'h0000_0000, "NOR");
        check(4'b0110, 32'h0000_0000, 32'h0000_0001, 4, 32'h0000_0010, "SLL");   // shifts use B
        check(4'b0111, 32'h0000_0000, 32'h8000_0000, 1, 32'h4000_0000, "SRL");
        check(4'b1000, 32'hFFFF_FFFF, 32'h0000_0001, 0, 32'h0000_0001, "SLT");   // signed -1 < 1
        check(4'b1000, 32'h0000_0001, 32'hFFFF_FFFF, 0, 32'h0000_0000, "SLT");
        check(4'b1001, 32'h1234_5678, 32'h0, 0, 32'h1234_5678, "ROTR");          // rotate uses A
        check(4'b1001, 32'h8000_0001, 32'h0, 1, 32'hC000_0000, "ROTR");
        check(4'b1001, 32'h1234_5678, 32'h0, 8, 32'h7812_3456, "ROTR");
        check(4'b1010, 32'h0000_0010, 32'h0000_0003, 0, 32'h0000_0030, "MUL");
        check(4'b1010, 32'hFFFF_FFFF, 32'h0000_0002, 0, 32'hFFFF_FFFE, "MUL");
        check(4'b1011, 32'h0000_0005, 32'hDEAD_BEEF, 0, 32'h0000_0005, "PASSA");

        if (errors == 0) $display("TEST PASSED: %0d ALU checks", tests);
        else             $display("FAIL: %0d of %0d ALU checks", errors, tests);
        $finish;
    end
endmodule
