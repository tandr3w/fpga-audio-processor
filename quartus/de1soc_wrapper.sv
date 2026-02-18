`timescale 1ns/100ps
`include "Audio_Controller/Audio_Controller.v"
`include "avconf/avconf.v"
`include "src/top.sv"

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
    output        VGA_CLK,

    // Audio CODEC
    inout         AUD_ADCLRCK, // ADC LR Clock
    input         AUD_ADCDAT,  // ADC Data
    inout         AUD_DACLRCK, // DAC LR Clock
    output        AUD_DACDAT,  // DAC Data
    inout         AUD_BCLK,    // Bit Clock
    output        AUD_XCK,     // Chip Clock

    // I2C for Audio Config
    output        FPGA_I2C_SCLK,
    inout         FPGA_I2C_SDAT
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

    wire [31:0] mic_to_logic_L, mic_to_logic_R; // port to receive input from logic
    wire [31:0] logic_to_spk_L, logic_to_spk_R; // port to send output to driver
    wire audio_in_available, audio_out_allowed;
    wire read_request, write_request;

    avconf cfg (
        .CLOCK_50      (CLOCK_50),
        .reset         (~KEY[0]),       // Reset when button 0 is pressed
        .FPGA_I2C_SCLK (FPGA_I2C_SCLK), // Connections to audio chip
        .FPGA_I2C_SDAT (FPGA_I2C_SDAT) 
    );

    Audio_Controller driver (
        .CLOCK_50                (CLOCK_50),
        .reset                   (~KEY[0]),     // Reset when button 0 is pressed

        .clear_audio_in_memory(1'b0),  
        .clear_audio_out_memory(1'b0),

        .audio_in_available(audio_in_available),
        .audio_out_allowed(audio_out_allowed),

        .read_audio_in           (read_request), // Only read and write when DE1-SOC signals availability
        .write_audio_out         (write_request),

        // Connect audio channels to effect generator
        .left_channel_audio_in   (mic_to_logic_L),
        .right_channel_audio_in  (mic_to_logic_R),
        .left_channel_audio_out  (logic_to_spk_L),
        .right_channel_audio_out (logic_to_spk_R),
        
        // Connections to Audio CODEC
        .AUD_ADCDAT              (AUD_ADCDAT),
        .AUD_DACDAT              (AUD_DACDAT),
        .AUD_BCLK                (AUD_BCLK),
        .AUD_ADCLRCK             (AUD_ADCLRCK),
        .AUD_DACLRCK             (AUD_DACLRCK),
        .AUD_XCK                 (AUD_XCK)
    );

    top effects (
        .CLOCK_50   (CLOCK_50),
        .switches   (SW),
        .audio_in_L (mic_to_logic_L),
        .audio_in_R (mic_to_logic_R),
        .audio_out_L(logic_to_spk_L),
        .audio_out_R(logic_to_spk_R),
        .audio_in_available(audio_in_available),
        .audio_out_allowed(audio_out_allowed),
        .read_audio_in(read_request),               
        .write_audio_out(write_request)          
    );

endmodule