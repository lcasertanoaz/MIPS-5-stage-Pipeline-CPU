`timescale 1ns / 1ps
module HazardDetectionUnit (
    input  wire [31:0] IF_ID_Instruction,  // instr in ID
    input  wire        ID_EX_RegWrite,     // from ID_EX pipe
    input  wire [4:0]  ID_EX_WriteReg,     // from ID_EX pipe
    input  wire [4:0]  EX_MEM_WriteReg,    // from EX/MEM pipe
    input  wire        EX_MEM_RegWrite,    // from EX/MEM pipe
    input  wire        ID_EX_MemWrite,
    input  wire        EX_MEM_MemWrite,
    
    output wire         PCWrite,            // 0 => freeze PC
    output wire         IF_ID_Write,        // 0 => freeze IF/ID
    output wire         ID_EX_Bubble        // 1 => insert bubble into EX
);
    // fields from ID instruction
    wire [5:0] op = IF_ID_Instruction[31:26];
    wire [4:0] rs = IF_ID_Instruction[25:21];
    wire [4:0] rt = IF_ID_Instruction[20:16];

    localparam SPECIAL = 6'b000000;
    localparam SPECIAL2= 6'b011100;

    localparam BEQ     = 6'b000100;
    localparam BNE     = 6'b000101;
    localparam REGIMM  = 6'b000001; 
    localparam BGTZ    = 6'b000111;
    localparam BLEZ    = 6'b000110;

    localparam J       = 6'b000010;
    localparam JAL     = 6'b000011;

    // Stores
    localparam SB      = 6'b101000;
    localparam SH      = 6'b101001;
    localparam SW      = 6'b101011;
    
    // Loads
    localparam LW      = 6'b100011;
    localparam LH      = 6'b100001;
    localparam LB      = 6'b100000;

    wire isR              = (op==SPECIAL) || (op==SPECIAL2);
    wire equality_branch  = (op==BEQ) || (op==BNE);
    wire is_load          = (op==LW)||(op==LH)||(op==LB);
    wire is_store         = (op==SB) || (op==SH) || (op==SW);
    
    wire uses_rs = ~(op==J || op==JAL);
    wire uses_rt = isR || is_store || equality_branch;
    
    wire cEX_rs  = ID_EX_RegWrite  && (ID_EX_WriteReg  != 5'd0) && (ID_EX_WriteReg  == rs);
    wire cEX_rt  = ID_EX_RegWrite  && (ID_EX_WriteReg  != 5'd0) && (ID_EX_WriteReg  == rt);
    wire cMEM_rs = EX_MEM_RegWrite && (EX_MEM_WriteReg != 5'd0) && (EX_MEM_WriteReg == rs);
    wire cMEM_rt = EX_MEM_RegWrite && (EX_MEM_WriteReg != 5'd0) && (EX_MEM_WriteReg == rt);
    
    wire store_in_pipe = ID_EX_MemWrite | EX_MEM_MemWrite;

    wire hazard_rs = uses_rs && (rs!=5'd0) && (cEX_rs || cMEM_rs);
    wire hazard_rt = uses_rt && (rt!=5'd0) && (cEX_rt || cMEM_rt);
    
    wire stall_raw = hazard_rs || hazard_rt;
    wire stall_memorder = store_in_pipe && is_load;


    wire stall = stall_raw | stall_memorder;

    assign PCWrite     = ~stall;
    assign IF_ID_Write = ~stall;
    assign ID_EX_Bubble=  stall;
endmodule
