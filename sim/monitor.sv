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
        bit received_first_symbol = 0;

        for (i = 0; i < NUM_RANS; i = i + 1) begin
            state[enc_cnt] = L_MIN;
        end

        for (symb_idx = 0; symb_idx < transaction.symbols.size();) begin
            @(iface.cb);
            if (iface.cb.valid_o) begin
                received_first_symbol = 1;
                if (received_first_symbol) begin
                    symbol = transaction.symbols[symb_idx];
                    symb_idx = symb_idx + 1;
                end

                state[enc_cnt] = encode(state[enc_cnt],
                        transaction.pdf[symbol], transaction.cdf[symbol]);

                if (state[enc_cnt] >= L_MAX) begin
                    if (iface.cb.enc_o != state[enc_cnt][SYMBOL_WIDTH - 1 : 0]) begin
                        $display("rANS Encoder %d Failed. Symbols Encoded: %d, Exp: %d, Obs: %d", enc_cnt,
                                symb_idx, state[enc_cnt][SYMBOL_WIDTH - 1 : 0], iface.cb.enc_o);
                    end

                    state[enc_cnt] = state[enc_cnt] >> SYMBOL_WIDTH;
                end
            end
            enc_cnt = enc_cnt + 1;
        end

        $stop;
    endtask
endclass