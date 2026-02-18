`timescale 1ns/100ps

module top (
    input  logic       CLOCK_50,
    input  logic [9:0] SW,
    input  logic       audio_in_available,
    input  logic       audio_out_allowed, 
    output logic       read_audio_in,   
    output logic       write_audio_out, 

    input  logic signed [31:0] audio_in_L,
    input  logic signed [31:0] audio_in_R,
    output logic signed [31:0] audio_out_L,
    output logic signed [31:0] audio_out_R
);

logic signed [31:0] l_processed, r_processed;

always_ff @(posedge CLOCK_50) begin

    read_audio_in <= audio_in_available && audio_out_allowed;
    write_audio_out <= audio_in_available && audio_out_allowed;

    if (audio_in_available && audio_out_allowed) begin
        // Get audio input
        l_processed = audio_in_L;
        r_processed = audio_in_R;

        // Apply effects based on switches
        if (SW[0]) begin
            l_processed = 0;
            r_processed = 0;
        end

        // Output processed audio channels
        audio_out_L <= l_processed;
        audio_out_R <= r_processed;
    end
end



endmodule