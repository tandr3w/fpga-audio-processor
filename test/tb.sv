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
    
    // Helper variables
    logic signed [31:0] prev_out_L, prev_out_R;

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

    // --- MAIN TEST SEQUENCE ---
    initial begin
        $dumpfile("sim_out/wave.vcd");
        $dumpvars(0, tb);
        $display("TEST START");

        // Initialize
        SW = 0;
        audio_in_available = 0;
        audio_out_allowed = 0;
        audio_in_L = 0;
        audio_in_R = 0;
        #100;

        $display("\n=== Audio Processing Module Test Suite ===\n");

        // ============================================================
        // TEST 1: Normal Passthrough
        // ============================================================
        $display("\nTest 1: Normal Passthrough");
        
        audio_in_L = 32'd1000;
        audio_in_R = -32'd1000;

        @(posedge CLOCK_50);
        audio_in_available = 1;
        audio_out_allowed = 1;

        wait(read_audio_in == 1);
        @(posedge CLOCK_50);

        check_audio_output(32'd1000, -32'd1000, "Basic passthrough");

        audio_in_available = 0;
        audio_out_allowed = 0;
        #50;

        // ============================================================
        // TEST 2: Mute Function
        // ============================================================
        $display("\nTest 2: Mute Function");

        SW[0] = 1; 
        audio_in_L = 32'd5000;
        audio_in_R = 32'd5000;

        @(posedge CLOCK_50);
        audio_in_available = 1;
        audio_out_allowed = 1;

        wait(read_audio_in == 1);
        @(posedge CLOCK_50);

        check_audio_output(32'd0, 32'd0, "Mute both channels");

        SW[0] = 0;
        audio_in_available = 0;
        audio_out_allowed = 0;
        #50;

        // ============================================================
        // TEST 3: Pipeline Timing Check
        // ============================================================
        $display("\nTest 3: Sequential Timing Accuracy");
        
        audio_in_L = 32'hDEADBEEF;
        audio_in_R = 32'hDEADBEEF;

        @(posedge CLOCK_50);
        audio_in_available = 1;
        audio_out_allowed = 1;

        wait(write_audio_out == 1);
        @(posedge CLOCK_50);

        check_audio_output(32'hDEADBEEF, 32'hDEADBEEF, "Timing check");

        audio_in_available = 0;
        audio_out_allowed = 0;
        #50;

        // ============================================================
        // TEST 4: Maximum Positive Values
        // ============================================================
        $display("\nTest 4: Maximum Positive Values");
        
        audio_in_L = 32'h7FFFFFFF;  // Max positive signed 32-bit
        audio_in_R = 32'h7FFFFFFF;

        @(posedge CLOCK_50);
        audio_in_available = 1;
        audio_out_allowed = 1;

        wait(read_audio_in == 1);
        @(posedge CLOCK_50);

        check_audio_output(32'h7FFFFFFF, 32'h7FFFFFFF, "Max positive values");

        audio_in_available = 0;
        audio_out_allowed = 0;
        #50;

        // ============================================================
        // TEST 5: Maximum Negative Values
        // ============================================================
        $display("\nTest 5: Maximum Negative Values");
        
        audio_in_L = 32'h80000000;  // Max negative signed 32-bit
        audio_in_R = 32'h80000000;

        @(posedge CLOCK_50);
        audio_in_available = 1;
        audio_out_allowed = 1;

        wait(read_audio_in == 1);
        @(posedge CLOCK_50);

        check_audio_output(32'h80000000, 32'h80000000, "Max negative values");

        audio_in_available = 0;
        audio_out_allowed = 0;
        #50;

        // ============================================================
        // TEST 6: Mute with Maximum Values
        // ============================================================
        $display("\nTest 6: Mute with Maximum Values");
        
        SW[0] = 1;
        audio_in_L = 32'h7FFFFFFF;
        audio_in_R = 32'h80000000;

        @(posedge CLOCK_50);
        audio_in_available = 1;
        audio_out_allowed = 1;

        wait(read_audio_in == 1);
        @(posedge CLOCK_50);

        check_audio_output(32'd0, 32'd0, "Mute overrides max values");

        SW[0] = 0;
        audio_in_available = 0;
        audio_out_allowed = 0;
        #50;

        // ============================================================
        // TEST 7: Only audio_in_available High
        // ============================================================
        $display("\nTest 7: Incomplete Handshake - Only audio_in_available");
        
        audio_in_L = 32'd12345;
        audio_in_R = 32'd67890;
        
        prev_out_L = audio_out_L;
        prev_out_R = audio_out_R;

        @(posedge CLOCK_50);
        audio_in_available = 1;
        audio_out_allowed = 0;  // Not allowed

        @(posedge CLOCK_50);
        @(posedge CLOCK_50);

        test_count = test_count + 1;
        if (read_audio_in === 0 && write_audio_out === 0) begin
            $display("  -> PASS: Handshake signals remain low");
            $display("LOG: %0t : INFO : tb : uut.read_audio_in : expected_value: 0 actual_value: %0d", $time, read_audio_in);
            pass_count = pass_count + 1;
        end else begin
            $display("  -> FAIL: Handshake should not activate");
            $display("LOG: %0t : ERROR : tb : uut.read_audio_in : expected_value: 0 actual_value: %0d", $time, read_audio_in);
            fail_count = fail_count + 1;
        end

        audio_in_available = 0;
        #50;

        // ============================================================
        // TEST 8: Only audio_out_allowed High
        // ============================================================
        $display("\nTest 8: Incomplete Handshake - Only audio_out_allowed");
        
        audio_in_L = 32'd99999;
        audio_in_R = 32'd88888;

        @(posedge CLOCK_50);
        audio_in_available = 0;  // Not available
        audio_out_allowed = 1;

        @(posedge CLOCK_50);
        @(posedge CLOCK_50);

        test_count = test_count + 1;
        if (read_audio_in === 0 && write_audio_out === 0) begin
            $display("  -> PASS: Handshake signals remain low");
            $display("LOG: %0t : INFO : tb : uut.write_audio_out : expected_value: 0 actual_value: %0d", $time, write_audio_out);
            pass_count = pass_count + 1;
        end else begin
            $display("  -> FAIL: Handshake should not activate");
            $display("LOG: %0t : ERROR : tb : uut.write_audio_out : expected_value: 0 actual_value: %0d", $time, write_audio_out);
            fail_count = fail_count + 1;
        end

        audio_out_allowed = 0;
        #50;

        // ============================================================
        // TEST 9: Sequential Audio Samples
        // ============================================================
        $display("\nTest 9: Sequential Audio Samples");
        
        // Sample 1
        audio_in_L = 32'd100;
        audio_in_R = 32'd200;
        @(posedge CLOCK_50);
        audio_in_available = 1;
        audio_out_allowed = 1;
        wait(read_audio_in == 1);
        @(posedge CLOCK_50);
        check_audio_output(32'd100, 32'd200, "Sequential sample 1");
        
        // Sample 2 - immediately following
        audio_in_L = 32'd300;
        audio_in_R = 32'd400;
        @(posedge CLOCK_50);
        check_audio_output(32'd300, 32'd400, "Sequential sample 2");
        
        // Sample 3
        audio_in_L = -32'd500;
        audio_in_R = -32'd600;
        @(posedge CLOCK_50);
        check_audio_output(-32'd500, -32'd600, "Sequential sample 3");

        audio_in_available = 0;
        audio_out_allowed = 0;
        #50;

        // ============================================================
        // TEST 10: Unused Switches Don't Interfere
        // ============================================================
        $display("\nTest 10: Unused Switches Verification");
        
        SW = 10'b1111111110;  // All switches except SW[0]
        audio_in_L = 32'd7777;
        audio_in_R = 32'd8888;

        @(posedge CLOCK_50);
        audio_in_available = 1;
        audio_out_allowed = 1;

        wait(read_audio_in == 1);
        @(posedge CLOCK_50);

        check_audio_output(32'd7777, 32'd8888, "Unused switches don't affect passthrough");

        SW = 0;
        audio_in_available = 0;
        audio_out_allowed = 0;
        #50;

        // ============================================================
        // TEST 11: Asymmetric Channel Values
        // ============================================================
        $display("\nTest 11: Asymmetric Channel Values");
        
        audio_in_L = 32'h7FFFFFFF;
        audio_in_R = 32'h80000000;

        @(posedge CLOCK_50);
        audio_in_available = 1;
        audio_out_allowed = 1;

        wait(read_audio_in == 1);
        @(posedge CLOCK_50);

        check_audio_output(32'h7FFFFFFF, 32'h80000000, "Max positive L, max negative R");

        audio_in_available = 0;
        audio_out_allowed = 0;
        #50;

        // ============================================================
        // TEST 12: Zero Audio Values
        // ============================================================
        $display("\nTest 12: Zero Audio Values");
        
        audio_in_L = 32'd0;
        audio_in_R = 32'd0;

        @(posedge CLOCK_50);
        audio_in_available = 1;
        audio_out_allowed = 1;

        wait(read_audio_in == 1);
        @(posedge CLOCK_50);

        check_audio_output(32'd0, 32'd0, "Zero values passthrough");

        audio_in_available = 0;
        audio_out_allowed = 0;
        #50;

        // ============================================================
        // TEST 13: Rapid Enable/Disable
        // ============================================================
        $display("\nTest 13: Rapid Handshake Toggling");
        
        audio_in_L = 32'd4444;
        audio_in_R = 32'd5555;

        // Quick enable
        @(posedge CLOCK_50);
        audio_in_available = 1;
        audio_out_allowed = 1;
        
        // One cycle only
        @(posedge CLOCK_50);
        audio_in_available = 0;
        audio_out_allowed = 0;
        
        @(posedge CLOCK_50);
        
        test_count = test_count + 1;
        if (read_audio_in === 0 && write_audio_out === 0) begin
            $display("  -> PASS: Signals deasserted after handshake removed");
            $display("LOG: %0t : INFO : tb : uut.read_audio_in : expected_value: 0 actual_value: %0d", $time, read_audio_in);
            pass_count = pass_count + 1;
        end else begin
            $display("  -> FAIL: Signals should follow handshake");
            $display("LOG: %0t : ERROR : tb : uut.read_audio_in : expected_value: 0 actual_value: %0d", $time, read_audio_in);
            fail_count = fail_count + 1;
        end
        
        #50;

        // ============================================================
        // TEST 14: Mute Toggle During Operation
        // ============================================================
        $display("\nTest 14: Mute Toggle During Operation");
        
        // Start with audio
        SW[0] = 0;
        audio_in_L = 32'd2000;
        audio_in_R = 32'd3000;

        @(posedge CLOCK_50);
        audio_in_available = 1;
        audio_out_allowed = 1;
        wait(read_audio_in == 1);
        @(posedge CLOCK_50);
        check_audio_output(32'd2000, 32'd3000, "Before mute toggle");

        // Toggle mute on
        SW[0] = 1;
        audio_in_L = 32'd2000;
        audio_in_R = 32'd3000;
        @(posedge CLOCK_50);
        check_audio_output(32'd0, 32'd0, "After mute enabled");

        // Toggle mute off
        SW[0] = 0;
        audio_in_L = 32'd2000;
        audio_in_R = 32'd3000;
        @(posedge CLOCK_50);
        check_audio_output(32'd2000, 32'd3000, "After mute disabled");

        audio_in_available = 0;
        audio_out_allowed = 0;
        SW[0] = 0;
        #50;

        // ============================================================
        // Test Summary
        // ============================================================
        $display("\n=== Test Summary ===");
        $display("Total Tests: %0d", test_count);
        $display("Passed:      %0d", pass_count);
        $display("Failed:      %0d", fail_count);
        
        if (fail_count == 0) begin
            $display("\nTEST PASSED");
        end else begin
            $display("\nTEST FAILED");
        end

        $finish;
    end

    // Waveform dump
    initial begin
        $dumpfile("dumpfile.fst");
        $dumpvars(0);
    end

endmodule
