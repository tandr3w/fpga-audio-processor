`timescale 1ns/100ps

module top #(
) (
    input  logic       a,
    input  logic       b,
    output logic       and_o,
    output logic       xor_o,
    output logic [2:0] and_or_xor
);
    assign and_o = a & b;
    assign xor_o = a ^ b;
    assign and_or_xor = {a & b, a | b, a ^ b};
endmodule