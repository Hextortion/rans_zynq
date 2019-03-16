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
        iface.cb.en_i <= 1'b0;
        iface.cb.freq_wr_i <= 1'b0;
        iface.cb.rst_i <= 1'b0;
        @(iface.cb);
        iface.cb.rst_i <= 1'b1;
        @(iface.cb);
        iface.cb.rst_i <= 1'b0;
    endtask

    task drive(ref Transaction #(RESOLUTION, SYMBOL_WIDTH) transaction);
        for (int i = 0; i < 2 ** SYMBOL_WIDTH;) begin
            @(iface.cb);
            if (iface.cb.ready_o) begin
                iface.cb.freq_wr_i <= 1'b1;
                iface.cb.symb_i <= i;
                iface.cb.freq_i <= transaction.pdf[i];
                iface.cb.cum_freq_i <= transaction.cdf[i];
                i = i + 1;
            end
        end

        @(iface.cb);
        iface.cb.freq_wr_i <= 1'b0;

        for (int i = 0; i < transaction.symbols.size(); i = i + 1) begin
            @(iface.cb);
            iface.cb.en_i <= 1'b1;
            iface.cb.symb_i <= transaction.symbols[i];
        end

        @(iface.cb);
        iface.cb.en_i <= 1'b0;
    endtask
endclass
