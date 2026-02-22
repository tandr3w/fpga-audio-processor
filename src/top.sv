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

logic audio_tick;
assign audio_tick = audio_in_available && audio_out_allowed;

logic signed [31:0] mute_out_L,  mute_out_R;
logic signed [31:0] dist_out_L,  dist_out_R;
logic signed [31:0] echo_out_L,  echo_out_R;
logic signed [31:0] pitch_out_L,  pitch_out_R;
logic signed [31:0] l_processed, r_processed;

mute_effect master_mute (
    .enable(SW[0]),      
    .in_L(audio_in_L),   .in_R(audio_in_R),
    .out_L(mute_out_L),  .out_R(mute_out_R)
);

distortion dist_effect (
    .CLOCK_50(CLOCK_50),
    .in_L(mute_out_L), .in_R(mute_out_R),
    .out_L(dist_out_L), .out_R(dist_out_R),
    .enable(SW[1]) 
);

// We now pass audio_tick into Echo and Vinyl
echo echo_effect (
    .CLOCK_50(CLOCK_50),
    .tick(audio_tick),
    .in_L(dist_out_L), .in_R(dist_out_R),
    .out_L(echo_out_L), .out_R(echo_out_R),
    .enable(SW[2]) 
);

// --- Hardcoded Perfect 5th Pitch Shifter ---
pitch_shifter perfect_5th_effect (
    .CLOCK_50(CLOCK_50),
    .tick(audio_tick),
    .enable(SW[3]),
    .pitch_ratio(16'h0180),  // 1.5x playback speed (Perfect 5th)
    .in_L(echo_out_L), 
    .in_R(echo_out_R),
    .out_L(pitch_out_L),     // Keeping wire names for compatibility
    .out_R(pitch_out_R)
);

vinyl vinyl_effect (
    .CLOCK_50(CLOCK_50),
    .in_L(pitch_out_L), .in_R(pitch_out_R),
    .out_L(l_processed), .out_R(r_processed),
    .enable(SW[4]) 
);

// Pass the handshakes out to the codec
always_ff @(posedge CLOCK_50) begin
    read_audio_in <= audio_tick;
    write_audio_out <= audio_tick;
    
    if (audio_tick) begin
        audio_out_L <= l_processed;
        audio_out_R <= r_processed;
    end
end

endmodule