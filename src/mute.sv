`timescale 1ns/100ps

module mute_effect (
    input  logic              enable, // The switch
    input  logic signed [31:0] in_L, in_R,
    output logic signed [31:0] out_L, out_R
);

    // Combinational Logic (Instant)
    always_comb begin
        if (enable) begin
            // Mute active: Silence the output
            out_L = 32'd0;
            out_R = 32'd0;
        end else begin
            // Mute inactive: Pass the signal through (Bypass)
            out_L = in_L;
            out_R = in_R;
        end
    end

endmodule