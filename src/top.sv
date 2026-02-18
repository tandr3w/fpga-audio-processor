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

logic signed [31:0] mute_out_L,  mute_out_R;
logic signed [31:0] dist_out_L,  dist_out_R;
logic signed [31:0] l_processed, r_processed;

mute_effect master_mute (
    .enable(SW[0]),      // Use SW[0] as Master Mute
    .in_L(audio_in_L),   .in_R(audio_in_R),
    .out_L(mute_out_L),  .out_R(mute_out_R)
);

distortion dist_L (
    .CLOCK_50(CLOCK_50),
    .in_L(mute_out_L), .in_R(mute_out_R),
    .out_L(l_processed), .out_R(r_processed),
    .enable(SW[1]) // Switch 0 turns it ON
);

always_ff @(posedge CLOCK_50) begin

    read_audio_in <= audio_in_available && audio_out_allowed;
    write_audio_out <= audio_in_available && audio_out_allowed;

    // Effects to add:
    // - Vinyl crackle w/ true randomness
    // - eq
    // - distortion (easy)
    // - echo
    if (audio_in_available && audio_out_allowed) begin
        // Output processed audio channels
        audio_out_L <= l_processed;
        audio_out_R <= r_processed;
    end
end



endmodule