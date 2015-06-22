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

`include "mips_define.vh"

reg [LINE_NUMBER - 1 : 0] inner_valid = 0;
reg [LINE_NUMBER - 1 : 0] inner_dirty = 0;
reg [TAG_BITS - 1 : 0] inner_tag[0 : LINE_NUMBER - 1];
reg [WORD_BITS - 1 : 0] inner_data[0 : LINE_NUMBER * LINE_WORDS - 1];

initial begin
    tag = 0;
    inner_valid = 0;
    inner_dirty = 0;
end

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
end

// always @(*)
// this issue is fixed on spartan6
// to avoid "always block sensitivity list" error
always @(
    inner_tag[0], inner_tag[1], inner_tag[2], inner_tag[3], 
    inner_tag[4], inner_tag[5], inner_tag[6], inner_tag[7],
    inner_tag[8], inner_tag[9], inner_tag[10], inner_tag[11], 
    inner_tag[12], inner_tag[13], inner_tag[14], inner_tag[15],
    inner_tag[16], inner_tag[17], inner_tag[18], inner_tag[19], 
    inner_tag[20], inner_tag[21], inner_tag[22], inner_tag[23],
    inner_tag[24], inner_tag[25], inner_tag[26], inner_tag[27], 
    inner_tag[28], inner_tag[29], inner_tag[30], inner_tag[31],
    inner_tag[32], inner_tag[33], inner_tag[34], inner_tag[35], 
    inner_tag[36], inner_tag[37], inner_tag[38], inner_tag[39],
    inner_tag[40], inner_tag[41], inner_tag[42], inner_tag[43], 
    inner_tag[44], inner_tag[45], inner_tag[46], inner_tag[47],
    inner_tag[48], inner_tag[49], inner_tag[50], inner_tag[51], 
    inner_tag[52], inner_tag[53], inner_tag[54], inner_tag[55],
    inner_tag[56], inner_tag[57], inner_tag[58], inner_tag[59], 
    inner_tag[60], inner_tag[61], inner_tag[62], inner_tag[63]
) begin
    tag <= inner_tag[addr[ADDRESS_BITS - TAG_BITS - 1 : LINE_WORDS_WIDTH + WORD_BYTES_WIDTH]];
end

always @(*) begin
    hit <= valid && (tag == addr[ADDRESS_BITS - 1 : ADDRESS_BITS - TAG_BITS]);
end
endmodule
