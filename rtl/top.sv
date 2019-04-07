module top(
    inout wire [14:0] DDR_addr,
    inout wire [2:0] DDR_ba,
    inout wire DDR_cas_n,
    inout wire DDR_ck_n,
    inout wire DDR_ck_p,
    inout wire DDR_cke,
    inout wire DDR_cs_n,
    inout wire [3:0] DDR_dm,
    inout wire [31:0] DDR_dq,
    inout wire [3:0] DDR_dqs_n,
    inout wire [3:0] DDR_dqs_p,
    inout wire DDR_odt,
    inout wire DDR_ras_n,
    inout wire DDR_reset_n,
    inout wire DDR_we_n,
    inout wire FIXED_IO_ddr_vrn,
    inout wire FIXED_IO_ddr_vrp,
    inout wire [53:0] FIXED_IO_mio,
    inout wire FIXED_IO_ps_clk,
    inout wire FIXED_IO_ps_porb,
    inout wire FIXED_IO_ps_srstb
);

logic SYSTEM_CLK;
logic SYSTEM_RSTN;
assign ctrl_if.aclk = SYSTEM_CLK;
assign ddr_if.aclk = SYSTEM_CLK;
assign ctrl_if.aresetn = SYSTEM_RSTN;
assign ddr_if.aresetn = SYSTEM_RSTN;

axi_lite_if #(.ADDR_WIDTH(32), .DATA_WIDTH(32)) ctrl_if();
axi_lite_if #(.ADDR_WIDTH(32), .DATA_WIDTH(64)) ddr_if();

rans_axi #(
    .RESOLUTION(10),
    .SYMBOL_WIDTH(8),
    .NUM_RANS(4)) (
    .clk_i(SYSTEM_CLK),
    .rst_i(!SYSTEM_RSTN),
    .ctrl_if(ctrl_if),
    .mem_if(ddr_if)
);

base I_base(
    .SYSTEM_CLK(SYSTEM_CLK),
    .SYSTEM_RSTN(SYSTEM_RSTN),
    .DDR_addr(DDR_addr),
    .DDR_ba(DDR_ba),
    .DDR_cas_n(DDR_cas_n),
    .DDR_ck_n(DDR_ck_n),
    .DDR_ck_p(DDR_ck_p),
    .DDR_cke(DDR_cke),
    .DDR_cs_n(DDR_cs_n),
    .DDR_dm(DDR_dm),
    .DDR_dq(DDR_dq),
    .DDR_dqs_n(DDR_dqs_n),
    .DDR_dqs_p(DDR_dqs_p),
    .DDR_odt(DDR_odt),
    .DDR_ras_n(DDR_ras_n),
    .DDR_reset_n(DDR_reset_n),
    .DDR_we_n(DDR_we_n),
    .FIXED_IO_ddr_vrn(FIXED_IO_ddr_vrn),
    .FIXED_IO_ddr_vrp(FIXED_IO_ddr_vrp),
    .FIXED_IO_mio(FIXED_IO_mio),
    .FIXED_IO_ps_clk(FIXED_IO_ps_clk),
    .FIXED_IO_ps_porb(FIXED_IO_ps_porb),
    .FIXED_IO_ps_srstb(FIXED_IO_ps_srstb),
    .M_CTRL_AXI_araddr(ctrl_if.araddr),
    .M_CTRL_AXI_arprot(3'b000),
    .M_CTRL_AXI_arready(ctrl_if.arready),
    .M_CTRL_AXI_arvalid(ctrl_if.arvalid),
    .M_CTRL_AXI_awaddr(ctrl_if.awaddr),
    .M_CTRL_AXI_awprot(3'b000),
    .M_CTRL_AXI_awready(ctrl_if.awready),
    .M_CTRL_AXI_awvalid(ctrl_if.awvalid),
    .M_CTRL_AXI_bready(ctrl_if.bready),
    .M_CTRL_AXI_bresp(ctrl_if.bresp),
    .M_CTRL_AXI_bvalid(ctrl_if.bvalid),
    .M_CTRL_AXI_rdata(ctrl_if.rdata),
    .M_CTRL_AXI_rready(ctrl_if.rready),
    .M_CTRL_AXI_rresp(ctrl_if.rresp),
    .M_CTRL_AXI_rvalid(ctrl_if.rvalid),
    .M_CTRL_AXI_wdata(ctrl_if.wdata),
    .M_CTRL_AXI_wready(ctrl_if.wready),
    .M_CTRL_AXI_wstrb(ctrl_if.wstrb),
    .M_CTRL_AXI_wvalid(ctrl_if.wvalid),
    .S_DDR_AXI_araddr(ddr_if.araddr),
    .S_DDR_AXI_arprot(3'b000),
    .S_DDR_AXI_arready(ddr_if.arready),
    .S_DDR_AXI_arvalid(ddr_if.arvalid),
    .S_DDR_AXI_awaddr(ddr_if.awaddr),
    .S_DDR_AXI_awprot(3'b000),
    .S_DDR_AXI_awready(ddr_if.awready),
    .S_DDR_AXI_awvalid(ddr_if.awvalid),
    .S_DDR_AXI_bready(ddr_if.bready),
    .S_DDR_AXI_bresp(ddr_if.bresp),
    .S_DDR_AXI_bvalid(ddr_if.bvalid),
    .S_DDR_AXI_rdata(ddr_if.rdata),
    .S_DDR_AXI_rready(ddr_if.rready),
    .S_DDR_AXI_rresp(ddr_if.rresp),
    .S_DDR_AXI_rvalid(ddr_if.rvalid),
    .S_DDR_AXI_wdata(ddr_if.wdata),
    .S_DDR_AXI_wready(ddr_if.wready),
    .S_DDR_AXI_wstrb(ddr_if.wstrb),
    .S_DDR_AXI_wvalid(ddr_if.wvalid)
);

endmodule
