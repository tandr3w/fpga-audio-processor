// Reads in a text file generated from the audio_converter script (representing a wav) and outputs a text file after applying effects.

`timescale 1ns/100ps

module quartus_tb;

    // --- Inputs/Outputs ---
    logic CLOCK_50 = 0;
    logic [9:0] SW = 0;
    logic audio_in_available = 0;
    logic audio_out_allowed = 0;
    logic signed [31:0] audio_in_L = 0, audio_in_R = 0;
    logic signed [31:0] audio_out_L, audio_out_R;
    logic read_ready, write_ready;

    // --- File Handles ---
    integer f_in, f_out;
    integer scan_status;
    logic [31:0] tmp_L, tmp_R;

    // --- Instantiate YOUR Top Module ---
    top uut (
        .CLOCK_50(CLOCK_50),
        .SW(SW),
        .audio_in_available(audio_in_available),
        .audio_out_allowed(audio_out_allowed),
        .read_audio_in(read_ready),
        .write_audio_out(write_ready),
        .audio_in_L(audio_in_L), .audio_in_R(audio_in_R),
        .audio_out_L(audio_out_L), .audio_out_R(audio_out_R)
    );

    // --- Clock Gen ---
    always #10 CLOCK_50 = ~CLOCK_50;

    // --- Main Process ---
    initial begin
        // 1. Open Files
        // Note: ModelSim runs inside the "simulation/modelsim" folder usually,
        // so we use "../" to find the files in the project root.
        f_in  = $fopen("scripts/input.txt", "r");
        f_out = $fopen("scripts/output.txt", "w");

        if (f_in == 0) begin
            $display("ERROR: Could not find input.txt");
            $finish;
        end

        // 2. Setup Switches (Turn on Distortion/Echo/etc here!)
        SW[1] = 1;
        SW[2] = 1;
        SW[3] = 1;
        SW[4] = 1;
        SW[5] = 1;
        SW[6] = 1;
        SW[7] = 1;
        SW[8] = 1;
        
        // 3. Reset
        #100;
        
        // 4. Process Loop
        while (!$feof(f_in)) begin
            // Read one line from file (Hex L, Hex R)
            scan_status = $fscanf(f_in, "%h %h\n", tmp_L, tmp_R);
            
            if (scan_status == 2) begin
                // Push into FPGA
                audio_in_L = tmp_L;
                audio_in_R = tmp_R;
                
                // Handshake: "Data is ready!"
                @(posedge CLOCK_50);
                audio_in_available = 1;
                audio_out_allowed = 1;

                // Wait for FPGA to ack
                wait(read_ready);
                @(posedge CLOCK_50); //     Data latched

                // Capture Output
                // IMPORTANT: We write audio_out_L/R to the file
                $fwrite(f_out, "%h %h\n", audio_out_L, audio_out_R);

                // Reset Handshake for next sample
                audio_in_available = 0;
                audio_out_allowed = 0;
                #100; // Wait a bit (simulate 48kHz gap)
            end
        end

        // 5. Cleanup
        $fclose(f_in);
        $fclose(f_out);
        $display("Simulation Finished. Data written to output.txt");
        $finish;
    end

endmodule