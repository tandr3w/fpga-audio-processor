`timescale 1ns/100ps

module ring_oscillator #(parameter STAGES = 13) (
    input  logic enable,
    input  logic CLOCK_50,
    output logic rand_bit
);

`ifndef SYNTHESIS 
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

    /* synthesis keep */ wire [STAGES-1:0] chain;

    assign chain[0] = enable ? ~chain[STAGES-1] : 1'b0;

    genvar i;
    generate
        for (i = 1; i < STAGES; i++) begin : ro_loop
            assign chain[i] = ~chain[i-1];
        end
    endgenerate

    assign rand_bit = chain[STAGES-1];

`endif

endmodule