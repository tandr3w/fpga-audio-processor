`timescale 1ns/100ps

module data_valadity;

    // Signals
    logic CLOCK_50;
    logic [9:0] SW;
    logic audio_in_available;
    logic audio_out_allowed;
    logic read_audio_in;
    logic write_audio_out;
    logic signed [31:0] audio_in_L, audio_in_R;
    logic signed [31:0] audio_out_L, audio_out_R;

    top uut (
        .CLOCK_50(CLOCK_50),
        .SW(SW),
        .audio_in_available(audio_in_available),
        .audio_out_allowed(audio_out_allowed),
        .read_audio_in(read_audio_in),
        .write_audio_out(write_audio_out),
        .audio_in_L(audio_in_L),
        .audio_in_R(audio_in_R),
        .audio_out_L(audio_out_L),
        .audio_out_R(audio_out_R)
    );

    // 50MHz Clock
    initial CLOCK_50 = 0;
    always #10 CLOCK_50 = ~CLOCK_50;

    initial begin
        $dumpfile("sim_out/wave.vcd");
        $dumpvars(0, data_valadity);

        // Initialize
        SW = 0;
        audio_in_available = 0;
        audio_out_allowed = 0;
        audio_in_L = 0;
        audio_in_R = 0;
        #100;

        $display("TEST: Checking for Timing Mismatch...");
        
        // 1. Setup Input Data
        audio_in_L = 32'hDEADBEEF; // A distinctive number
        audio_in_R = 32'hDEADBEEF;

        // 2. Trigger the Handshake
        // We simulate the driver saying "I'm ready"
        @(posedge CLOCK_50);
        audio_in_available = 1;
        audio_out_allowed = 1;

        // 3. Wait for YOUR module to say "Write Now"
        wait(write_audio_out == 1);
        
        // 4. Sample the data at the EXACT moment you requested the write.
        // This is when the real Audio Controller would grab the data.
        @(posedge CLOCK_50); 

        // 5. Verify
        if (audio_out_L !== 32'hDEADBEEF) begin
            $display("!!! FAIL !!!");
            $display("Timing Error Detected:");
            $display("You asserted 'write_audio_out' (I grabbed data).");
            $display("EXPECTED: %h", 32'hDEADBEEF);
            $display("ACTUAL:   %h (Likely 0 or X)", audio_out_L);
            $display("Reason: Your 'write' signal arrived 1 cycle BEFORE your data.");
        end else begin
            $display("PASS: Data was ready.");
        end

        $finish;
    end
endmodule