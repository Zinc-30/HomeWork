module cmu (
    input wire clk,  // input clock, 50MHz
    input wire rst,
    //cpu intface
    input wire [31:0] addr_rw,
    input wire en_r,
    output reg [31:0] data_r,
    input wire en_w,
    input wire [31:0] data_w,
    output wire stall,
    //mem intface
    output reg mem_cs_o,//?
    output reg mem_we_o,
    output reg [31:0] mem_addr_o,
    input wire [31:0] mem_data_i,
    output reg [31:0] mem_data_o,
    input wire mem_ack_i
);

`include "mips_define.vh"

localparam
    S_IDLE = 0,
    S_BACK = 1,
    S_BACK_WAIT = 2,
    S_FILL = 3,
    S_FILL_WAIT = 4,
	 S_FILL_EX = 5;



reg [2:0] state,next_state;
reg [1:0] word_count, next_word_count;

reg [31:0] cache_addr, cache_din;
reg cache_edit, cache_store;
wire [31:0] cache_dout;
wire cache_hit, cache_valid, cache_dirty;
wire [21:0] cache_tag;

reg [31:0] mem_data_syn;
reg mem_ack_syn;

initial begin
    cache_addr <= 0;
	 state <= 0;
end

always @(posedge clk) begin
    case(state) 
        S_IDLE: begin
            if (en_r || en_w) begin
                if (cache_hit) begin
                    next_state = S_IDLE;
                end
                else if (cache_valid && cache_dirty) begin
                    next_word_count = 0;
                    next_state = S_BACK;
                end
                else begin
                    next_word_count = 0;
                    next_state = S_FILL;
                end
            end
        end
        S_BACK: begin
            if (mem_ack_i)
                next_word_count = word_count + 1'h1;
            else
                next_word_count = word_count;
            if (mem_ack_i && word_count == {LINE_WORDS_WIDTH{1'b1}})
                next_state = S_BACK_WAIT;
            else
                next_state = S_BACK;
        end
        S_BACK_WAIT: begin
            next_word_count = 0;
            next_state = S_FILL;
        end
        S_FILL: begin
            if (mem_ack_i)
                next_word_count = word_count + 1'h1;
            else
                next_word_count = word_count;
            if (mem_ack_i && word_count == {LINE_WORDS_WIDTH{1'b1}})
                next_state = S_FILL_WAIT;
            else
                next_state = S_FILL;
        end
        S_FILL_WAIT: begin
            next_word_count = 0;
            next_state = S_FILL_EX;
        end
		  S_FILL_EX: begin
				next_state = S_IDLE;
		  end
    endcase
end

//Perform State Assignment
always @(posedge clk) begin
    if (rst) begin
        state <= 0;
        word_count <= 0;
    end
    else begin
        state <= next_state;
        word_count <= next_word_count;
    end 
end

always @(*) begin
    //cpu intface
    mem_data_syn = mem_data_i;
    mem_ack_syn = mem_ack_i;
    case (next_state)
        S_IDLE: begin
            cache_addr = addr_rw;
            cache_edit = en_w;
            cache_din = data_w;
            cache_store = 0;
            if (cache_hit) begin
                data_r = cache_dout;
            end
        end
        S_BACK, S_BACK_WAIT, S_FILL_EX: begin
            cache_addr = {addr_rw[31:LINE_WORDS_WIDTH+2], next_word_count,2'b00};
        end
        S_FILL, S_FILL_WAIT, S_FILL_EX: begin
            cache_addr = {addr_rw[31:LINE_WORDS_WIDTH+2], word_count,2'b00};
            //cache_din = mem_data_syn;
            cache_din = mem_data_i;
            cache_store = mem_ack_syn;
        end
    endcase
    //mem intface
    case (next_state)
        S_IDLE, S_BACK_WAIT, S_FILL_WAIT, S_FILL_EX: begin
            mem_cs_o <= 0;
            mem_we_o <= 0;
            mem_addr_o <= 0;
        end
        S_BACK: begin
            mem_cs_o <= 1;
            mem_we_o <= 1;
            mem_addr_o <= {cache_tag, addr_rw[31-TAG_BITS:LINE_WORDS_WIDTH+2], next_word_count, 2'b00};
            mem_data_o <= cache_dout;
        end
        S_FILL: begin
            mem_cs_o <= 1;
            mem_we_o <= 0;
            mem_addr_o <= {addr_rw[31:LINE_WORDS_WIDTH+2],next_word_count, 2'b00};

        end
    endcase
end

//cache
cacheline CACHELINE(
    .clk(clk),
    .rst(rst),
    .addr(cache_addr),
    .load(cache_store),
    .edit(cache_edit),
    .invalid(),
    .din(cache_din),
    .hit(cache_hit),
    .valid(cache_valid),
    .dirty(cache_dirty),
    .tag(cache_tag),
    .dout(cache_dout)
);

assign stall = (en_r | en_w) & !(cache_hit && state == S_IDLE);

endmodule
