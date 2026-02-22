`timescale 1ns/100ps

module distortion (
    input  logic              CLOCK_50,   
    input  logic              enable,  
    input  logic              high,   
    input  logic signed [31:0] in_L,      
    input  logic signed [31:0] in_R,      
    output logic signed [31:0] out_L,     
    output logic signed [31:0] out_R      
);

    logic signed [31:0] SOFT_THRESH = 32'd20000000; // 200 Million
    logic signed [31:0] HARD_THRESH = 32'd80000000; // 1 Billion

    logic sign_L, sign_R;
    logic signed [31:0] abs_L, abs_R;
    logic signed [31:0] squash_L, squash_R;

    always_comb begin
        if (high) begin
            SOFT_THRESH = 32'd200000000;
            HARD_THRESH = 32'd800000000;
        end else begin
            SOFT_THRESH = 32'd20000000;
            HARD_THRESH = 32'd80000000;
        end    
        if (!enable) begin
            out_L = in_L;
            out_R = in_R;
            sign_L = 0; sign_R = 0;
            abs_L = 0; abs_R = 0;
            squash_L = 0; squash_R = 0;
        end else begin
            sign_L = in_L[31];
            sign_R = in_R[31];
            
            // No Drive (1.0x gain) to keep things clean
            abs_L = (sign_L ? -in_L : in_L);
            abs_R = (sign_R ? -in_R : in_R);

            // --- LEFT CHANNEL ---
            if (abs_L < SOFT_THRESH) begin
                squash_L = abs_L; // 100% Clean
            end else if (abs_L < HARD_THRESH) begin
                // This zone is now 800 million units wide.
                // We use a gentle 3/4 slope here.
                automatic logic signed [31:0] diff = abs_L - SOFT_THRESH;
                squash_L = SOFT_THRESH + (diff - (diff >>> 2));
            end else begin
                // The hard cap only happens at the very extreme peaks.
                automatic logic signed [31:0] max_diff = HARD_THRESH - SOFT_THRESH;
                squash_L = SOFT_THRESH + (max_diff - (max_diff >>> 2));
            end

            // --- RIGHT CHANNEL ---
            if (abs_R < SOFT_THRESH) begin
                squash_R = abs_R;
            end else if (abs_R < HARD_THRESH) begin
                automatic logic signed [31:0] diff = abs_R - SOFT_THRESH;
                squash_R = SOFT_THRESH + (diff - (diff >>> 2));
            end else begin
                automatic logic signed [31:0] max_diff = HARD_THRESH - SOFT_THRESH;
                squash_R = SOFT_THRESH + (max_diff - (max_diff >>> 2));
            end

            out_L = sign_L ? -squash_L : squash_L;
            out_R = sign_R ? -squash_R : squash_R;
        end
    end

endmodule