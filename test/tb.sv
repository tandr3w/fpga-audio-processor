`timescale 1ns/100ps

module tb;
    logic a;
    logic b;
    logic and_o;
    logic xor_o;
    logic [2:0] and_or_xor;

    // Instantiate the AND gate
    top uut (
        .a(a),
        .b(b),
        .and_o(and_o),
        .xor_o(xor_o),
        .and_or_xor(and_or_xor)
    );

    initial begin
        $dumpfile("sim_out/wave.vcd");
        $dumpvars(0, tb);
    end

    // Clock not needed, just stimulus
    initial begin
        
        // Print header
        $display("Time\t a b | AND XOR");
        $display("----------------");

        // Test all combinations
        a = 0; b = 0; #10 $display("%0t\t %b %b | %b", $time, a, b, and_o, xor_o);
        a = 0; b = 1; #10 $display("%0t\t %b %b | %b", $time, a, b, and_o, xor_o);
        a = 1; b = 0; #10 $display("%0t\t %b %b | %b", $time, a, b, and_o, xor_o);
        a = 1; b = 1; #10 $display("%0t\t %b %b | %b", $time, a, b, and_o, xor_o);
        a = 0; b = 0; #10 $display("%0t\t %b %b | %b", $time, a, b, and_o, xor_o);
        a = 0; b = 1; #10 $display("%0t\t %b %b | %b", $time, a, b, and_o, xor_o);
        a = 1; b = 0; #10 $display("%0t\t %b %b | %b", $time, a, b, and_o, xor_o);
        a = 1; b = 1; #10 $display("%0t\t %b %b | %b", $time, a, b, and_o, xor_o);

        $display("Testbench finished!");
        $finish;
    end
endmodule