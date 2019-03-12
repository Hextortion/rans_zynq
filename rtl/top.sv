`timescale 1ns / 1ps

module top #(
    parameter RESOLUTION = 10,
    parameter SYMBOL_WIDTH = 8
)(
    input logic clk_i,
    input logic rst_i,
    input logic en_i,
    input logic freq_wr_i,
    input logic [RESOLUTION - 1 : 0] freq_i,
    input logic [RESOLUTION - 1 : 0] cum_freq_i,
    input logic [SYMBOL_WIDTH - 1 : 0] symb_i,
    output logic valid_o,
    output logic [SYMBOL_WIDTH - 1 : 0] enc_o
);

logic [1:0] cnt_r;
logic [3:0] clk_div_en_r;
logic [3:0] clk_div;

always_ff @(posedge clk_i or posedge rst_i) begin
    if (rst_i) begin
        cnt_r <= 'd0;
        clk_div_en_r <= 4'b0001;
    end else begin
        cnt_r <= cnt_r + 'd1;
        clk_div_en_r <= {clk_div_en_r[2:0], clk_div_en_r[3]};
    end
end

logic valid [4];
logic [7:0] enc [4];

genvar i;

`ifdef SIMULATION
    for (i = 0; i < 4; i = i + 1) begin : gen_clk_buf
        assign clk_div[i] = clk_i && clk_div_en_r[i];
    end
`else
    for (i = 0; i < 4; i = i + 1) begin : gen_clk_buf
        BUFGCE I_clk_buf(.I(clk_i), .CE(clk_div_en_r[i]), .O(clk_div[i]));
    end
`endif

for (i = 0; i < 4; i = i + 1) begin : gen_rans
    rans I_rans(
        .clk_i(clk_div[i]),
        .rst_i(rst_i),
        .en_i(en_i),
        .freq_wr_i(freq_wr_i),
        .freq_i(freq_i),
        .cum_freq_i(cum_freq_i),
        .symb_i(symb_i),
        .valid_o(valid[i]),
        .enc_o(enc[i])
    );
end

assign valid_o = valid[cnt_r];
assign enc_o = enc[cnt_r];

endmodule
