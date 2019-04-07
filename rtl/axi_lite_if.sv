interface axi_lite_if #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32
);
    localparam STRB_WIDTH = DATA_WIDTH / 8;

    // Clock and Reset
    logic aclk;
    logic aresetn;

    // Write Address Channel
    logic [ADDR_WIDTH - 1 : 0] awaddr;
    logic awvalid;
    logic awready;

    // Write Data Channel
    logic [DATA_WIDTH - 1 : 0] wdata;
    logic [STRB_WIDTH - 1 : 0] wstrb;
    logic wvalid;
    logic wready;

    // Read Address Channel
    logic [ADDR_WIDTH - 1: 0] araddr;
    logic arvalid;
    logic arready;

    // Read Data Channel
    logic [DATA_WIDTH - 1 : 0] rdata;
    logic [1 : 0] rresp;
    logic rvalid;
    logic rready;

    // Write Response Channel
    logic [1 : 0] bresp;
    logic bvalid;
    logic bready;

    modport slave (
        input aclk, aresetn,
        input awaddr, awvalid, output awready,
        input wdata, wstrb, wvalid, output wready,
        input araddr, arvalid, output arready,
        output rdata, rresp, rvalid, input rready,
        output bresp, bvalid, input bready
    );

    modport master (
        input aclk, aresetn,
        output awaddr, awvalid, input awready,
        output wdata, wstrb, wvalid, input wready,
        output araddr, arvalid, input arready,
        input rdata, rresp, rvalid, output rready,
        input bresp, bvalid, output bready
    );

endinterface
