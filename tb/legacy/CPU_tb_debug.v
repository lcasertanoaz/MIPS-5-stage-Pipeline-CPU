`timescale 1ns / 1ps

module CPU_tb;
    reg  Clk;
    reg  Reset;

    wire [31:0] out_PC;
    wire [31:0] out_write_data;
    wire        out_regwrite;
    wire [4:0]  out_write_reg;

    // Spy wires
    wire [31:0] out_v0;
    wire [31:0] out_v1;

    integer f;
    integer i; 

    // Instantiate CPU
    CPU dut (
        .Clk(Clk),
        .Reset(Reset),
        .out_PC(out_PC),
        .out_write_data(out_write_data),
        .out_regwrite(out_regwrite),
        .out_write_reg(out_write_reg),
        .out_v0(out_v0),        
        .out_v1(out_v1)       
    );

    // Clock Generation (50MHz)
    initial begin
        Clk = 0;
        forever #10 Clk = ~Clk;
    end

    // Reset Sequence
    initial begin
        Reset = 1;
        @(posedge Clk); #1;
        @(posedge Clk); #1;
        @(posedge Clk); #1;
        Reset = 0;
    end

    // Console Logging - General
    initial begin
        $display("Time     PC        RegW  rd   WriteData     v0(row)   v1(col)");
        $monitor("%7t  %h  %b     %2d   %h        %d        %d",
                 $time, out_PC, out_regwrite, out_write_reg, out_write_data, out_v0, out_v1);             
    end

    // Specific Monitor for v0/v1 changes
    always @(out_v0 or out_v1) begin
        if (!Reset) begin
            $display(">>> UPDATE DETECTED at %t: v0=%d, v1=%d <<<", $time, out_v0, out_v1);
        end
    end

    // File Output & Simulation Duration
    initial begin
        f = $fopen("output.txt", "w");
        
        // Wait for reset to release
        @(negedge Reset); 

        // Run for enough cycles to finish Test 1 (at least)
        for (i = 0; i < 200000000; i = i + 1) begin
            @(posedge Clk); #1;

            // Log writes to file
            if (out_regwrite)
                $fwrite(f, "PC:%h | WriteReg:%d | Data:%0d | v0:%0d | v1:%0d\n", 
                        out_PC, out_write_reg, $signed(out_write_data), out_v0, out_v1);
        end

        $display("Simulation finished due to cycle limit.");
        $fclose(f);
        $finish;
    end

endmodule
