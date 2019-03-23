`timescale 1ns / 1ps
`default_nettype none

`include "rans_if.sv"

module top #(
    parameter RESOLUTION = 10,
    parameter SYMBOL_WIDTH = 8,
    parameter NUM_RANS = 4
)(
    rans_if.dut iface
);

logic [$clog2(NUM_RANS) - 1 : 0] cnt_r;
logic [NUM_RANS - 1 : 0] clk_div_en_r;
logic clk_div [NUM_RANS];

always_ff @(posedge iface.clk_i or posedge iface.rst_i) begin
    if (iface.rst_i) begin
        cnt_r <= 0;
        clk_div_en_r <= 1;
    end else begin
        cnt_r <= cnt_r + 1;
        clk_div_en_r <= {clk_div_en_r[NUM_RANS - 2 : 0], clk_div_en_r[NUM_RANS - 1]};
    end
end

logic [$clog2(NUM_RANS) - 1 : 0] freq_wr_cnt_r;
always_ff @(posedge iface.clk_i or posedge iface.rst_i) begin
    if (iface.rst_i) begin
        freq_wr_cnt_r <= 0;
    end else begin
        if (freq_wr_cnt_r) freq_wr_cnt_r <= freq_wr_cnt_r + 1;
        if (iface.freq_wr_i && !freq_wr_cnt_r) freq_wr_cnt_r <= 1;
    end
end

assign iface.ready_o = !freq_wr_cnt_r;

logic [1 : 0] valid [NUM_RANS];
logic [2 * SYMBOL_WIDTH - 1 : 0] enc [NUM_RANS];

genvar i;

`ifdef SIMULATION
    for (i = 0; i < NUM_RANS; i = i + 1) begin : gen_clk_buf
        assign clk_div[i] = clk_div_en_r[i];
    end
`else
    for (i = 0; i < NUM_RANS; i = i + 1) begin : gen_clk_buf
        BUFGCE I_clk_buf(.I(iface.clk_i), .CE(clk_div_en_r[i]), .O(clk_div[i]));
    end
`endif

logic en_r [NUM_RANS];
logic [SYMBOL_WIDTH - 1 : 0] symb_r [NUM_RANS];
for (i = 0; i < NUM_RANS; i = i + 1) begin
    always @(posedge clk_div[i]) begin
        en_r[i] <= iface.en_i;
        symb_r[i] <= iface.symb_i;
    end
end

for (i = 0; i < NUM_RANS; i = i + 1) begin : gen_rans
    rans I_rans(
        .clk_i(clk_div[i]),
        .rst_i(iface.rst_i),
        .en_i(en_r[i]),
        .freq_wr_i(iface.freq_wr_i),
        .freq_addr_i(iface.symb_i),
        .freq_i(iface.freq_i),
        .cum_freq_i(iface.cum_freq_i),
        .symb_i(symb_r[i]),
        .valid_o(valid[i]),
        .enc_o(enc[i])
    );
end

always @(posedge iface.clk_i) begin
    iface.valid_o <= valid[cnt_r];
    iface.enc_o <= enc[cnt_r];
end

endmodule
