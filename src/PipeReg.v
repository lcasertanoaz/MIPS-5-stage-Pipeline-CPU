`timescale 1ns / 1ps
`default_nettype none

// On every rising edge, if Reset=1 -> clear to 0
// otherwise -> pass input
// WIDTH parameter ensures proper sizing
module PipeReg #(parameter WIDTH = 1)(
    input  wire              Clk,
    input  wire              Reset,
    input  wire              stall,
    input  wire [WIDTH-1:0]  in,
    output reg  [WIDTH-1:0]  out
);
    always @(posedge Clk) begin
        if (Reset) begin
            out <= {WIDTH{1'b0}};
        end else begin
            if(!stall) begin
                out <= in; 
            end
        end
    end
endmodule
