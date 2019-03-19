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
        $display("%h %h %h %h", state, ((state / freq) << RESOLUTION), (state % freq), cum_freq);
        encode = ((state / freq) << RESOLUTION) + (state % freq) + cum_freq;
    endfunction

    task run(ref Transaction #(RESOLUTION, SYMBOL_WIDTH) transaction);
        bit [$clog2(NUM_RANS) - 1 : 0] enc_cnt = 0;
        int i;
        int symb_idx = 0;
        int symbol;
        bit received_first_symbol = 0;
        int num_errors = 0;
        bit [$clog2(NUM_RANS) - 1 : 0] output_bits;

        for (i = 0; i < NUM_RANS; i = i + 1) begin
            output_bits[i] = 0;
            state[i] = L_MIN;
        end

        for (symb_idx = 0; num_errors < 10 && symb_idx < transaction.symbols.size();) begin
            @(iface.cb);
            if (iface.cb.valid_o) begin
                received_first_symbol = 1;
                if (received_first_symbol) begin
                    symbol = transaction.symbols[symb_idx];
                end
            end

            if (received_first_symbol) begin
                state[enc_cnt] = encode(state[enc_cnt],
                        transaction.pdf[symbol], transaction.cdf[symbol]);

                if (output_bits[enc_cnt]) begin
                    if (iface.cb.enc_o != state[enc_cnt][SYMBOL_WIDTH - 1 : 0]) begin
                        num_errors = num_errors + 1;
                        $error("rANS Encoder %d Failed. Symbols Encoded: %d, Exp: %h, Obs: %h", enc_cnt,
                                symb_idx, state[enc_cnt][SYMBOL_WIDTH - 1 : 0], iface.cb.enc_o);
                        $display("cum freq: %h, freq: %h, symbol: %h", transaction.cdf[symbol], transaction.pdf[symbol], symbol);
                    end
                end

                output_bits[enc_cnt] = state[enc_cnt] >= L_MAX;
                if (state[enc_cnt] >= L_MAX) begin
                    state[enc_cnt] = state[enc_cnt] >> SYMBOL_WIDTH;
                end

                symb_idx = symb_idx + 1;
                enc_cnt = enc_cnt + 1;
            end
        end

        $stop;
    endtask
endclass