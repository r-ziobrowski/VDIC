`timescale 1ns/1ps

module dummy_dut(
    input wire clock,
    input wire reset,
    input wire valid,
    output logic [7:0] data
    );

    assign data = '1;

endmodule
