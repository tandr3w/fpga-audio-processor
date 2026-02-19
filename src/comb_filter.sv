module comb_filter #(parameter DEPTH = 2048) (
    input  logic              clk,
    input  logic              enable,
    input  logic signed [31:0] in,
    output logic signed [31:0] out
);
    logic signed [31:0] mem [DEPTH-1:0];
    logic [$clog2(DEPTH)-1:0] addr = 0;
    logic signed [31:0] delayed_raw;
    logic signed [31:0] delayed_clean;

    always_ff @(posedge clk) begin
        if (!enable) begin
            out <= in;
            addr <= 0;
        end else begin
            delayed_raw = mem[addr];
            delayed_clean = $isunknown(delayed_raw) ? 32'sh0 : delayed_raw;
            
            // FEEDBACK: Present + 87.5% of Past
            // (1/2 + 1/4 + 1/8) = 0.875. This makes the reverb "linger" much longer.
            mem[addr] <= (in >>> 1) + (delayed_clean >>> 1) + (delayed_clean >>> 2) + (delayed_clean >>> 3); 
            
            out <= delayed_clean;
            addr <= (addr == DEPTH-1) ? 0 : addr + 1;
        end
    end
endmodule