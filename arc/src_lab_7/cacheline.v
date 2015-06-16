module cacheline(
    input wire clk,
    input wire rst,
    input wire [31:0] addr,
    input wire load,
    input wire edit,
    input wire invalid,
    input wire [31:0] din,
    output reg hit,
    output reg valid,
    output reg dirty,
    output reg [21:0] tag,
    output reg [31:0] dout
);

localparam
    LINE_WORDS = 4,
    LINE_WORDS_WIDTH = 2,
    WORD_BITS = 32,
    TAG_BITS = 22,
    ADDRESS_BITS = 32,
    LINE_INDEX_WIDTH = 6,
    LINE_NUMBER = 64,
    WORD_BYTES_WIDTH = 2;

reg [LINE_NUMBER - 1 : 0] inner_valid = 0;
reg [LINE_NUMBER - 1 : 0] inner_dirty = 0;
reg [TAG_BITS - 1 : 0] inner_tag[0 : LINE_NUMBER - 1];
reg [WORD_BITS - 1 : 0] inner_data[0 : LINE_NUMBER * LINE_WORDS - 1];

always @(posedge clk) begin
    dout <= inner_data[addr[ADDRESS_BITS - TAG_BITS - 1 : WORD_BYTES_WIDTH]];
end

always @(posedge clk) begin
    if ((hit && edit) || (load)) begin
        inner_data[addr[ADDRESS_BITS - TAG_BITS - 1 : WORD_BYTES_WIDTH]] <= din;
    end
end

always @(*) begin
    if (invalid) begin
        inner_valid[addr[ADDRESS_BITS - TAG_BITS - 1 : LINE_WORDS_WIDTH + WORD_BYTES_WIDTH]] <= 0;
        inner_dirty[addr[ADDRESS_BITS - TAG_BITS - 1 : LINE_WORDS_WIDTH + WORD_BYTES_WIDTH]] <= 0;
    end
    else if (load) begin
        inner_valid[addr[ADDRESS_BITS - TAG_BITS - 1 : LINE_WORDS_WIDTH + WORD_BYTES_WIDTH]] <= 1;
        inner_dirty[addr[ADDRESS_BITS - TAG_BITS - 1 : LINE_WORDS_WIDTH + WORD_BYTES_WIDTH]] <= 0;
        inner_tag[addr[ADDRESS_BITS - TAG_BITS - 1 : LINE_WORDS_WIDTH + WORD_BYTES_WIDTH]] <= addr[ADDRESS_BITS - 1 : ADDRESS_BITS - TAG_BITS];
    end
    else if (edit) begin
        inner_dirty[addr[ADDRESS_BITS - TAG_BITS - 1 : LINE_WORDS_WIDTH + WORD_BYTES_WIDTH]] <= 1;
        inner_tag[addr[ADDRESS_BITS - TAG_BITS - 1 : LINE_WORDS_WIDTH + WORD_BYTES_WIDTH]] <= addr[ADDRESS_BITS - 1 : ADDRESS_BITS - TAG_BITS];
    end
end

always @(*) begin
    valid <= inner_valid[addr[ADDRESS_BITS - TAG_BITS - 1 : LINE_WORDS_WIDTH + WORD_BYTES_WIDTH]];
    dirty <= inner_dirty[addr[ADDRESS_BITS - TAG_BITS - 1 : LINE_WORDS_WIDTH + WORD_BYTES_WIDTH]];
    tag <= inner_tag[addr[ADDRESS_BITS - TAG_BITS - 1 : LINE_WORDS_WIDTH + WORD_BYTES_WIDTH]];
end

always @(*) begin
    hit <= valid && (tag == addr[ADDRESS_BITS - 1 : ADDRESS_BITS - TAG_BITS]);
end
endmodule
