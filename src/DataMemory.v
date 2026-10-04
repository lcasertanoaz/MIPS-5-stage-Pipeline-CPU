`timescale 1ns / 1ps
`default_nettype none
////////////////////////////////////////////////////////////////////////////////
// Computer Architecture
// Module - data_memory.v
// Description - 32-Bit wide data memory (lw/sw/lh/sh/lb/sb, aligned)
// 
// Size select:
//   word : EX_MEM_HalfControl=0 & EX_MEM_ByteControl=0
//   half : EX_MEM_HalfControl=1
//   byte : EX_MEM_ByteControl=1
//
// INPUTS:
//   EX_MEM_Address     : byte address
//   EX_MEM_WriteData   : data to store
//   Clk                : rising-edge clock
//   EX_MEM_MemWrite    : write enable
//   EX_MEM_MemRead     : read enable
//   EX_MEM_HalfControl : select halfword
//   EX_MEM_ByteControl : select byte
//
// OUTPUTS:-
//   MEM_ReadData       : read data
//
// FUNCTIONALITY:
// Has a 1K memory using Address[11:2]. 
// MemWrite = 1 on posedge --> masked read/modify/write into Address, otherwise doesn't write.
// MemRead = 1 --> output word/half/byte (sign-extended) from address, otherwise it is 0x00000000.
//
// Write (synchronous):
//   On posedge when MemWrite=1:
//     - Build mask by size/offset
//     - Shift payload into lane
//     - masked RMW: (old & ~mask) | (payload & mask)
//
// Read (asynchronous):
//   If MemRead=0 â†’ 0x00000000
//   Else:
//     - word: return full word
//     - half: select lane, sign-extend
//     - byte: select lane, sign-extend
////////////////////////////////////////////////////////////////////////////////
module DataMemory(
    input  wire [31:0] EX_MEM_Address,
    input  wire [31:0] EX_MEM_WriteData,
    input  wire        Clk,
    input  wire        EX_MEM_MemWrite,
    input  wire        EX_MEM_MemRead,
    input  wire        EX_MEM_HalfControl,
    input  wire        EX_MEM_ByteControl,
    output reg  [31:0] MEM_ReadData
);

    // 1K x 32 memory, addressed by EX_MEM_Address[11:2]
    reg [31:0] memory [0:16383];

    // Masked-write temporaries
    reg [31:0] cur_word;
    reg [31:0] write_mask;
    reg [31:0] write_data_shifted;

    // Read temporaries
    reg [31:0] rd_word;
    reg [15:0] rd_half;
    reg [7:0]  rd_byte;

    // Memory by byte
    wire [13:0] word_index = EX_MEM_Address[15:2]; // 1024 words
    wire [1:0] byte_off   = EX_MEM_Address[1:0];  // byte within word

    initial begin
        $readmemh("data_memory.mem", memory);
    end

    // ===================== WRITE (posedge, masked) =====================
    always @(posedge Clk) begin
        if (EX_MEM_MemWrite) begin
            cur_word = memory[word_index];

            // choose write size/mask/data
            if (EX_MEM_HalfControl) begin
                // store halfword (aligned to [15:0] or [31:16])
                if (byte_off[1] == 1'b0) begin
                    write_mask          = 32'h0000_FFFF;
                    write_data_shifted  = {16'h0000, EX_MEM_WriteData[15:0]};
                end else begin
                    write_mask          = 32'hFFFF_0000;
                    write_data_shifted  = {EX_MEM_WriteData[15:0], 16'h0000};
                end
            end
            else if (EX_MEM_ByteControl) begin
                // store byte
                case (byte_off)
                    2'b00: begin
                        write_mask         = 32'h0000_00FF;
                        write_data_shifted = {24'h000000, EX_MEM_WriteData[7:0]};
                    end
                    2'b01: begin
                        write_mask         = 32'h0000_FF00;
                        write_data_shifted = {16'h0000, EX_MEM_WriteData[7:0], 8'h00};
                    end
                    2'b10: begin
                        write_mask         = 32'h00FF_0000;
                        write_data_shifted = {8'h00, EX_MEM_WriteData[7:0], 16'h0000};
                    end
                    2'b11: begin
                        write_mask         = 32'hFF00_0000;
                        write_data_shifted = {EX_MEM_WriteData[7:0], 24'h000000};
                    end
                endcase
            end
            else begin
                // store word
                write_mask         = 32'hFFFF_FFFF;
                write_data_shifted = EX_MEM_WriteData;
            end

            // read-modify-write
            memory[word_index] <= (cur_word & ~write_mask)
                                | (write_data_shifted & write_mask);
                                
            $display("DMEM W @%0t addr=%h off=%0d size=%s data=%h mask=%h payload=%h", $time, EX_MEM_Address, byte_off,
            EX_MEM_HalfControl ? "H" : EX_MEM_ByteControl ? "B" : "W", EX_MEM_WriteData, write_mask, write_data_shifted);
        end
    end

    // ===================== READ (asynchronous) =====================
    always @* begin
        if (!EX_MEM_MemRead) begin
            MEM_ReadData = 32'h0000_0000;
        end else begin
            rd_word = memory[word_index];

            if (EX_MEM_HalfControl) begin
                // halfword load with sign-extend (matches lab examples)
                rd_half = (byte_off[1] == 1'b0) ? rd_word[15:0] : rd_word[31:16];
                MEM_ReadData = {{16{rd_half[15]}}, rd_half};
            end
            else if (EX_MEM_ByteControl) begin
                // byte load with sign-extend
                case (byte_off)
                    2'b00: rd_byte = rd_word[7:0];
                    2'b01: rd_byte = rd_word[15:8];
                    2'b10: rd_byte = rd_word[23:16];
                    2'b11: rd_byte = rd_word[31:24];
                endcase
                MEM_ReadData = {{24{rd_byte[7]}}, rd_byte};
            end
            else begin
                // word load
                MEM_ReadData = rd_word;
            end
        end
    end

endmodule
