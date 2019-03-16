interface rans_if #(
    parameter RESOLUTION = 10,
    parameter SYMBOL_WIDTH = 8
);
    logic clk_i;
    logic rst_i;
    logic en_i;
    logic freq_wr_i;
    logic [RESOLUTION - 1 : 0] freq_i;
    logic [RESOLUTION - 1 : 0] cum_freq_i;
    logic [SYMBOL_WIDTH - 1 : 0] symb_i;
    logic ready_o;
    logic valid_o;
    logic [SYMBOL_WIDTH - 1 : 0] enc_o;

    modport tb (input ready_o, valid_o, enc_o,
                output clk_i, rst_i, en_i, freq_wr_i, freq_i, cum_freq_i, symb_i);

    modport dut (output ready_o, valid_o, enc_o,
                 input clk_i, rst_i, en_i, freq_wr_i, freq_i, cum_freq_i, symb_i);
endinterface