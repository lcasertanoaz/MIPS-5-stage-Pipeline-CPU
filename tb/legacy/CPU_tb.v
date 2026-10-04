`timescale 1ns / 1ps

module CPU_tb;
    reg  Clk;
    reg  Reset;
    wire [31:0] out_PC;
    wire [31:0] out_write_data;
    wire        out_regwrite;
    wire [4:0]  out_write_reg;

    integer f;
    integer i; 

    CPU dut (
        .Clk(Clk),
        .Reset(Reset),
        .out_PC(out_PC),
        .out_write_data(out_write_data),
        .out_regwrite(out_regwrite),     
        .out_write_reg(out_write_reg) 
    );

    // clock
    initial begin
        Clk = 0;
        forever #10 Clk = ~Clk;
    end

    // reset
    initial begin
        Reset = 1;
        @(posedge Clk); #1;
        @(posedge Clk); #1;
        @(posedge Clk); #1;
        Reset = 0;
    end

    initial begin
        $display("time   PC         RegWrite  rd   WriteData");
        $monitor("%4t  %h   %b        %0d   %h",
                 $time,
                 out_PC,
                 out_regwrite,    
                 out_write_reg,
                 out_write_data);
    end

    initial begin
        Reset = 1;
        @(posedge Clk); #1;
        @(posedge Clk); #1;
        @(posedge Clk); #1;
        Reset = 0;
    
        f = $fopen("output.txt", "w");
    
        for (i = 0; i < 427; i = i + 1) begin
            @(posedge Clk); #1;
            if (out_regwrite)
                $fwrite(f, "%0d\n", $signed(out_write_data));
        end
    
        $fclose(f);
        $finish;
    end

endmodule
