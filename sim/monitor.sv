class Monitor #(
    parameter RESOLUTION = 10,
    parameter SYMBOL_WIDTH = 8,
    parameter NUM_RANS = 4
);
    localparam SCALE = 2 ** RESOLUTION;
    localparam L_MIN = SCALE;
    localparam L_MAX = L_MIN << SYMBOL_WIDTH;

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
        int i;
        int symb_idx = 0;
        int symbol;
        int errors = 0;
        longint state [NUM_RANS];
        bit [SYMBOL_WIDTH - 1 : 0] encoded [$];

        for (i = 0; i < NUM_RANS; i = i + 1) begin
            state[i] = L_MIN;
        end

        for (symb_idx = 0; symb_idx < transaction.symbols.size(); symb_idx = symb_idx + 1) begin
            symbol = transaction.symbols[symb_idx];
            state[enc_cnt] = encode(state[enc_cnt], transaction.pdf[symbol], transaction.cdf[symbol]);
            while (state[enc_cnt] >= L_MAX) begin
                encoded.push_back(state[enc_cnt][SYMBOL_WIDTH - 1 : 0]);
                state[enc_cnt] = state[enc_cnt] >> SYMBOL_WIDTH;
            end
            enc_cnt = enc_cnt + 1;
        end

        while (encoded.size()) begin
            @(iface.cb)
            for (i = 0; i < 2; i = i + 1) begin
                if (iface.cb.valid_o[i]) begin
                    if (iface.cb.enc_o[(i + 1) * SYMBOL_WIDTH - 1 -: SYMBOL_WIDTH] != encoded[0]) begin
                        $error("Mismatch #%d, Obs: %h, Exp: %h", errors, iface.cb.enc_o, encoded[0]);
                        errors = errors + 1;
                    end
                    encoded.pop_front();
                end
            end
        end

        $stop;
    endtask
endclass