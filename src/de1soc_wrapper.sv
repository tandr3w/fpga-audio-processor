`timescale 1ns/100ps

module de1soc_wrapper (
    input         CLOCK_50,
    input  [9:0]  SW,
    input  [3:0]  KEY,

    inout         PS2_CLK,
    inout         PS2_DAT,

    output [6:0]  HEX5,
    output [6:0]  HEX4,
    output [6:0]  HEX3,
    output [6:0]  HEX2,
    output [6:0]  HEX1,
    output [6:0]  HEX0,

    output [9:0]  LEDR,

    output [7:0]  VGA_R,
    output [7:0]  VGA_G,
    output [7:0]  VGA_B,
    output        VGA_HS,
    output        VGA_VS,
    output        VGA_BLANK_N,
    output        VGA_SYNC_N,
    output        VGA_CLK
);

    // Default Assignments

    // LEDs off
    assign LEDR = 10'b0;

    // HEX displays off (active-low)
    assign HEX0 = 7'b1111111;
    assign HEX1 = 7'b1111111;
    assign HEX2 = 7'b1111111;
    assign HEX3 = 7'b1111111;

    // VGA outputs black / inactive
    assign VGA_R = 8'b0;
    assign VGA_G = 8'b0;
    assign VGA_B = 8'b0;

    assign VGA_HS      = 1'b1;
    assign VGA_VS      = 1'b1;
    assign VGA_BLANK_N = 1'b1;
    assign VGA_SYNC_N  = 1'b0;
    assign VGA_CLK     = CLOCK_50;

endmodule