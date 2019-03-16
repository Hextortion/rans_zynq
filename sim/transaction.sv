class Transaction #(
    parameter RESOLUTION = 10,
    parameter SYMBOL_WIDTH = 8
);
    bit [SYMBOL_WIDTH - 1 : 0] num_symbols;
    int symbols [];
    int pdf [2 ** SYMBOL_WIDTH];
    int cdf [2 ** SYMBOL_WIDTH + 1];

    function new(int num_symbols);
        int best_freq;
        int best_steal;
        int freq;
        int cur_total;
        int i, j;

        this.num_symbols = num_symbols;
        symbols = new [num_symbols];

        for (i = 0; i < num_symbols; i = i + 1) begin
            bit [SYMBOL_WIDTH - 1 : 0] symb = $urandom_range(0, 2 ** SYMBOL_WIDTH - 1);
            symbols[i] = symb;
            pdf[symb] = pdf[symb] + 1;
        end

        cdf[0] = 0;
        for (i = 0; i < 2 ** SYMBOL_WIDTH; i = i + 1) begin
            cdf[i + 1] = cdf[i] + pdf[i];
        end

        cur_total = cdf[2 ** SYMBOL_WIDTH];
        for (i = 1; i <= 2 ** SYMBOL_WIDTH; i = i + 1) begin
            cdf[i] = 2 ** RESOLUTION * cdf[i] / num_symbols;
        end

        for (i = 0; i < 2 ** SYMBOL_WIDTH; i = i + 1) begin
            if (cdf[i + 1] == cdf[i]) begin
                best_freq = ~0;
                best_steal = -1;

                for (j = 0; j < num_symbols; j++) begin
                    freq = cdf[j + 1] - cdf[j];
                    if (freq > 1 && freq < best_freq) begin
                        best_freq = freq;
                        best_steal = j;
                    end
                end

                if (best_steal < i) begin
                    for (j = best_steal + 1; j <= i; j++) begin
                        cdf[j] = cdf[j] - 1;
                    end
                end else begin
                    for (j = i + 1; j <= best_steal; j++) begin
                        cdf[j] = cdf[j] + 1;
                    end
                end
            end
        end

        for (i = 0; i < 2 ** SYMBOL_WIDTH; i++) begin
            pdf[i] = cdf[i + 1] - cdf[i];
        end
    endfunction
endclass
