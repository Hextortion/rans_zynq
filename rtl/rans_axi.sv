module rans_axi #(
    parameter RESOLUTION = 10,
    parameter SYMBOL_WIDTH = 8,
    parameter NUM_RANS = 4
) (
    input clk_i,
    input rst_i,
    axi_lite_if.slave ctrl_if,
    axi_stream_if.slave stream_in_if,
    axi_stream_if.master stream_out_if
);

localparam ADDR_WIDTH = SYMBOL_WIDTH + 1;
localparam DATA_WIDTH = 32;
localparam STRB_WIDTH = DATA_WIDTH / 8;

rans_if #(RESOLUTION, SYMBOL_WIDTH) rans_multi_stream_if();
rans_multi_stream #(RESOLUTION, SYMBOL_WIDTH, NUM_RANS) I_rans_multi_stream(rans_multi_stream_if.dut);

logic rvalid_r;
logic arready_r;
logic [ADDR_WIDTH - 1 : 0] araddr_r;
logic [ADDR_WIDTH - 1 : 0] araddr;
logic [DATA_WIDTH - 1 : 0] rdata_r;
logic [DATA_WIDTH - 1 : 0] rdata;
logic [ADDR_WIDTH - 1 : 0] awaddr_r;
logic [ADDR_WIDTH - 1 : 0] awaddr;
logic [DATA_WIDTH - 1 : 0] wdata_r;
logic [DATA_WIDTH - 1 : 0] wdata;
logic awready_r;
logic wready_r;
logic bvalid_r;

logic rstall;
assign rstall = rvalid_r && !ctrl_if.rready;
logic wstall;
assign wstall = (bvalid_r && !ctrl_if.bready) || !rans_multi_stream_if.ready_o;

always_ff @(posedge ctrl_if.aclk) begin
    if (!ctrl_if.aresetn) begin
        rvalid_r <= 0;
    end else if (ctrl_if.arvalid) begin
        rvalid_r <= 1;
    end else if (rstall) begin
        rvalid_r <= 1;
    end else if (!arready_r) begin
        rvalid_r <= 1;
    end else begin
        rvalid_r <= 0;
    end
end

always_ff @(posedge ctrl_if.aclk) begin
    if (!ctrl_if.aresetn) begin
        arready_r <= 0;
    end else begin
        if (rstall) begin
            if (!arready_r) begin
                arready_r <= 0;
            end else begin
                arready_r <= !ctrl_if.arvalid;
            end
        end else begin
            arready_r <= 1;
        end
    end
end

always_ff @(posedge ctrl_if.aclk) begin
    if (arready_r) begin
        araddr_r <= ctrl_if.araddr;
    end
end

always_comb begin
    if (!arready_r) begin
        araddr = araddr_r;
    end else begin
        araddr = ctrl_if.araddr;
    end
end

always_ff @(posedge ctrl_if.aclk) begin
    if (!rstall) begin

    end
end

always_ff @(posedge ctrl_if.aclk) begin
    if (!ctrl_if.aresetn) begin
        awready_r <= 1;
    end else if (wstall) begin
        if (!awready_r) begin
            awready_r <= 0;
        end else begin
            awready_r <= !ctrl_if.awvalid;
        end
    end else if (!wready_r || (ctrl_if.wvalid && wready_r)) begin
        awready_r <= 1;
    end else begin
        awready_r <= awready_r && !ctrl_if.awvalid;
    end
end

always_ff @(posedge ctrl_if.aclk) begin
    if (!ctrl_if.aresetn) begin
        wready_r <= 1;
    end else if (wstall) begin
        if (!wready_r) begin
            wready_r <= 0;
        end else begin
            wready_r <= !ctrl_if.wvalid;
        end
    end else if (!awready_r || (ctrl_if.awvalid && awready_r)) begin
        wready_r <= 1;
    end else begin
        wready_r <= wready_r && !ctrl_if.wvalid;
    end
end

always_ff @(posedge ctrl_if.aclk) begin
    if (awready_r && ctrl_if.awvalid) begin
        awaddr_r <= ctrl_if.awaddr;
    end
end

always_comb begin
    if (!awready_r) begin
        awaddr = awaddr_r;
    end else begin
        awaddr = ctrl_if.awaddr;
    end
end

always_ff @(posedge ctrl_if.aclk) begin
    if (wready_r && ctrl_if.wvalid) begin
        wdata_r <= ctrl_if.wdata;
    end
end

always_comb begin
    if (!wready_r) begin
        wdata = wdata_r;
    end else begin
        wdata = ctrl_if.wdata;
    end
end

always_ff @(posedge ctrl_if.aclk) begin
    if (!wstall &&
        (!awready_r || ctrl_if.awvalid) &&
        (!wready_r  || ctrl_if.wvalid))
    begin
        rans_multi_stream_if.freq_wr_i <= 0;
        rans_multi_stream_if.restart_i <= 0;
        if (awaddr < (2 ** SYMBOL_WIDTH)) begin
            rans_multi_stream_if.freq_wr_i <= 1;
            rans_multi_stream_if.symb_i <= awaddr[SYMBOL_WIDTH - 1 : 0];
            {rans_multi_stream.freq_i, rans_multi_stream.cum_freq_i}
                    <= wdata[2 * RESOLUTION - 1 : 0];
        end else if (awaddr == (2 ** SYMBOL_WIDTH)) begin
            rans_multi_stream_if.restart_i <= 1;
        end
    end
end

always @(posedge ctrl_if.aclk) begin
    if (!ctrl_if.aresetn) begin
        bvalid_r <= 0;
    end else if (rans_multi_stream_if.ready_o    &&
                 (!awready_r || ctrl_if.awvalid) &&
                 (!wready_r  || ctrl_if.wvalid))
    begin
        bvalid_r <= 1;
    end else if (ctrl_if.bready) begin
        bvalid_r <= 0;
    end
end

assign ctrl_if.rvalid = rvalid_r;
assign ctrl_if.arready = arready_r;
assign ctrl_if.awready = awready_r;
assign ctrl_if.wready = wready_r;
assign ctrl_if.bvalid = bvalid_r;
assign ctrl_if.rresp = 0;
assign ctrl_if.bresp = 0;

endmodule