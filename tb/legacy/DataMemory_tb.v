`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Computer Architecture
//
// Module - DataMemory_tb.v
// Description - Basic functional test of DataMemory.v
////////////////////////////////////////////////////////////////////////////////

module DataMemory_tb;

    // DUT inputs
    reg  [31:0] EX_MEM_Address;
    reg  [31:0] EX_MEM_WriteData;
    reg         Clk;
    reg         EX_MEM_MemWrite;
    reg         EX_MEM_MemRead;
    reg         EX_MEM_HalfControl;
    reg         EX_MEM_ByteControl;

    // DUT output
    wire [31:0] MEM_ReadData;

    // Instantiate DUT
    DataMemory dut (
        .EX_MEM_Address(EX_MEM_Address),
        .EX_MEM_WriteData(EX_MEM_WriteData),
        .Clk(Clk),
        .EX_MEM_MemWrite(EX_MEM_MemWrite),
        .EX_MEM_MemRead(EX_MEM_MemRead),
        .EX_MEM_HalfControl(EX_MEM_HalfControl),
        .EX_MEM_ByteControl(EX_MEM_ByteControl),
        .MEM_ReadData(MEM_ReadData)
    );

    // Clock gen: 20ns period
    initial begin
        Clk = 1'b0;
        forever #10 Clk = ~Clk;
    end

    // Stimulus
    initial begin
        // init all control signals
        EX_MEM_Address      = 32'h0000_0000;
        EX_MEM_WriteData    = 32'h0000_0000;
        EX_MEM_MemWrite     = 1'b0;
        EX_MEM_MemRead      = 1'b0;
        EX_MEM_HalfControl  = 1'b0;
        EX_MEM_ByteControl  = 1'b0;

        // Wait till posedge
        #5;
    
        // ================= TEST 1: store word / load word =================
        
        // --- WRITE 0x11111111 to addr 0x00000000 ---
        EX_MEM_Address      = 32'h0000_0000;
        EX_MEM_WriteData    = 32'h1111_1111;
        EX_MEM_HalfControl  = 1'b0;  // word
        EX_MEM_ByteControl  = 1'b0;  // word
        EX_MEM_MemWrite     = 1'b1;
        EX_MEM_MemRead      = 1'b0;
        
        // --- READ addr 0x00000000 ---
        @(posedge Clk); #1;
        EX_MEM_MemWrite     = 1'b0;
        EX_MEM_MemRead      = 1'b1; #1;
        $display("T1 word rd @0x00000000 = 0x%08h (expect 0x11111111)", MEM_ReadData);
        EX_MEM_MemRead      = 1'b0; #5;

        // ================= TEST 2: halfword low =================
        // write 0xAAAA into low half of word @0x4
        EX_MEM_Address      = 32'h0000_0004;       // byte_off = 2'b00
        EX_MEM_WriteData    = 32'h0000_AAAA;
        EX_MEM_HalfControl  = 1'b1;                // half store
        EX_MEM_ByteControl  = 1'b0;
        EX_MEM_MemWrite     = 1'b1;
        
        // --- READ addr 0x00000004 ---
        @(posedge Clk); #1;
        EX_MEM_MemWrite     = 1'b0;
        EX_MEM_MemRead      = 1'b1; #1;
        $display("T2 half-low rd @0x00000004 = 0x%08h (expect signext(0xAAAA))", MEM_ReadData);
        EX_MEM_MemRead      = 1'b0; #5;

        // ============= TEST 3: store halfword high / load halfword high =============
        // Write 0xBBBB into upper half of same word @0x6 (byte_off[1]==1)
        EX_MEM_Address      = 32'h0000_0006;       // byte_off = 2'b10 -> high half
        EX_MEM_WriteData    = 32'h0000_BBBB;
        EX_MEM_HalfControl  = 1'b1;
        EX_MEM_ByteControl  = 1'b0;
        EX_MEM_MemWrite     = 1'b1;
        
        // --- READ addr 0x00000006 ---
        @(posedge Clk); #1;
        EX_MEM_MemWrite     = 1'b0;
        EX_MEM_MemRead      = 1'b1; #1;
        $display("T3 half-high rd @0x00000006 = 0x%08h (expect signext(0xBBBB))", MEM_ReadData);
        EX_MEM_MemRead      = 1'b0;

        // --- READ addr 0x00000004 to check halving at 0x00000006 ---
        EX_MEM_Address      = 32'h0000_0004;
        EX_MEM_HalfControl  = 1'b0;
        EX_MEM_ByteControl  = 1'b0;
        EX_MEM_MemRead      = 1'b1; #1;
        $display("T3 full word @0x00000004 = 0x%08h (expect 0xBBBB_AAAA)", MEM_ReadData);
        EX_MEM_MemRead      = 1'b0; #5;

        // ============= TEST 4: store byte in each lane / load byte =============
        // We'll use address 0x8 and write each byte separately.
        // Byte 0 (LSB) = 0x11 at addr 0x8
        EX_MEM_Address      = 32'h0000_0008;       // byte_off 00
        EX_MEM_WriteData    = 32'h0000_0011;
        EX_MEM_HalfControl  = 1'b0;
        EX_MEM_ByteControl  = 1'b1;
        EX_MEM_MemWrite     = 1'b1;
        
        @(posedge Clk); #1;
        EX_MEM_MemWrite     = 1'b0;

        // Byte 1 = 0x22 at addr 0x9
        EX_MEM_Address      = 32'h0000_0009;       // byte_off 01
        EX_MEM_WriteData    = 32'h0000_0022;
        EX_MEM_ByteControl  = 1'b1;
        EX_MEM_MemWrite     = 1'b1;
        @(posedge Clk); #1;
        EX_MEM_MemWrite     = 1'b0;

        // Byte 2 = 0x33 at addr 0xA
        EX_MEM_Address      = 32'h0000_000A;       // byte_off 10
        EX_MEM_WriteData    = 32'h0000_0033;
        EX_MEM_ByteControl  = 1'b1;
        EX_MEM_MemWrite     = 1'b1;
        @(posedge Clk); #1;
        EX_MEM_MemWrite     = 1'b0;

        // Byte 3 = 0x44 at addr 0xB
        EX_MEM_Address      = 32'h0000_000B;       // byte_off 11
        EX_MEM_WriteData    = 32'h0000_0044;
        EX_MEM_ByteControl  = 1'b1;
        EX_MEM_MemWrite     = 1'b1;
        @(posedge Clk); #1;
        EX_MEM_MemWrite     = 1'b0;

        // Read full word @0x8
        EX_MEM_Address      = 32'h0000_0008;
        EX_MEM_ByteControl  = 1'b0;
        EX_MEM_HalfControl  = 1'b0;
        EX_MEM_MemRead      = 1'b1;
        #1;
        $display("T4 word @0x00000008 = 0x%08h (expect 0x44332211)", MEM_ReadData);
        EX_MEM_MemRead      = 1'b0;

        // Also read just the byte at 0xA (should sign-extend 0x33)
        EX_MEM_Address      = 32'h0000_000A;
        EX_MEM_ByteControl  = 1'b1;
        EX_MEM_HalfControl  = 1'b0;
        EX_MEM_MemRead      = 1'b1; #1;
        $display("T4 byte @0x0000000A = 0x%08h (expect signext(0x33))", MEM_ReadData);
        EX_MEM_MemRead      = 1'b0;

        // ============= TEST 5: MemRead=0 output zero =============
        EX_MEM_Address      = 32'h0000_0000;
        EX_MEM_ByteControl  = 1'b0;
        EX_MEM_HalfControl  = 1'b0;
        EX_MEM_MemRead      = 1'b0; #1;
        $display("T5 MemRead=0 -> 0x%08h (expect 0x00000000)", MEM_ReadData);

        #20;
        $finish;
    end

endmodule