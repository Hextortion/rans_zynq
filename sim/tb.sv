`timescale 1ns / 1ps

module tb;

localparam RESOLUTION = 10;
localparam SYMBOL_WIDTH = 8;

logic clk;
logic rst;
logic en;
logic freq_wr;
logic [RESOLUTION - 1 : 0] freq;
logic [RESOLUTION - 1 : 0] cum_freq;
logic [SYMBOL_WIDTH - 1 : 0] symb;
logic valid;
logic [SYMBOL_WIDTH - 1 : 0] enc;

top I_dut(
    .clk_i(clk),
    .rst_i(rst),
    .en_i(en),
    .freq_wr_i(freq_wr),
    .freq_i(freq),
    .cum_freq_i(cum_freq),
    .symb_i(symb),
    .valid_o(valid),
    .enc_o(enc)
);

class Driver #(
    parameter RESOLUTION = 10,
    parameter SYMBOL_WIDTH = 8
);
    task reset;
        en = 1'b0;
        freq_wr = 1'b0;
        rst = 1'b0;
        @(posedge clk);
        rst = 1'b1;
        @(posedge clk);
        rst = 1'b0;
    endtask

    task drive(ref Transaction #(RESOLUTION, SYMBOL_WIDTH) transaction);
        @(posedge clk);
        for (int i = 0; i < 2 ** SYMBOL_WIDTH; i = i + 1) begin
            freq_wr = 1'b1;
            freq = transaction.pdf[i];
            cum_freq = transaction.cdf[i];
            @(posedge clk);
        end

        freq_wr = 1'b0;
        @(posedge clk);
        for (int i = 0; i < transaction.symbols.size(); i = i + 1) begin
            en = 1'b1;
            symb = transaction.symbols[i];
            @(posedge clk);
        end

        en = 1'b0;
        @(posedge clk);
    endtask
endclass

class Transaction #(
    parameter RESOLUTION = 10,
    parameter SYMBOL_WIDTH = 8
);
    bit [SYMBOL_WIDTH - 1 : 0] num_symbols;
    int symbols [];
    int pdf [2 ** SYMBOL_WIDTH];
    int cdf [2 ** SYMBOL_WIDTH + 1];

    function automatic new(int num_symbols);
        int best_freq;
        int best_steal;
        int freq;

        this.num_symbols = num_symbols;
        symbols = new [num_symbols];

        for (int i = 0; i < num_symbols; i = i + 1) begin
            bit [SYMBOL_WIDTH - 1 : 0] symb = $urandom_range(0, 2 ** SYMBOL_WIDTH - 1);
            symbols[i] = symb;
            pdf[symb] = pdf[symb] + 1;
        end

        cdf[0] = 0;
        for (int i = 0; i < 2 ** SYMBOL_WIDTH; i = i + 1) begin
            cdf[i + 1] = cdf[i] + pdf[i];
        end

        int cur_total = cdf[2 ** SYMBOL_WIDTH];
        for (int i = 1; i <= 2 ** SYMBOL_WIDTH; i = i + 1) begin
            cdf[i] = 2 ** RESOLUTION * cdf[i] / num_symbols;
        end

        for (int i = 0; i < 2 ** SYMBOL_WIDTH; i = i + 1) begin
            if (cdf[i + 1] == cdf[i]) begin
                best_freq = ~0;
                best_steal = -1;

                for (int j = 0; j < num_symbols; j++) begin
                    freq = cdf[j + 1] - cdf[j];
                    if (freq > 1 && freq < best_freq) begin
                        best_freq = freq;
                        best_steal = j;
                    end
                end

                if (best_steal < i) begin
                    for (int j = best_steal + 1; j <= i; j++) begin
                        cdf[j] = cdf[j] - 1;
                    end
                end else begin
                    for (int j = i + 1; j <= best_steal; j++) begin
                        cdf[j] = cdf[j] + 1;
                    end
                end
            end
        end

        for (int i = 0; i < 2 ** SYMBOL_WIDTH; i++) begin
            pdf[i] = cdf[i + 1] - cdf[i];
        end
    endfunction
end

function longint encode(longint state, longint freq, longint cum_freq);
    encode = ((state / freq) << RESOLUTION) + (state % freq) + cum_freq;
endfunction

initial begin
    clk = 1'b0;
    forever begin
        #2.5ns clk = ~clk;
    end
end

initial begin

end

endmodule