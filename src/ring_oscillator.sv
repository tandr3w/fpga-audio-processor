`timescale 1ns/100ps

module ring_oscillator #(parameter STAGES = 13) (
    input  logic enable,
    input  logic CLOCK_50, 
    output logic rand_bit
);

// EXPLICIT CHANGE: Swapped to the native Quartus macro!
`ifndef ALTERA_RESERVED_QIS 
    // --- SIMULATION PATH ---
    logic [31:0] temp_rand;
    always_ff @(posedge CLOCK_50) begin
        if (enable) begin
            // synthesis translate_off
            temp_rand = $urandom;
            // synthesis translate_on
            rand_bit <= temp_rand[0]; 
        end else begin
            rand_bit <= 1'b0;
        end
    end

`else
    // --- HARDWARE PATH (Indestructible TRNG) ---
    
    // The (* keep *) attribute tells Quartus not to absorb these wires
    (* keep *) wire [STAGES-1:0] chain;

    // LCELL forces Quartus to use a physical logic element for the gate
    LCELL stage_0 (
        .in(enable ? ~chain[STAGES-1] : 1'b0),
        .out(chain[0])
    );

    genvar i;
    generate
        for (i = 1; i < STAGES; i++) begin : ro_loop
            LCELL stage_n (
                .in(~chain[i-1]),
                .out(chain[i])
            );
        end
    endgenerate

    // Sample the chaotic output!
    assign rand_bit = chain[STAGES-1];

`endif

endmodule