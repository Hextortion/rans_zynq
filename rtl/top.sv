`timescale 1ns / 1ps
`default_nettype none

`include "rans_if.sv"

module top #(
    parameter RESOLUTION = 10,
    parameter SYMBOL_WIDTH = 8
)(
    rans_if.dut iface
);

logic [1:0] cnt_r;
logic [3:0] clk_div_en_r;
logic clk_div [4];

always_ff @(posedge iface.clk_i or posedge iface.rst_i) begin
    if (iface.rst_i) begin
        cnt_r <= 'd0;
        clk_div_en_r <= 4'b0001;
    end else begin
        cnt_r <= cnt_r + 'd1;
        clk_div_en_r <= {clk_div_en_r[2:0], clk_div_en_r[3]};
    end
end

logic [1:0] freq_wr_cnt_r;
always_ff @(posedge iface.clk_i or posedge iface.rst_i) begin
    if (iface.rst_i) begin
        freq_wr_cnt_r <= 0;
    end else begin
        if (freq_wr_cnt_r) freq_wr_cnt_r <= freq_wr_cnt_r + 1;
        if (iface.freq_wr_i && !freq_wr_cnt_r) freq_wr_cnt_r <= 1;
    end
end

assign iface.ready_o = !freq_wr_cnt_r;

logic valid [4];
logic [SYMBOL_WIDTH - 1 : 0] enc [4];

genvar i;

`ifdef SIMULATION
    for (i = 0; i < 4; i = i + 1) begin : gen_clk_buf
        assign clk_div[i] = clk_div_en_r[i];
    end
`else
    for (i = 0; i < 4; i = i + 1) begin : gen_clk_buf
        BUFGCE I_clk_buf(.I(iface.clk_i), .CE(clk_div_en_r[i]), .O(clk_div[i]));
    end
`endif

for (i = 0; i < 4; i = i + 1) begin : gen_rans
    rans I_rans(
        .clk_i(clk_div[i]),
        .rst_i(iface.rst_i),
        .en_i(iface.en_i),
        .freq_wr_i(iface.freq_wr_i),
        .freq_i(iface.freq_i),
        .cum_freq_i(iface.cum_freq_i),
        .symb_i(iface.symb_i),
        .valid_o(valid[i]),
        .enc_o(enc[i])
    );
end

assign iface.valid_o = valid[cnt_r];
assign iface.enc_o = enc[cnt_r];

endmodule
