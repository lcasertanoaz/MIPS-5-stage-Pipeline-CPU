`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Computer Architecture
// 
// Module - SignExtension.v
// Description - Sign extension module.
////////////////////////////////////////////////////////////////////////////////
module SignExtension(in, out);

    /* A 16-Bit input word */
    input wire [15:0] in;
    
    /* A 32-Bit output word */
    output wire [31:0] out;
    
    assign out = {{16{in[15]}}, in};

endmodule
