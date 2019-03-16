`timescale 1ns / 1ps
`default_nettype none

`include "rans_if.sv"

module tb;

localparam RESOLUTION = 10;
localparam SYMBOL_WIDTH = 8;

rans_if #(RESOLUTION, SYMBOL_WIDTH) iface();

top I_dut(iface.dut);

function longint encode(longint state, longint freq, longint cum_freq);
    encode = ((state / freq) << RESOLUTION) + (state % freq) + cum_freq;
endfunction

endmodule