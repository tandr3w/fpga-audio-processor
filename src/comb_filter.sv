`timescale 1ns/100ps

module comb_filter #(parameter DEPTH = 2048) (
    input  logic              clk,
    input  logic              tick,
    input  logic              enable,
    input  logic signed [31:0] in,
    output logic signed [31:0] out
);
    // Memory is pre-initialized to 0, meaning we don't need X-state checks!
    logic signed [31:0] mem [DEPTH-1:0] = '{default:32'sh0};
    logic [$clog2(DEPTH)-1:0] addr = 0;
    
    // Initialize to 0 so the first cycle is clean
    logic signed [31:0] delayed_raw = 0; 

    // M10K Block RAM Inference
    always_ff @(posedge clk) begin
        delayed_raw <= mem[addr];
    end

    always_ff @(posedge clk) begin
        // Only do math when a new sample arrives
        if (tick) begin 
            if (!enable) begin
                out <= in;
            end else begin
                // EXPLICIT CHANGE: Using delayed_raw directly in the math!
                mem[addr] <= (in >>> 1) + (delayed_raw >>> 1) + (delayed_raw >>> 2) + (delayed_raw >>> 3); 
                out <= delayed_raw;
                
                addr <= (addr == DEPTH-1) ? 0 : addr + 1;
            end
        end
    end
endmodule