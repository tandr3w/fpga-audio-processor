`timescale 1ns/100ps

module tb;

    // 1. Signal Declaration
    // Inputs to top
    logic CLOCK_50;
    logic [9:0] SW;
    logic audio_in_available;
    logic audio_out_allowed;
    logic signed [31:0] audio_in_L;
    logic signed [31:0] audio_in_R;

    // Outputs from top
    logic read_audio_in;
    logic write_audio_out;
    logic signed [31:0] audio_out_L;
    logic signed [31:0] audio_out_R;

    // 2. Instantiate the Unit Under Test (UUT)
    // Make sure port names match your top.sv exactly
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

    // 3. Clock Generation (50 MHz)
    // Period = 20ns (1s / 50,000,000)
    initial begin
        CLOCK_50 = 0;
        forever #10 CLOCK_50 = ~CLOCK_50;
    end

    // 4. Test Procedure
    initial begin
        // --- Setup for Waveform Viewing ---
        // These lines are critical for the GitHub Action to generate waves
        $dumpfile("sim_out/wave.vcd");
        $dumpvars(0, tb);

        // --- Initialize Inputs ---
        SW = 10'd0;                // All switches OFF
        audio_in_available = 0;
        audio_out_allowed = 0;
        audio_in_L = 0;
        audio_in_R = 0;

        // Wait for global reset/startup (100ns)
        #100;
        $display("--- Simulation Start ---");

        // ============================================================
        // TEST CASE 1: Normal Audio Passthrough (Switch 0 is OFF)
        // ============================================================
        $display("Test 1: Normal Passthrough (Input: 1000 -> Output: Should be 1000)");
        
        // 1. Set Audio Data
        audio_in_L = 32'd1000;
        audio_in_R = -32'd1000; // Test negative numbers too

        // 2. Raise Handshake Flags (Simulate Controller saying "Ready")
        @(posedge CLOCK_50);
        audio_in_available = 1;
        audio_out_allowed = 1;

        // 3. Wait for 'top' to respond with read/write signals
        wait(read_audio_in == 1 && write_audio_out == 1);
        
        // 4. Wait one clock cycle for the logic to latch the data
        @(posedge CLOCK_50);

        // 5. Check Results (Self-Checking)
        if (audio_out_L == 1000 && audio_out_R == -1000) 
            $display("  -> PASS: Audio passed through correctly.");
        else 
            $display("  -> FAIL: Expected 1000/-1000, got %d/%d", audio_out_L, audio_out_R);

        // 6. Reset Handshake (Simulate Controller finishing the transfer)
        audio_in_available = 0;
        audio_out_allowed = 0;
        #50; // Wait a bit between tests

        // ============================================================
        // TEST CASE 2: Mute Function (Switch 0 is ON)
        // ============================================================
        $display("Test 2: Mute Function (Input: 5000 -> Output: Should be 0)");

        // 1. Turn on Mute Switch
        SW[0] = 1; 

        // 2. Set Audio Data
        audio_in_L = 32'd5000;
        audio_in_R = 32'd5000;

        // 3. Raise Handshake Flags
        @(posedge CLOCK_50);
        audio_in_available = 1;
        audio_out_allowed = 1;

        // 4. Wait for logic to trigger
        wait(read_audio_in == 1);
        @(posedge CLOCK_50); // Clock edge to latch data

        // 5. Check Results
        if (audio_out_L == 0 && audio_out_R == 0)
            $display("  -> PASS: Audio muted correctly.");
        else
            $display("  -> FAIL: Expected 0, got %d/%d", audio_out_L, audio_out_R);

        // 6. Cleanup
        audio_in_available = 0;
        audio_out_allowed = 0;
        
        $display("--- Simulation End ---");
        $finish;
    end
    
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