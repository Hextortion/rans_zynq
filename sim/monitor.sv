class Monitor #(
    parameter RESOLUTION = 10,
    parameter SYMBOL_WIDTH = 8,
    parameter NUM_RANS = 4
);
    longint state [NUM_RANS];

    virtual rans_if #(RESOLUTION, SYMBOL_WIDTH).tb iface;

    function new(virtual rans_if #(RESOLUTION, SYMBOL_WIDTH).tb iface);
        this.iface = iface;
    endfunction

    function longint encode(longint state, longint freq, longint cum_freq);
        encode = ((state / freq) << RESOLUTION) + (state % freq) + cum_freq;
    endfunction

    task run(ref Transaction #(RESOLUTION, SYMBOL_WIDTH) transaction);
        bit [$clog2(NUM_RANS) - 1 : 0] enc_cnt = 0;
        bit done = 0;

        while (!done) begin
            @(iface.cb)
            if (iface.cb.valid_o) begin
                state[enc_cnt] = encode(state[enc_cnt],
                        transaction.pdf[symb], transaction.cdf[symb]);
            end
            enc_cnt = 0;
        end
    endtask
endclass