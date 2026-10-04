`timescale 1ns / 1ps
// tb_regfile: self-checking test of RegisterFile
// (writes on the rising edge, reads registered on the falling edge)
module tb_regfile;
    reg         Clk = 1'b0;
    reg  [4:0]  ReadRegister1 = 0, ReadRegister2 = 0, WriteRegister = 0;
    reg  [31:0] WriteData = 0;
    reg         RegWrite = 1'b0;
    wire [31:0] ReadData1, ReadData2, v0, v1;
    integer     errors = 0, tests = 0;

    RegisterFile dut (.ReadRegister1(ReadRegister1), .ReadRegister2(ReadRegister2),
                      .WriteRegister(WriteRegister), .WriteData(WriteData),
                      .RegWrite(RegWrite), .Clk(Clk),
                      .ReadData1(ReadData1), .ReadData2(ReadData2), .v0(v0), .v1(v1));

    always #5 Clk = ~Clk;

    task write_reg(input [4:0] r, input [31:0] d, input we);
        begin
            @(negedge Clk);
            WriteRegister = r; WriteData = d; RegWrite = we;
            @(posedge Clk); #1;
            RegWrite = 1'b0;
        end
    endtask

    task expect_reg(input [4:0] r, input [31:0] expected);
        begin
            ReadRegister1 = r; ReadRegister2 = r;
            @(negedge Clk); #1;
            tests = tests + 1;
            if (ReadData1 !== expected || ReadData2 !== expected) begin
                $display("FAIL: $%0d read %h / %h, expected %h", r, ReadData1, ReadData2, expected);
                errors = errors + 1;
            end
        end
    endtask

    integer i;
    initial begin
        // every register starts at 0
        for (i = 0; i < 32; i = i + 1) expect_reg(i, 32'h0);

        write_reg(5, 32'hDEAD_BEEF, 1);  expect_reg(5, 32'hDEAD_BEEF);
        write_reg(31, 32'h1234_5678, 1); expect_reg(31, 32'h1234_5678);
        write_reg(5, 32'hFFFF_FFFF, 0);  expect_reg(5, 32'hDEAD_BEEF);   // RegWrite=0: no change
        write_reg(0, 32'hFFFF_FFFF, 1);  expect_reg(0, 32'h0);           // $zero is hardwired

        // $v0/$v1 debug ports track registers 2 and 3
        write_reg(2, 32'd17, 1); write_reg(3, 32'd16, 1);
        tests = tests + 1;
        if (v0 !== 32'd17 || v1 !== 32'd16) begin
            $display("FAIL: v0/v1 ports = %0d/%0d, expected 17/16", v0, v1);
            errors = errors + 1;
        end

        if (errors == 0) $display("TEST PASSED: %0d register file checks", tests);
        else             $display("FAIL: %0d of %0d register file checks", errors, tests);
        $finish;
    end
endmodule
