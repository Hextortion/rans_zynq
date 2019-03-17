`timescale 1ns / 1ps
`default_nettype none

`include "rans_if.sv"
import RansTestPackage::*;

module tb;

localparam RESOLUTION = 10;
localparam SYMBOL_WIDTH = 8;

rans_if #(RESOLUTION, SYMBOL_WIDTH) iface();

top I_dut(iface.dut);

initial begin
    Driver #(RESOLUTION, SYMBOL_WIDTH) driver = new(iface);
    Transaction #(RESOLUTION, SYMBOL_WIDTH) transaction = new(100000);
    fork
        driver.gen_clk();
    join_none
    driver.reset();
    driver.drive(transaction);
end

endmodule