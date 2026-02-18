module distortion (
    input  logic              CLOCK_50,      // Clock (optional, but good practice for future sync)
    input  logic              enable,   // SW[x]
    input  logic signed [31:0] in_L,    // Left Input
    input  logic signed [31:0] in_R,    // Right Input
    output logic signed [31:0] out_L,   // Left Output
    output logic signed [31:0] out_R    // Right Output
);

    // --- Thresholds (Tone Control) ---
    // Lower these values to get MORE distortion.
    // 32-bit Max is ~2,147,000,000.
    // Start curving at 15M and cap at 30M instead of 1M/2M
    localparam signed [31:0] SOFT_THRESH = 32'd15000000; 
    localparam signed [31:0] HARD_THRESH = 32'd30000000;

    always_comb begin
        if (!enable) begin
            // Bypass: Pass input directly to output
            out_L = in_L <<< 10;
            out_R = in_R <<< 10;
        end else begin
            
            // ============================================================
            // LEFT CHANNEL PROCESSING
            // ============================================================
            
            // --- POSITIVE CYCLE ---
            if (in_L >= 0) begin
                if (in_L < SOFT_THRESH) begin
                    out_L = in_L; // Clean
                end else if (in_L < HARD_THRESH) begin
                    // Soft Clip: Base + (Excess / 2)
                    out_L = SOFT_THRESH + ((in_L - SOFT_THRESH) >>> 1);
                end else begin
                    out_L = HARD_THRESH; // Hard Limit
                end
            end 
            // --- NEGATIVE CYCLE ---
            else begin
                if (in_L > -SOFT_THRESH) begin
                    out_L = in_L; // Clean
                end else if (in_L > -HARD_THRESH) begin
                    // Soft Clip Negative
                    out_L = -SOFT_THRESH - (-(in_L + SOFT_THRESH) >>> 1);
                end else begin
                    out_L = -HARD_THRESH; // Hard Limit
                end
            end

            // ============================================================
            // RIGHT CHANNEL PROCESSING (Exact Copy)
            // ============================================================

            // --- POSITIVE CYCLE ---
            if (in_R >= 0) begin
                if (in_R < SOFT_THRESH) begin
                    out_R = in_R;
                end else if (in_R < HARD_THRESH) begin
                    out_R = SOFT_THRESH + ((in_R - SOFT_THRESH) >>> 1);
                end else begin
                    out_R = HARD_THRESH;
                end
            end 
            // --- NEGATIVE CYCLE ---
            else begin
                if (in_R > -SOFT_THRESH) begin
                    out_R = in_R;
                end else if (in_R > -HARD_THRESH) begin
                    out_R = -SOFT_THRESH - (-(in_R + SOFT_THRESH) >>> 1);
                end else begin
                    out_R = -HARD_THRESH;
                end
            end
        end
    end

endmodule