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


logic [15:0] selected_pitch;

always_comb begin
    // SW[6:4] acts as a 3-bit selector (0 to 7)
    case (SW[6:4])
        3'b000: selected_pitch = 16'h0080; // 0.50x : Octave Down
        3'b001: selected_pitch = 16'h00C0; // 0.75x : Perfect 4th Down
        3'b010: selected_pitch = 16'h0100; // 1.00x : Normal Pitch
        3'b011: selected_pitch = 16'h0140; // 1.25x : Major 3rd Up
        3'b100: selected_pitch = 16'h0155; // 1.33x : Perfect 4th Up
        3'b101: selected_pitch = 16'h0180; // 1.50x : Perfect 5th Up
        3'b110: selected_pitch = 16'h01C0; // 1.75x : Minor 7th Up
        3'b111: selected_pitch = 16'h0200; // 2.00x : Octave Up
        default: selected_pitch = 16'h0100; // Fallback to Normal
    endcase
end

pitch_shifter pitch_effect (
    .CLOCK_50(CLOCK_50),
    .tick(audio_tick),
    .enable(SW[3]),
    .pitch_ratio(selected_pitch),
    .in_L(echo_out_L), 
    .in_R(echo_out_R),
    .out_L(pitch_out_L),
    .out_R(pitch_out_R)
);

vinyl vinyl_effect (
    .CLOCK_50(CLOCK_50),
    .in_L(pitch_out_L), .in_R(pitch_out_R),
    .out_L(l_processed), .out_R(r_processed),
    .enable(SW[7]) 
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