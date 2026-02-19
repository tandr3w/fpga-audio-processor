`timescale 1ns/100ps

module distortion (
    input  logic              CLOCK_50,   
    input  logic              enable,     
    input  logic signed [31:0] in_L,      
    input  logic signed [31:0] in_R,      
    output logic signed [31:0] out_L,     
    output logic signed [31:0] out_R      
);

    // --- Thresholds ---
    localparam signed [31:0] SOFT_THRESH = 32'd15000000; 
    localparam signed [31:0] HARD_THRESH = 32'd30000000;

    // Intermediate registers for processing
    logic sign_L, sign_R;
    logic signed [31:0] abs_L, abs_R;
    logic signed [31:0] squash_L, squash_R;
    logic signed [31:0] makeup_L, makeup_R;

    always_comb begin
        if (!enable) begin
            out_L = in_L;
            out_R = in_R;
            sign_L = 1'b0;
            sign_R = 1'b0;
            abs_L = 32'sh0;
            abs_R = 32'sh0;
            squash_L = 32'sh0;
            squash_R = 32'sh0;
            makeup_L = 32'sh0;
            makeup_R = 32'sh0;
        end else begin
            sign_L = in_L[31];
            sign_R = in_R[31];
            
            abs_L = sign_L ? -in_L : in_L;
            abs_R = sign_R ? -in_R : in_R;

            // --- LEFT CHANNEL ---
            if (abs_L < SOFT_THRESH) begin
                squash_L = abs_L; 
            end else if (abs_L < HARD_THRESH) begin
                squash_L = SOFT_THRESH + ((abs_L - SOFT_THRESH) >>> 1);
            end else begin
                // Hard cap at exactly 22,500,000
                squash_L = SOFT_THRESH + ((HARD_THRESH - SOFT_THRESH) >>> 1); 
            end

            // --- RIGHT CHANNEL ---
            if (abs_R < SOFT_THRESH) begin
                squash_R = abs_R;
            end else if (abs_R < HARD_THRESH) begin
                squash_R = SOFT_THRESH + ((abs_R - SOFT_THRESH) >>> 1);
            end else begin
                squash_R = SOFT_THRESH + ((HARD_THRESH - SOFT_THRESH) >>> 1);
            end

            // Volume Compensation
            makeup_L = squash_L + (squash_L >>> 2) + (squash_L >>> 4);
            makeup_R = squash_R + (squash_R >>> 2) + (squash_R >>> 4);

            out_L = sign_L ? -makeup_L : makeup_L;
            out_R = sign_R ? -makeup_R : makeup_R;
            
        end
    end

endmodule