`timescale 1ns/100ps

module vinyl (
    input  logic              CLOCK_50,
    input  logic              enable,
    input  logic signed [31:0] in_L,
    input  logic signed [31:0] in_R,
    output logic signed [31:0] out_L,
    output logic signed [31:0] out_R
);

    logic ro_bit;
    ring_oscillator ro_inst (
        .enable(enable),
        .CLOCK_50(CLOCK_50), 
        .rand_bit(ro_bit)
    );

    // Clock divider
    logic [10:0] timer_48k = 0;
    logic pulse_48k;
    always_ff @(posedge CLOCK_50) begin
        if (timer_48k >= 1041) begin timer_48k <= 0; pulse_48k <= 1'b1; end
        else                   begin timer_48k <= timer_48k + 1; pulse_48k <= 1'b0; end
    end

    logic [31:0] noise_reg = 32'h0;
    logic        pop_trigger_sticky = 1'b0;
    logic signed [31:0] pop_val = 32'sh0;
    
    always_ff @(posedge CLOCK_50) begin
        if (!enable) begin
            noise_reg <= 32'h0;
            pop_trigger_sticky <= 1'b0;
            pop_val <= 32'sh0;
        end else begin
            // Get a random 31 bit integer
            noise_reg <= {noise_reg[30:0], ro_bit};

            // Occasionally create loud pops 
            if ($signed(noise_reg) > 32'sd2147400000) begin
                pop_trigger_sticky <= 1'b1;
            end

            // Decay pops at 48kHz to ensure they appear in a sample
            if (pulse_48k) begin
                if (pop_trigger_sticky) begin
                    pop_val <= noise_reg >>> 3; 
                    pop_trigger_sticky <= 1'b0; 
                end else begin
                    pop_val <= pop_val - (pop_val >>> 8);
                end
            end
        end
    end

    logic signed [32:0] final_L, final_R;
    localparam signed [32:0] MAX_VAL = 33'sd2147483647;
    localparam signed [32:0] MIN_VAL = -33'sd2147483648;

    always_ff @(posedge CLOCK_50) begin
        if (!enable) begin
            out_L <= in_L; out_R <= in_R;
        end else begin
            final_L = 33'(in_L) + (33'($signed(noise_reg)) >>> 6) + 33'(pop_val);
            final_R = 33'(in_R) + (33'($signed(noise_reg)) >>> 6) + 33'(pop_val);

            // Prevent clipping
            if (final_L > MAX_VAL)      out_L <= 32'h7FFFFFFF;
            else if (final_L < MIN_VAL) out_L <= 32'h80000000;
            else                        out_L <= final_L[31:0];

            if (final_R > MAX_VAL)      out_R <= 32'h7FFFFFFF;
            else if (final_R < MIN_VAL) out_R <= 32'h80000000;
            else                        out_R <= final_R[31:0];
        end
    end

endmodule