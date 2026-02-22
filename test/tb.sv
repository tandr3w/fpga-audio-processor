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

    // Test tracking
    integer test_count = 0;
    integer pass_count = 0;
    integer fail_count = 0;
    
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

    // --- Helper Task for Checking Results ---
    task check_audio_output(
        input signed [31:0] expected_L,
        input signed [31:0] expected_R,
        input string test_name
    );
        test_count = test_count + 1;
        if (audio_out_L === expected_L && audio_out_R === expected_R) begin
            $display("  -> PASS: %s", test_name);
            $display("LOG: %0t : INFO : tb : uut.audio_out_L : expected_value: %0d actual_value: %0d", $time, expected_L, audio_out_L);
            $display("LOG: %0t : INFO : tb : uut.audio_out_R : expected_value: %0d actual_value: %0d", $time, expected_R, audio_out_R);
            pass_count = pass_count + 1;
        end else begin
            $display("  -> FAIL: %s", test_name);
            $display("LOG: %0t : ERROR : tb : uut.audio_out_L : expected_value: %0d actual_value: %0d", $time, expected_L, audio_out_L);
            $display("LOG: %0t : ERROR : tb : uut.audio_out_R : expected_value: %0d actual_value: %0d", $time, expected_R, audio_out_R);
            fail_count = fail_count + 1;
        end
    endtask

    // --- Helper Task for Range Checking (for effects with tolerances) ---
    task check_audio_output_nonzero(
        input string test_name
    );
        test_count = test_count + 1;
        if (audio_out_L !== 32'sd0 || audio_out_R !== 32'sd0) begin
            $display("  -> PASS: %s (L=%0d, R=%0d)", test_name, audio_out_L, audio_out_R);
            $display("LOG: %0t : INFO : tb : uut.audio_out_L : expected_value: non-zero actual_value: %0d", $time, audio_out_L);
            $display("LOG: %0t : INFO : tb : uut.audio_out_R : expected_value: non-zero actual_value: %0d", $time, audio_out_R);
            pass_count = pass_count + 1;
        end else begin
            $display("  -> FAIL: %s", test_name);
            $display("LOG: %0t : ERROR : tb : uut.audio_out_L : expected_value: non-zero actual_value: %0d", $time, audio_out_L);
            $display("LOG: %0t : ERROR : tb : uut.audio_out_R : expected_value: non-zero actual_value: %0d", $time, audio_out_R);
            fail_count = fail_count + 1;
        end
    endtask

    // --- Helper Task to Apply Audio Sample ---
    task apply_audio_sample(
        input signed [31:0] sample_L,
        input signed [31:0] sample_R,
        input integer wait_cycles
    );
        audio_in_L = sample_L;
        audio_in_R = sample_R;
        audio_in_available = 1;
        audio_out_allowed = 1;
        
        repeat(wait_cycles) @(posedge CLOCK_50);
        
        audio_in_available = 0;
        audio_out_allowed = 0;
    endtask

    // --- MAIN TEST SEQUENCE ---
    initial begin
        $dumpfile("sim_out/wave.vcd");
        $dumpvars(0, tb);
        $display("TEST START");
        

        // Initialize all signals
        SW = 10'b0;
        audio_in_available = 0;
        audio_out_allowed = 0;
        audio_in_L = 0;
        audio_in_R = 0;
        
        // Wait for initial settling
        repeat(10) @(posedge CLOCK_50);

        $display("\n========================================");
        $display("=== Audio Effects Processor Test Suite ===");
        $display("========================================\n");

        // ============================================================
        // TEST 1: Basic Passthrough (All Effects Disabled)
        // ============================================================
        $display("\n[TEST 1] Basic Passthrough - All Effects OFF");
        SW = 10'b0000000000; // All effects off
        
        apply_audio_sample(32'sd1000, -32'sd1000, 3);
        @(posedge CLOCK_50);
        check_audio_output(32'sd1000, -32'sd1000, "Passthrough positive/negative");

        apply_audio_sample(32'h00010000, 32'h00020000, 3);
        @(posedge CLOCK_50);
        check_audio_output(32'h00010000, 32'h00020000, "Passthrough hex values");

        repeat(5) @(posedge CLOCK_50);

        // ============================================================
        // TEST 2: Master Mute Function (SW[0])
        // ============================================================
        $display("\n[TEST 2] Master Mute Function");
        SW[0] = 1; // Enable master mute
        
        apply_audio_sample(32'sd5000, -32'sd3000, 3);
        @(posedge CLOCK_50);
        check_audio_output(32'sd0, 32'sd0, "Mute blocks all audio");

        apply_audio_sample(32'h7FFFFFFF, 32'h80000000, 3);
        @(posedge CLOCK_50);
        check_audio_output(32'sd0, 32'sd0, "Mute blocks max values");

        SW[0] = 0; // Disable mute
        repeat(5) @(posedge CLOCK_50);

        // ============================================================
        // TEST 3: Distortion Effect (SW[1])
        // ============================================================
        $display("\n[TEST 3] Distortion Effect");
        SW = 10'b0000000010; // Only distortion enabled

        // Large signal - should be compressed
        apply_audio_sample(32'sd50000000, 32'sd50000000, 3);
        @(posedge CLOCK_50);
        test_count = test_count + 1;
        if (audio_out_L < 32'sd50000000 && audio_out_L > 32'sd0) begin
            $display("  -> PASS: Distortion compresses large signals (out=%0d)", audio_out_L);
            $display("LOG: %0t : INFO : tb : uut.audio_out_L : expected_value: <50000000 actual_value: %0d", $time, audio_out_L);
            pass_count = pass_count + 1;
        end else begin
            $display("  -> FAIL: Distortion should compress signal");
            $display("LOG: %0t : ERROR : tb : uut.audio_out_L : expected_value: <50000000 actual_value: %0d", $time, audio_out_L);
            fail_count = fail_count + 1;
        end

        // Negative signal
        apply_audio_sample(-32'sd50000000, -32'sd50000000, 3);
        @(posedge CLOCK_50);
        test_count = test_count + 1;
        if (audio_out_L > -32'sd50000000 && audio_out_L < 32'sd0) begin
            $display("  -> PASS: Distortion handles negative signals (out=%0d)", audio_out_L);
            $display("LOG: %0t : INFO : tb : uut.audio_out_L : expected_value: >-50000000 actual_value: %0d", $time, audio_out_L);
            pass_count = pass_count + 1;
        end else begin
            $display("  -> FAIL: Distortion should compress negative signal");
            $display("LOG: %0t : ERROR : tb : uut.audio_out_L : expected_value: >-50000000 actual_value: %0d", $time, audio_out_L);
            fail_count = fail_count + 1;
        end

        SW = 10'b0; // Turn off distortion
        repeat(5) @(posedge CLOCK_50);

        // ============================================================
        // TEST 4: Echo Effect (SW[2])
        // ============================================================
        $display("\n[TEST 4] Echo Effect");
        SW = 10'b0000001000; // Only echo enabled

        // Apply a signal and check that echo processes it
        apply_audio_sample(32'sd10000000, 32'sd10000000, 5);
        repeat(10) @(posedge CLOCK_50);
        
        test_count = test_count + 1;
        // Echo should modify the output (not exact passthrough due to comb filters)
        if (audio_out_L !== 32'sd0 && audio_out_R !== 32'sd0) begin
            $display("  -> PASS: Echo processes audio (L=%0d, R=%0d)", audio_out_L, audio_out_R);
            $display("LOG: %0t : INFO : tb : uut.audio_out_L : expected_value: non-zero actual_value: %0d", $time, audio_out_L);
            pass_count = pass_count + 1;
        end else begin
            $display("  -> FAIL: Echo should produce non-zero output");
            $display("LOG: %0t : ERROR : tb : uut.audio_out_L : expected_value: non-zero actual_value: %0d", $time, audio_out_L);
            fail_count = fail_count + 1;
        end

        SW = 10'b0; // Turn off echo
        repeat(10) @(posedge CLOCK_50);

        // ============================================================
        // TEST 5: Vinyl Effect (SW[3])
        // ============================================================
        $display("\n[TEST 5] Vinyl Effect");
        SW = 10'b0100000000; // Only vinyl enabled
        
        // Let vinyl's ring oscillator and noise generator warm up
        repeat(200) @(posedge CLOCK_50);
        
        // Clean input signal
        apply_audio_sample(32'sd5000000, 32'sd5000000, 5);
        repeat(10) @(posedge CLOCK_50);
        
        test_count = test_count + 1;
        // Vinyl should add noise/variance, so output shouldn't exactly match input
        if (audio_out_L !== 32'sd5000000 || audio_out_R !== 32'sd5000000) begin
            $display("  -> PASS: Vinyl adds noise/crackle (L=%0d, R=%0d)", audio_out_L, audio_out_R);
            $display("LOG: %0t : INFO : tb : uut.audio_out_L : expected_value: !=5000000 actual_value: %0d", $time, audio_out_L);
            pass_count = pass_count + 1;
        end else begin
            $display("  -> FAIL: Vinyl should modify signal");
            $display("LOG: %0t : ERROR : tb : uut.audio_out_L : expected_value: !=5000000 actual_value: %0d", $time, audio_out_L);
            fail_count = fail_count + 1;
        end

        SW = 10'b0; // Turn off vinyl
        repeat(10) @(posedge CLOCK_50);

        // ============================================================
        // TEST 6: Combined Effects
        // ============================================================
        $display("\n[TEST 6] Combined Effects");
        
        // Distortion + Echo
        SW = 10'b0000001110;
        apply_audio_sample(32'sd20000000, 32'sd20000000, 5);
        repeat(10) @(posedge CLOCK_50);
        check_audio_output_nonzero("Distortion + Echo combination");
        SW = 10'b0;
        repeat(10) @(posedge CLOCK_50);

        // All effects enabled (except mute)
        SW = 10'b1111111110;
        repeat(100) @(posedge CLOCK_50); // Let effects stabilize
        apply_audio_sample(32'sd15000000, 32'sd15000000, 5);
        repeat(10) @(posedge CLOCK_50);
        check_audio_output_nonzero("All effects enabled");
        SW = 10'b0;
        repeat(10) @(posedge CLOCK_50);

        // ============================================================
        // TEST 8: Handshake Protocol
        // ============================================================
        $display("\n[TEST 7] Handshake Protocol");
        SW = 10'b0;
        
        // Both signals high - should activate
        audio_in_L = 32'sd12345;
        audio_in_R = 32'sd67890;
        audio_in_available = 1;
        audio_out_allowed = 1;
        @(posedge CLOCK_50);
        @(posedge CLOCK_50);
        
        test_count = test_count + 1;
        if (read_audio_in === 1 && write_audio_out === 1) begin
            $display("  -> PASS: Both handshake signals activate");
            $display("LOG: %0t : INFO : tb : uut.read_audio_in : expected_value: 1 actual_value: %0d", $time, read_audio_in);
            pass_count = pass_count + 1;
        end else begin
            $display("  -> FAIL: Handshake should activate");
            $display("LOG: %0t : ERROR : tb : uut.read_audio_in : expected_value: 1 actual_value: %0d", $time, read_audio_in);
            fail_count = fail_count + 1;
        end

        // Only audio_in_available
        audio_in_available = 1;
        audio_out_allowed = 0;
        @(posedge CLOCK_50);
        @(posedge CLOCK_50);
        
        test_count = test_count + 1;
        if (read_audio_in === 0 && write_audio_out === 0) begin
            $display("  -> PASS: Handshake requires both signals");
            $display("LOG: %0t : INFO : tb : uut.read_audio_in : expected_value: 0 actual_value: %0d", $time, read_audio_in);
            pass_count = pass_count + 1;
        end else begin
            $display("  -> FAIL: Handshake should not activate");
            $display("LOG: %0t : ERROR : tb : uut.read_audio_in : expected_value: 0 actual_value: %0d", $time, read_audio_in);
            fail_count = fail_count + 1;
        end

        audio_in_available = 0;
        audio_out_allowed = 0;
        repeat(5) @(posedge CLOCK_50);

        // ============================================================
        // TEST 9: Boundary Values
        // ============================================================
        $display("\n[TEST 8] Boundary Values");
        SW = 10'b0; // All effects off for clean test
        
        // Maximum positive
        apply_audio_sample(32'h7FFFFFFF, 32'h7FFFFFFF, 3);
        @(posedge CLOCK_50);
        check_audio_output(32'h7FFFFFFF, 32'h7FFFFFFF, "Max positive passthrough");

        // Maximum negative
        apply_audio_sample(32'h80000000, 32'h80000000, 3);
        @(posedge CLOCK_50);
        check_audio_output(32'h80000000, 32'h80000000, "Max negative passthrough");

        // Zero
        apply_audio_sample(32'sd0, 32'sd0, 3);
        @(posedge CLOCK_50);
        check_audio_output(32'sd0, 32'sd0, "Zero passthrough");

        repeat(5) @(posedge CLOCK_50);

        // ============================================================
        // TEST 10: Switch Stability
        // ============================================================
        $display("\n[TEST 9] Switch Toggle Stability");
        
        // Rapid effect toggling
        SW = 10'b0000000010; // Distortion on
        apply_audio_sample(32'sd8000000, 32'sd8000000, 2);
        @(posedge CLOCK_50);
        @(posedge CLOCK_50);
        @(posedge CLOCK_50);
        @(posedge CLOCK_50);
        @(posedge CLOCK_50);
        
        SW = 10'b0000000000; // All off
        @(posedge CLOCK_50);
        @(posedge CLOCK_50);

        apply_audio_sample(32'sd8000000, 32'sd8000000, 2);
        @(posedge CLOCK_50);
        check_audio_output(32'sd8000000, 32'sd8000000, "Effect toggle stability");

        repeat(5) @(posedge CLOCK_50);

        // ============================================================
        // TEST 11: Asymmetric Channel Processing
        // ============================================================
        $display("\n[TEST 10] Asymmetric Channel Processing");
        SW = 10'b0;
        
        apply_audio_sample(32'sd10000000, -32'sd10000000, 3);
        @(posedge CLOCK_50);
        check_audio_output(32'sd10000000, -32'sd10000000, "Independent channel processing");

        apply_audio_sample(32'h7FFFFFFF, 32'h80000000, 3);
        @(posedge CLOCK_50);
        check_audio_output(32'h7FFFFFFF, 32'h80000000, "Max positive/negative split");

        repeat(5) @(posedge CLOCK_50);

        // ============================================================
        // TEST 12: Sequential Processing
        // ============================================================
        $display("\n[TEST 11] Sequential Sample Processing");
        SW = 10'b0;
        
        audio_in_available = 1;
        audio_out_allowed = 1;
        
        audio_in_L = 32'sd1111;
        audio_in_R = 32'sd2222;
        repeat(3) @(posedge CLOCK_50);
        check_audio_output(32'sd1111, 32'sd2222, "Sequential sample 1");
        
        audio_in_L = 32'sd3333;
        audio_in_R = 32'sd4444;
        repeat(3) @(posedge CLOCK_50);
        check_audio_output(32'sd3333, 32'sd4444, "Sequential sample 2");
        
        audio_in_L = 32'sd5555;
        audio_in_R = 32'sd6666;
        repeat(3) @(posedge CLOCK_50);
        check_audio_output(32'sd5555, 32'sd6666, "Sequential sample 3");
        
        audio_in_available = 0;
        audio_out_allowed = 0;
        repeat(5) @(posedge CLOCK_50);

        // ============================================================
        // TEST 13: Unused Switches
        // ============================================================
        $display("\n[TEST 12] Unused Switch Verification");
        SW = 10'b1000000000; // Upper switches (unused)
        
        apply_audio_sample(32'sd7654321, 32'sd8765432, 3);
        @(posedge CLOCK_50);
        check_audio_output(32'sd7654321, 32'sd8765432, "Unused switches don't interfere");

        SW = 10'b0;
        repeat(5) @(posedge CLOCK_50);

        // ============================================================
        // Test Summary
        // ============================================================
        $display("\n========================================");
        $display("===        Test Summary              ===");
        $display("========================================");
        $display("Total Tests:  %0d", test_count);
        $display("Passed:       %0d", pass_count);
        $display("Failed:       %0d", fail_count);
        $display("Pass Rate:    %0d%%", (pass_count * 100) / test_count);
        $display("========================================\n");
        
        if (fail_count == 0) begin
            $display("TEST PASSED");
        end else begin
            $display("TEST FAILED");
        end

        $finish;
    end

endmodule
