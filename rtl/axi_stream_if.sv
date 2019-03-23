interface axi_stream_if #(
    DATA_WIDTH = 32,
    ID_WIDTH = 1,
    DEST_WIDTH = 1,
    USER_WIDTH = 1
);
    localparam STRB_WIDTH = DATA_WIDTH / 8;

    logic aclk;
    logic aresetn;
    logic tvalid;
    logic tready;
    logic [DATA_WIDTH - 1 : 0] tdata;
    logic [STRB_WIDTH - 1 : 0] tstrb;
    logic [STRB_WIDTH - 1 : 0] tkeep;
    logic tlast;
    logic [ID_WIDTH - 1 : 0] tid;
    logic [DEST_WIDTH - 1 : 0] tdest;
    logic [USER_WIDTH - 1 : 0] tuser;

    modport slave (
        input aclk, aresetn,
        input tvalid, output tready,
        input tdata, tstrb, tkeep, tlast, tid, tdest, tuser
    );

    modport master (
        input aclk, aresetn,
        output tvalid, input tready,
        output tdata, tstrb, tkeep, tlast, tid, tdest, tuser
    );

endinterface