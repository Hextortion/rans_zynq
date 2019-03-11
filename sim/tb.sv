`timescale 1ns / 1ps

module tb;

logic clk;
logic rst;
logic en;
logic freq_wr;
logic [9:0] freq;
logic [9:0] cum_freq;
logic [7:0] symb;
logic valid;
logic [7:0] enc;

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

initial begin
    clk = 1'b0;
    forever begin
        #2.5ns clk = ~clk;
    end
end

initial begin
    rst = 1'b0;
    repeat (2) @(posedge clk);
    rst = 1'b1;
    repeat (2) @(posedge clk);
    rst = 1'b0;
end

endmodule