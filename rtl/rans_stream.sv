`timescale 1ns / 1ps
`default_nettype none

module rans_stream #(
    parameter RESOLUTION = 10,
    parameter SYMBOL_WIDTH = 8,
    parameter SHIFT_WIDTH = 4
) (
    input var logic clk_i,
    input var logic valid_i,
    input var logic freq_wr_i,
    input var logic restart_i,
    input var logic [SYMBOL_WIDTH - 1 : 0] freq_addr_i,
    input var logic [RESOLUTION - 1 : 0] freq_i,
    input var logic [RESOLUTION - 1 : 0] cum_freq_i,
    input var logic [SYMBOL_WIDTH - 1 : 0] symb_i,
    output var logic [1 : 0] valid_o,
    output var logic [2 * SYMBOL_WIDTH - 1 : 0] enc_o
);

localparam DIVTABLE_WIDTH = RESOLUTION + SYMBOL_WIDTH + SHIFT_WIDTH;
localparam STATE_WIDTH = RESOLUTION + SYMBOL_WIDTH;
localparam MULT_WIDTH = 2 * STATE_WIDTH;
localparam SCALE = 2 ** RESOLUTION;
localparam L_MIN = SCALE;
localparam L_MAX = L_MIN << SYMBOL_WIDTH;

logic [2 * RESOLUTION - 1 : 0] freqtable [2 ** SYMBOL_WIDTH];
logic [DIVTABLE_WIDTH - 1 : 0] divtable [2 ** RESOLUTION];

`ifdef SIMULATION
    `define HEX_PATH "rtl/"
`else
    `define HEX_PATH ""
`endif

initial begin
    $readmemh({`HEX_PATH, "divtable.mem"}, divtable);
end

logic valid_r;
logic [RESOLUTION - 1 : 0] freq_r;
logic [RESOLUTION - 1 : 0] cum_freq_r;

always_ff @(posedge clk_i) begin
    if (freq_wr_i) begin
        freqtable[freq_addr_i] <= {freq_i, cum_freq_i};
    end
end

always_ff @(posedge clk_i) begin
    valid_r <= valid_i;
    freq_r <= freqtable[symb_i][2 * RESOLUTION - 1 : RESOLUTION];
    cum_freq_r <= freqtable[symb_i][RESOLUTION - 1 : 0];
end

logic valid_d1r;
logic [RESOLUTION - 1 : 0] cmpl_freq_r;
logic [STATE_WIDTH - 1 : 0] rcp_r;
logic [SHIFT_WIDTH - 1 : 0] shift_r;
logic [RESOLUTION - 1 : 0] cum_freq_d1r;

always_ff @(posedge clk_i) begin
    valid_d1r <= valid_r;
    cmpl_freq_r <= SCALE - freq_r;
    rcp_r <= divtable[freq_r][STATE_WIDTH - 1 : 0];
    shift_r <= divtable[freq_r][DIVTABLE_WIDTH - 1 : STATE_WIDTH];
    cum_freq_d1r <= cum_freq_r;
end

logic [STATE_WIDTH - 1 : 0] state_r;
logic [2 * STATE_WIDTH - 1 : 0] quotient_int;
logic [STATE_WIDTH - 1 : 0] quotient;
logic [2 * STATE_WIDTH + RESOLUTION - 1 : 0] state_int;
logic [1 : 0] shift_byte;

always_comb begin
    quotient_int = state_r * rcp_r;
    quotient = quotient_int[2 * STATE_WIDTH - 1 : STATE_WIDTH - 1] >> shift_r;
    state_int = (state_r + cum_freq_d1r) + (cmpl_freq_r * quotient);
    shift_byte[0] = state_int >= L_MAX;
    shift_byte[1] = (state_int >> SYMBOL_WIDTH) >= L_MAX;
end

// The encoder may need to shift out 0, 1, or 2 if the RESOLUTION is larger than
// the SYMBOL_WIDTH. It is natural to expect RESOLUTION to be larger especially if we
// would like the frequency counts to have decent accuracy.
always_ff @(posedge clk_i) begin
    valid_o[0] <= shift_byte[0] && valid_d1r;
    valid_o[1] <= shift_byte[1] && valid_d1r;
    enc_o <= state_int[2 * SYMBOL_WIDTH - 1: 0];
end

always_ff @(posedge clk_i) begin
    if (restart_i) begin
        state_r <= L_MIN;
    end else begin
        if (valid_d1r) begin
            if (shift_byte[0]) begin
                state_r <= state_int >> SYMBOL_WIDTH;
                if (shift_byte[1]) begin
                    state_r <= state_int >> (2 * SYMBOL_WIDTH);
                end
            end else begin
                state_r <= state_int;
            end
        end
    end
end

endmodule

`default_nettype wire