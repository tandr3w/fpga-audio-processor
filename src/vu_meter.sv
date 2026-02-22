`timescale 1ns/1ps

module vu_meter (
    input  logic        clock,
    input  logic        reset,
    input  logic signed [31:0] audio_in_L,
    input  logic signed [31:0] audio_in_R,
    input  logic        audio_valid,
    output logic [9:0]  led_level
);

    // Parameters for decay and thresholds
    localparam DECAY_RATE = 16'd100;      // Decay amount per clock cycle
    localparam DECAY_COUNTER_MAX = 16'd50000;  // Decay every ~1ms at 50MHz
    
    // Threshold levels for 10 LEDs (logarithmic scaling)
    // Using upper 24 bits of 32-bit audio for comparison
    localparam logic [23:0] THRESHOLD_1  = 24'h00_0800;  // Lowest threshold
    localparam logic [23:0] THRESHOLD_2  = 24'h00_1000;
    localparam logic [23:0] THRESHOLD_3  = 24'h00_2000;
    localparam logic [23:0] THRESHOLD_4  = 24'h00_4000;
    localparam logic [23:0] THRESHOLD_5  = 24'h00_8000;
    localparam logic [23:0] THRESHOLD_6  = 24'h01_0000;
    localparam logic [23:0] THRESHOLD_7  = 24'h02_0000;
    localparam logic [23:0] THRESHOLD_8  = 24'h04_0000;
    localparam logic [23:0] THRESHOLD_9  = 24'h08_0000;
    localparam logic [23:0] THRESHOLD_10 = 24'h10_0000;  // Highest threshold
    
    // Internal signals
    logic [31:0] abs_audio_L;
    logic [31:0] abs_audio_R;
    logic [31:0] audio_magnitude;
    logic [31:0] peak_level;
    logic [15:0] decay_counter;
    logic [23:0] current_level;
    
    // Compute absolute value of left channel
    always_comb begin
        if (audio_in_L[31]) begin  // Negative
            abs_audio_L = ~audio_in_L + 1'b1;
        end else begin
            abs_audio_L = audio_in_L;
        end
    end
    
    // Compute absolute value of right channel
    always_comb begin
        if (audio_in_R[31]) begin  // Negative
            abs_audio_R = ~audio_in_R + 1'b1;
        end else begin
            abs_audio_R = audio_in_R;
        end
    end
    
    // Take maximum of left and right channels
    always_comb begin
        if (abs_audio_L > abs_audio_R) begin
            audio_magnitude = abs_audio_L;
        end else begin
            audio_magnitude = abs_audio_R;
        end
    end
    
    // Peak detection with decay
    always_ff @(posedge clock or posedge reset) begin
        if (reset) begin
            peak_level <= 32'h0;
            decay_counter <= 16'h0;
        end else begin
            if (audio_valid) begin
                // Update peak if current magnitude is higher
                if (audio_magnitude > peak_level) begin
                    peak_level <= audio_magnitude;
                    decay_counter <= 16'h0;
                end else begin
                    // Decay logic
                    if (decay_counter >= DECAY_COUNTER_MAX) begin
                        decay_counter <= 16'h0;
                        // Decay the peak level
                        if (peak_level > DECAY_RATE) begin
                            peak_level <= peak_level - DECAY_RATE;
                        end else begin
                            peak_level <= 32'h0;
                        end
                    end else begin
                        decay_counter <= decay_counter + 1'b1;
                    end
                end
            end
        end
    end
    
    // Extract upper 24 bits for threshold comparison
    assign current_level = peak_level[31:8];
    
    // Map level to LED outputs (bar graph style)
    always_comb begin
        if (current_level >= THRESHOLD_10) begin
            led_level = 10'b11_1111_1111;  // All 10 LEDs on
        end else if (current_level >= THRESHOLD_9) begin
            led_level = 10'b01_1111_1111;  // 9 LEDs on
        end else if (current_level >= THRESHOLD_8) begin
            led_level = 10'b00_1111_1111;  // 8 LEDs on
        end else if (current_level >= THRESHOLD_7) begin
            led_level = 10'b00_0111_1111;  // 7 LEDs on
        end else if (current_level >= THRESHOLD_6) begin
            led_level = 10'b00_0011_1111;  // 6 LEDs on
        end else if (current_level >= THRESHOLD_5) begin
            led_level = 10'b00_0001_1111;  // 5 LEDs on
        end else if (current_level >= THRESHOLD_4) begin
            led_level = 10'b00_0000_1111;  // 4 LEDs on
        end else if (current_level >= THRESHOLD_3) begin
            led_level = 10'b00_0000_0111;  // 3 LEDs on
        end else if (current_level >= THRESHOLD_2) begin
            led_level = 10'b00_0000_0011;  // 2 LEDs on
        end else if (current_level >= THRESHOLD_1) begin
            led_level = 10'b00_0000_0001;  // 1 LED on
        end else begin
            led_level = 10'b00_0000_0000;  // All LEDs off
        end
    end

endmodule
