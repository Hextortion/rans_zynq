`include "rans_if.sv"
`include "transaction.sv"

class Driver #(
    parameter RESOLUTION = 10,
    parameter SYMBOL_WIDTH = 8
);
    virtual rans_if #(RESOLUTION, SYMBOL_WIDTH).tb iface;

    function new(virtual rans_if #(RESOLUTION, SYMBOL_WIDTH).tb iface);
        this.iface = iface;
    endfunction

    task gen_clk();
        iface.clk_i = 1'b0;
        forever begin
            #2.5ns iface.clk_i = ~iface.clk_i;
        end
    endtask

    task reset();
        iface.en_i = 1'b0;
        iface.freq_wr_i = 1'b0;
        iface.rst_i = 1'b0;
        @(posedge iface.clk_i);
        iface.rst_i = 1'b1;
        @(posedge iface.clk_i);
        iface.rst_i = 1'b0;
    endtask

    task drive(ref Transaction #(RESOLUTION, SYMBOL_WIDTH) transaction);
        @(posedge iface.clk_i);
        for (int i = 0; i < 2 ** SYMBOL_WIDTH; i = i + 1) begin
            iface.freq_wr_i = 1'b1;
            iface.freq_i = transaction.pdf[i];
            iface.cum_freq_i = transaction.cdf[i];
            @(posedge iface.clk_i);
        end

        iface.freq_wr_i = 1'b0;
        @(posedge iface.clk_i);
        for (int i = 0; i < transaction.symbols.size(); i = i + 1) begin
            iface.en_i = 1'b1;
            iface.symb_i = transaction.symbols[i];
            @(posedge iface.clk_i);
        end

        iface.en_i = 1'b0;
        @(posedge iface.clk_i);
    endtask
endclass
