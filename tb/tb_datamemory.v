`timescale 1ns / 1ps
// tb_datamemory: self-checking test of DataMemory
// (word / halfword / byte stores with masking, sign-extended loads)
module tb_datamemory;
    reg         Clk = 1'b0;
    reg  [31:0] Address = 0, WriteData = 0;
    reg         MemWrite = 0, MemRead = 0, Half = 0, Byte = 0;
    wire [31:0] ReadData;
    integer     errors = 0, tests = 0;

    DataMemory dut (.EX_MEM_Address(Address), .EX_MEM_WriteData(WriteData), .Clk(Clk),
                    .EX_MEM_MemWrite(MemWrite), .EX_MEM_MemRead(MemRead),
                    .EX_MEM_HalfControl(Half), .EX_MEM_ByteControl(Byte),
                    .MEM_ReadData(ReadData));

    always #5 Clk = ~Clk;

    // size: 0 = word, 1 = half, 2 = byte
    task store(input [31:0] addr, input [31:0] data, input [1:0] size);
        begin
            @(negedge Clk);
            Address = addr; WriteData = data; MemRead = 0;
            Half = (size == 1); Byte = (size == 2); MemWrite = 1;
            @(posedge Clk); #1;
            MemWrite = 0;
        end
    endtask

    task load(input [31:0] addr, input [1:0] size, input [31:0] expected);
        begin
            @(negedge Clk);
            Address = addr; Half = (size == 1); Byte = (size == 2); MemRead = 1; #1;
            tests = tests + 1;
            if (ReadData !== expected) begin
                $display("FAIL: load size=%0d @%h = %h, expected %h", size, addr, ReadData, expected);
                errors = errors + 1;
            end
            MemRead = 0;
        end
    endtask

    initial begin
        // use addresses past the program's data image
        store(32'h8000, 32'h1111_1111, 0);  load(32'h8000, 0, 32'h1111_1111);

        store(32'h8004, 32'h0000_0000, 0);
        store(32'h8004, 32'h0000_AAAA, 1);  load(32'h8004, 1, 32'hFFFF_AAAA);  // sign-extended
        store(32'h8006, 32'h0000_7BBB, 1);  load(32'h8006, 1, 32'h0000_7BBB);
        load(32'h8004, 0, 32'h7BBB_AAAA);                                      // both halves kept

        store(32'h8008, 32'h0000_0000, 0);
        store(32'h8008, 32'h11, 2); store(32'h8009, 32'h22, 2);
        store(32'h800A, 32'h33, 2); store(32'h800B, 32'h84, 2);
        load(32'h8008, 0, 32'h8433_2211);
        load(32'h800A, 2, 32'h0000_0033);
        load(32'h800B, 2, 32'hFFFF_FF84);                                      // sign-extended

        // MemRead = 0 returns 0
        @(negedge Clk); Address = 32'h8000; MemRead = 0; Half = 0; Byte = 0; #1;
        tests = tests + 1;
        if (ReadData !== 32'h0) begin
            $display("FAIL: MemRead=0 returned %h", ReadData); errors = errors + 1;
        end

        if (errors == 0) $display("TEST PASSED: %0d data memory checks", tests);
        else             $display("FAIL: %0d of %0d data memory checks", errors, tests);
        $finish;
    end
endmodule
