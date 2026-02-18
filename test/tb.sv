`timescale 1ns/100ps

module tb;

    // --- Signal Declarations ---
    logic CLOCK_50;
    logic [9:0] SW;
    logic audio_in_available;
    logic audio_out_allowed;
    logic signed [31:0] audio_in_L, audio_in_R;
    logic read_audio_in, write_audio_out;
    logic signed [31:0] audio_out_L, audio_out_R;

    // --- UUT Instantiation ---
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

    // --- Clock Generation ---
    initial begin
        CLOCK_50 = 0;
        forever #10 CLOCK_50 = ~CLOCK_50;
    end

    // --- MAIN TEST SEQUENCE ---
    initial begin
        $dumpfile("sim_out/wave.vcd");
        $dumpvars(0, tb);

        // 1. Initialize
        SW = 0;
        audio_in_available = 0;
        audio_out_allowed = 0;
        audio_in_L = 0;
        audio_in_R = 0;
        #100;

        $display("--- Simulation Start ---");

        // ============================================================
        // TEST 1: Passthrough
        // ============================================================
        $display("\nTest 1: Normal Passthrough");
        
        // Setup
        audio_in_L = 32'd1000;
        audio_in_R = -32'd1000;

        // Handshake
        @(posedge CLOCK_50);
        audio_in_available = 1;
        audio_out_allowed = 1;

        // Wait for Logic to respond
        wait(read_audio_in == 1);
        @(posedge CLOCK_50); // Latch Data

        // Verify
        if (audio_out_L == 1000 && audio_out_R == -1000) 
            $display("  -> PASS");
        else 
            $display("  -> FAIL: Got %d / %d", audio_out_L, audio_out_R);

        // Reset
        audio_in_available = 0;
        audio_out_allowed = 0;
        #50;

        // ============================================================
        // TEST 2: Mute
        // ============================================================
        $display("\nTest 2: Mute Function");

        // Setup
        SW[0] = 1; 
        audio_in_L = 32'd5000;
        audio_in_R = 32'd5000;

        // Handshake
        @(posedge CLOCK_50);
        audio_in_available = 1;
        audio_out_allowed = 1;

        // Wait
        wait(read_audio_in == 1);
        @(posedge CLOCK_50);

        // Verify
        if (audio_out_L == 0)
            $display("  -> PASS");
        else
            $display("  -> FAIL: Got %d", audio_out_L);

        // Reset
        SW[0] = 0; // Turn mute off for next test
        audio_in_available = 0;
        audio_out_allowed = 0;
        #50;

        // ============================================================
        // TEST 3: Pipeline Timing Check (The "Trap")
        // ============================================================
        $display("\nTest 3: Checking for Sequential Timing Accuracy");
        
        // Setup distinctive data
        audio_in_L = 32'hDEADBEEF;
        audio_in_R = 32'hDEADBEEF;

        // Handshake
        @(posedge CLOCK_50);
        audio_in_available = 1;
        audio_out_allowed = 1;

        // Wait for the WRITE signal
        wait(write_audio_out == 1);
        
        // Sample at the exact moment WRITE goes high
        // If your logic is sequential, data should be ready NOW.
        @(posedge CLOCK_50); 

        // Verify
        if (audio_out_L === 32'hDEADBEEF) begin
            $display("  -> PASS: Data valid exactly when Write asserted.");
        end else begin
            $display("  -> FAIL: Timing Mismatch!");
            $display("     Expected: DEADBEEF");
            $display("     Got:      %h", audio_out_L);
        end

        $display("\n--- Simulation End ---");
        $finish;
    end

endmodule