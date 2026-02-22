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
    logic signed [31:0] post_L, post_R;

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
            post_L = 32'sh0;
            post_R = 32'sh0;
        end else begin
            sign_L = in_L[31];
            sign_R = in_R[31];
            
            // 1. DRIVE (Pre-Gain): Push signal into the clipping thresholds (4x multiplier)
            abs_L = sign_L ? -(in_L <<< 2) : (in_L <<< 2);
            abs_R = sign_R ? -(in_R <<< 2) : (in_R <<< 2);

            // --- LEFT CHANNEL (Clipping logic) ---
            if (abs_L < SOFT_THRESH) begin
                squash_L = abs_L;
            end else if (abs_L < HARD_THRESH) begin
                squash_L = SOFT_THRESH + ((abs_L - SOFT_THRESH) >>> 1);
            end else begin
                squash_L = SOFT_THRESH + ((HARD_THRESH - SOFT_THRESH) >>> 1);
            end

            // --- RIGHT CHANNEL (Clipping logic) ---
            if (abs_R < SOFT_THRESH) begin
                squash_R = abs_R;
            end else if (abs_R < HARD_THRESH) begin
                squash_R = SOFT_THRESH + ((abs_R - SOFT_THRESH) >>> 1);
            end else begin
                squash_R = SOFT_THRESH + ((HARD_THRESH - SOFT_THRESH) >>> 1);
            end

            // 2. REAPPLY SIGNS
            post_L = sign_L ? -squash_L : squash_L;
            post_R = sign_R ? -squash_R : squash_R;
            
            // 3. MAKEUP GAIN (Post-Gain)
            // Multiply the final squashed signal by 2 (shift left by 1) to make it louder.
            // Since our hard cap is ~22.5 million, multiplying by 2 (45 million) 
            // is still completely safe inside the 32-bit limit (2.14 billion).
            out_L = post_L <<< 1; 
            out_R = post_R <<< 1;
            
        end
    end

endmodule