`timescale 1ns/100ps

module echo (
    input  logic              CLOCK_50,
    input  logic              enable,   
    input  logic signed [31:0] in_L,    
    input  logic signed [31:0] in_R,    
    output logic signed [31:0] out_L,   
    output logic signed [31:0] out_R    
);

    logic signed [31:0] cL1, cL2, cL3, cL4;
    logic signed [31:0] cR1, cR2, cR3, cR4;

    comb_filter #(.DEPTH(3203))  cfL1 (.clk(CLOCK_50), .enable(enable), .in(in_L), .out(cL1));
    comb_filter #(.DEPTH(3571))  cfL2 (.clk(CLOCK_50), .enable(enable), .in(in_L), .out(cL2));
    comb_filter #(.DEPTH(4211))  cfL3 (.clk(CLOCK_50), .enable(enable), .in(in_L), .out(cL3));
    comb_filter #(.DEPTH(4877))  cfL4 (.clk(CLOCK_50), .enable(enable), .in(in_L), .out(cL4));

    comb_filter #(.DEPTH(3301))  cfR1 (.clk(CLOCK_50), .enable(enable), .in(in_R), .out(cR1));
    comb_filter #(.DEPTH(3697))  cfR2 (.clk(CLOCK_50), .enable(enable), .in(in_R), .out(cR2));
    comb_filter #(.DEPTH(4337))  cfR3 (.clk(CLOCK_50), .enable(enable), .in(in_R), .out(cR3));
    comb_filter #(.DEPTH(4999))  cfR4 (.clk(CLOCK_50), .enable(enable), .in(in_R), .out(cR4));

    logic signed [33:0] wet_L, wet_R;
    logic signed [34:0] final_L, final_R;
    localparam signed [34:0] MAX_VAL = 35'sd2147483647;
    localparam signed [34:0] MIN_VAL = -35'sd2147483648;

    always_comb begin
        if (!enable) begin
            out_L = in_L;
            out_R = in_R;
            wet_L = 34'sh0;
            wet_R = 34'sh0;
            final_L = 35'sh0;
            final_R = 35'sh0;
        end else begin
            wet_L = 34'(cL1) + 34'(cL2) + 34'(cL3) + 34'(cL4);
            wet_R = 34'(cR1) + 34'(cR2) + 34'(cR3) + 34'(cR4);

            final_L = (35'(in_L) >>> 2) + (35'(wet_L) >>> 2);
            final_R = (35'(in_R) >>> 2) + (35'(wet_R) >>> 2);

            // Ensure output does not pass max/min values for audio and cause wrapping (crackles)
            if (final_L > MAX_VAL)      out_L = 32'h7FFFFFFF;
            else if (final_L < MIN_VAL) out_L = 32'h80000000;
            else                        out_L = final_L[31:0];

            if (final_R > MAX_VAL)      out_R = 32'h7FFFFFFF;
            else if (final_R < MIN_VAL) out_R = 32'h80000000;
            else                        out_R = final_R[31:0];
        end
    end
endmodule