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

localparam STRB_WIDTH = DATA_WIDTH / 8;

rans_if #(RESOLUTION, SYMBOL_WIDTH) rans_multi_stream_if;
rans_multi_stream #(RESOLUTION, SYMBOL_WIDTH, NUM_RANS) I_rans_multi_stream(rans_multi_stream_if.dut);

logic rvalid_r;
logic arready_r;
logic [ADDR_WIDTH - 1 : 0] araddr_r;
logic [DATA_WIDTH - 1 : 0] rdata_r;
logic [ADDR_WIDTH - 1 : 0] awaddr_r;
logic [DATA_WIDTH - 1 : 0] wdata_r;
logic [STRB_WIDTH - 1 : 0] wstrb_r;
logic wvalid_r;
logic awready_r;
logic wready_r;
logic bvalid_r;

logic rstall;
assign rstall = rvalid_r && !ctrl_if.rready;
logic wstall;
assign wstall = bvalid_r && !ctrl_if.bready;

always_ff @(posedge ctrl_if.aclk) begin
    if (!ctrl_if.aresetn) begin
        rvalid_r <= 0;
    end else if (ctrl_if.arvalid) begin
        rvalid_r <= 1;
    end else if (rstall) begin
        rvalid_r <= 1;
    end else if (!arready_r) begin
        rvalid_r <= 1;
    end else
        rvalid_r <= 0;
    end
end

always_ff @(posedge ctrl_if.aclk) begin
    if (!posedge ctrl_if.aresetn) begin
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

always_ff @(posedge ctrl_if.aclk) begin
    if (!rstall) begin
        if (!arready_r) begin
            rdata_r <= mem[araddr_r];
        end else begin
            rdata_r <= mem[ctrl_if.araddr];
        end
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
    end else if (!awready_r || (wvalid_r && ctrl_if.wready)) begin
        awready_r <= 1'b1;
    end else
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
        wready <= 1;
    end else begin
        wready_r <= w_ready_r && !ctrl_if.wvalid
    end
end

always_ff @(posedge ctrl_if.aclk) begin
    if (awready_r && ctrl_if.awvalid) begin
        waddr_r <= ctrl_if.waddr_r;
    end
end

always_ff @(posedge ctrl_if.aclk) begin
    if (wready_r && ctrl_if.wvalid) begin
        wdata_r <= ctrl_if.wdata;
        wstrb_r <= ctrl_if.wstrb;
    end
end

always_ff @(posedge ctrl_if.aclk) begin
    if (!wstall && (!awready_r && ctrl_if.awvalid) && (!wready_r || ctrl_if.wvalid)) begin
        if (!wready_r) begin
            for (int i = 0; i < STRB_WIDTH; i = i + 1) begin
                if (wstrb_r[i]) begin
                    mem[waddr_r][i * STRB_WIDTH +: 8] <= wdata_r[i * STRB_WIDTH +: 8];
                end
            end
        end else begin
            for (int i = 0; i < STRB_WIDTH; i = i + 1) begin
                if (ctrl_if.wstrb[i]) begin
                    mem[ctrl_if.waddr][i * STRB_WIDTH +: 8] <= ctrl_if.wdata[i * STRB_WIDTH +: 8];
                end
            end
        end
    end
end

always @(posedge ctrl_if.aclk) begin
    if (!ctrl_if.aresetn) begin
        bvalid_r <= 0;
    end else if ((!awready_r || ctrl_if.awvalid) && (!wready_r || ctrl_if.wvalid)) begin
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