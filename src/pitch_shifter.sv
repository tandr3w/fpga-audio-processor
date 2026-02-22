`timescale 1ns/100ps

module pitch_shifter (
    input  logic              CLOCK_50,
    input  logic              tick,
    input  logic              enable,
    input  logic [15:0]       pitch_ratio, 
    input  logic signed [31:0] in_L,
    input  logic signed [31:0] in_R,
    output logic signed [31:0] out_L,
    output logic signed [31:0] out_R
);

    localparam int DEPTH = 4096;
    
    // --- MEMORY REPLICATION FOR M10K INFERENCE ---
    logic signed [31:0] mem_L_a0 [DEPTH-1:0] = '{default:0};
    logic signed [31:0] mem_L_a1 [DEPTH-1:0] = '{default:0};
    logic signed [31:0] mem_L_b0 [DEPTH-1:0] = '{default:0};
    logic signed [31:0] mem_L_b1 [DEPTH-1:0] = '{default:0};

    logic signed [31:0] mem_R_a0 [DEPTH-1:0] = '{default:0};
    logic signed [31:0] mem_R_a1 [DEPTH-1:0] = '{default:0};
    logic signed [31:0] mem_R_b0 [DEPTH-1:0] = '{default:0};
    logic signed [31:0] mem_R_b1 [DEPTH-1:0] = '{default:0};

    logic [11:0] w_ptr = 0;      
    logic [27:0] r_ptr_a = 0;    
    logic [27:0] r_ptr_b;        
    
    // Offset Head B by exactly half the buffer (2048 samples)
    assign r_ptr_b = r_ptr_a + 28'h0800000;

    logic [11:0] a0, a1, b0, b1;
    assign a0 = r_ptr_a[27:16];
    assign a1 = r_ptr_a[27:16] + 12'd1;
    assign b0 = r_ptr_b[27:16];
    assign b1 = r_ptr_b[27:16] + 12'd1;

    logic signed [31:0] vA0L=0, vA1L=0, vB0L=0, vB1L=0;
    logic signed [31:0] vA0R=0, vA1R=0, vB0R=0, vB1R=0;

    // --- DEDICATED READ BLOCK ---
    always_ff @(posedge CLOCK_50) begin
        vA0L <= mem_L_a0[a0]; 
        vA1L <= mem_L_a1[a1];
        vB0L <= mem_L_b0[b0]; 
        vB1L <= mem_L_b1[b1];
        
        vA0R <= mem_R_a0[a0]; 
        vA1R <= mem_R_a1[a1];
        vB0R <= mem_R_b0[b0]; 
        vB1R <= mem_R_b1[b1];
    end

    localparam signed [63:0] MAX_VAL = 64'sd2147483647;
    localparam signed [63:0] MIN_VAL = -64'sd2147483648;

    // --- DSP PROCESSING BLOCK ---
    always_ff @(posedge CLOCK_50) begin
        if (!enable) begin
            out_L <= in_L;
            out_R <= in_R;
        end else if (tick) begin
            
            // --- DEDICATED WRITE BLOCK ---
            mem_L_a0[w_ptr] <= in_L;
            mem_L_a1[w_ptr] <= in_L;
            mem_L_b0[w_ptr] <= in_L;
            mem_L_b1[w_ptr] <= in_L;

            mem_R_a0[w_ptr] <= in_R;
            mem_R_a1[w_ptr] <= in_R;
            mem_R_b0[w_ptr] <= in_R;
            mem_R_b1[w_ptr] <= in_R;

            begin
                automatic logic [15:0] fa, fb;
                automatic logic [11:0] dist_a;
                automatic logic [15:0] gain_a;

                automatic logic signed [63:0] diff_AL, diff_AR, diff_BL, diff_BR;
                automatic logic signed [63:0] mult_AL, mult_AR, mult_BL, mult_BR;
                automatic logic signed [31:0] iAL, iAR, iBL, iBR;
                automatic logic signed [63:0] cross_AL, cross_AR, cross_BL, cross_BR;
                automatic logic signed [63:0] sum_L, sum_R;

                fa = r_ptr_a[15:0];
                fb = r_ptr_b[15:0];
                
                dist_a = w_ptr - r_ptr_a[27:16];
                
                if (dist_a < 12'd64) begin
                    gain_a = 16'(dist_a[5:0]) << 10;
                end else if (dist_a > 12'd4031) begin  
                    gain_a = 16'(6'(~dist_a[5:0])) << 10;      
                end else begin
                    gain_a = 16'hFFFF;                 
                end

                diff_AL = 64'($signed(vA1L)) - 64'($signed(vA0L));
                diff_AR = 64'($signed(vA1R)) - 64'($signed(vA0R));
                diff_BL = 64'($signed(vB1L)) - 64'($signed(vB0L));
                diff_BR = 64'($signed(vB1R)) - 64'($signed(vB0R));

                mult_AL = diff_AL * $signed({1'b0, fa});
                mult_AR = diff_AR * $signed({1'b0, fa});
                mult_BL = diff_BL * $signed({1'b0, fb});
                mult_BR = diff_BR * $signed({1'b0, fb});

                iAL = vA0L + mult_AL[47:16];
                iAR = vA0R + mult_AR[47:16];
                iBL = vB0L + mult_BL[47:16];
                iBR = vB0R + mult_BR[47:16];

                cross_AL = $signed(iAL) * $signed({1'b0, gain_a});
                cross_AR = $signed(iAR) * $signed({1'b0, gain_a});
                cross_BL = $signed(iBL) * $signed({1'b0, ~gain_a});
                cross_BR = $signed(iBR) * $signed({1'b0, ~gain_a});

                sum_L = 64'($signed(cross_AL[47:16])) + 64'($signed(cross_BL[47:16]));
                sum_R = 64'($signed(cross_AR[47:16])) + 64'($signed(cross_BR[47:16]));

                if (sum_L > MAX_VAL)      out_L <= 32'h7FFFFFFF;
                else if (sum_L < MIN_VAL) out_L <= 32'h80000000;
                else                      out_L <= sum_L[31:0];

                if (sum_R > MAX_VAL)      out_R <= 32'h7FFFFFFF;
                else if (sum_R < MIN_VAL) out_R <= 32'h80000000;
                else                      out_R <= sum_R[31:0];
            end

            w_ptr   <= w_ptr + 12'd1;
            r_ptr_a <= r_ptr_a + {4'b0, pitch_ratio, 8'b0};
        end
    end

endmodule