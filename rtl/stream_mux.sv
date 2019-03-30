`timescale 1 ns / 1 ps
`default_nettype none

module stream_mux #(
    parameter NUM_DATA = 8,
    parameter INPUT_DATA_WIDTH = 8,
    parameter OUTPUT_DATA_WIDTH = 64
) (
    input var logic clk_i,
    input var logic rst_i,
    input var logic [NUM_DATA - 1 : 0 ] valid_i,
    output var logic ready_o,
    input var logic [NUM_DATA - 1 : 0][INPUT_DATA_WIDTH - 1 : 0] data_i,
    output var logic valid_o,
    input var logic ready_i,
    output var logic [OUTPUT_DATA_WIDTH - 1 : 0] data_o
);

localparam NUM_OUTPUT_WORDS = OUTPUT_DATA_WIDTH / INPUT_DATA_WIDTH;

logic [2 * OUTPUT_DATA_WIDTH - 1 : 0] data_shift_next;
logic [2 * OUTPUT_DATA_WIDTH - 1 : 0] data_shift_r;
logic [NUM_DATA - 1 : 0] valid_r [NUM_DATA];
logic [NUM_DATA - 1 : 0][INPUT_DATA_WIDTH - 1 : 0] data_r [NUM_DATA];
logic [NUM_DATA - 1 : 0] shift [NUM_DATA];
logic [3 * OUTPUT_DATA_WIDTH - 1 : 0] data_shift_int;
logic [$clog2(NUM_DATA) - 1 : 0] valid_count;
logic [$clog2(NUM_DATA) - 1 : 0] valid_count_r;
logic [$clog2(2 * NUM_OUTPUT_WORDS) - 1 : 0] buf_ptr_r;

always_comb begin
    for (int i = 0; i < NUM_DATA; i = i + 1) begin
        for (int j = 0; j < NUM_DATA; j = j + 1) begin
            shift[i][j] = 1;
            for (int k = 0; k <= j; k = k + 1) begin
                shift[i][j] = shift[i][j] && valid_r[j][k];
            end
            shift[i][j] = !shift[i][j];
        end
    end
end

always_comb begin
    data_shift_int = {data_r[NUM_DATA - 1], data_shift_r};
    data_shift_next = data_shift_int >> (valid_count_r * INPUT_DATA_WIDTH);
end

always_comb begin
    valid_count = 0;
    for (int j = 0; j < NUM_DATA; j = j + 1) begin
        valid_count = valid_count + valid_r[NUM_DATA - 2][j];
    end
end

always_ff @(posedge clk_i) begin
    if (rst_i) begin
        buf_ptr_r <= 0;
    end else if (ready_o) begin
        valid_o <= buf_ptr_r >= NUM_OUTPUT_WORDS;
        buf_ptr_r <= ((buf_ptr_r >= NUM_OUTPUT_WORDS) ? (buf_ptr_r - NUM_OUTPUT_WORDS) : buf_ptr_r)
                + valid_count_r;
    end
end

always_ff @(posedge clk_i) begin
    if (ready_o) begin
        data_r[0] <= data_i;
        valid_r[0] <= valid_i;
        data_shift_r <= data_shift_next;
        valid_count_r <= valid_count;

        for (int i = 1; i < NUM_DATA; i = i + 1) begin
            for (int j = 0; j < NUM_DATA; j = j + 1) begin
                if (j <= (NUM_DATA - 1 - i)) begin
                    valid_r[i][j] <= shift[i][j] ? valid_r[i - 1][j + 1] : valid_r[i - 1][j];
                    data_r[i][j] <= shift[i][j] ? data_r[i - 1][j + 1] : data_r[i - 1][j];
                end else begin
                    valid_r[i][j] <= valid_r[i - 1][j];
                    data_r[i][j] <= data_r[i - 1][j];
                end
            end
        end
    end
end

assign ready_o = !valid_o || ready_i;
assign data_o = data_shift_r[2 * OUTPUT_DATA_WIDTH - buf_ptr_r * INPUT_DATA_WIDTH +: OUTPUT_DATA_WIDTH];

endmodule

`default_nettype wire