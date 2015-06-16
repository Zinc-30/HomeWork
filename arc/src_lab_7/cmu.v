module cmu (
	input wire clk,  // input clock, 50MHz
	input wire rst,
	//cpu intface
	input wire [31:0] addr_rw,
	input wire en_w,
	input wire [31:0] data_w,
	input wire en_r,
	output wire [31:0] data_r,
	output wire stall,
	//mem intface
	output wire mem_cs_o,
	output wire mem_we_o,
	output wire [31:0] mem_addr_o,
	output wire [31:0] mem_data_o,
	input wire [31:0] mem_data_i,
	input wire mem_ack_i
	);
reg [2:0] state,next_state;
reg word_count,word_count_buf,next_word_count;
reg [31:0] cache_addr,cache_din,
reg cache_hit,cache_valid,

always @(posedge clk) begin
	case(state) begin
		S_IDLE: begin
		if (en_r || en_w) begin
			if (cache_hit)
				next_state = S_IDLE;
			else if (cache_valid && cache_dirty)
				next_state = S_BACK;
				else
				next_state = S_FILL;
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
			next_word_count <= 0;
			next_state <= S_IDLE;
		end
	end
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
//Output (1)
case (next_state)
S_IDLE: begin
	cache_addr = addr_rw;
	cache_edit = en_w;
	cache_din = data_w;
	end
S_BACK, S_BACK_WAIT: begin
	cache_addr = {addr_rw[31:LINE_WORDS_WIDTH+2], next_word_count,2'b00};
	end
S_FILL, S_FILL_WAIT: begin
	cache_addr = {addr_rw[31:LINE_WORDS_WIDTH+2], word_count_buf,2'b00};
	cache_din = mem_data_syn;
	cache_store = mem_ack_syn;
	end
endcase
//Output (2)
case (next_state)
S_IDLE, S_BACK_WAIT, S_FILL_WAIT: begin
	mem_cs_o <= 0;
	mem_we_o <= 0;
	mem_addr_o <= 0;
	end
S_BACK: begin
	mem_cs_o <= 1;
	mem_we_o <= 1;
	mem_addr_o <= {cache_tag, addr_rw[31-TAG_BITS:LINE_WORDS_WIDTH+2], next_word_count, 2'b00};
	end
S_FILL: begin
	mem_cs_o <= 1;
	mem_we_o <= 0;
	mem_addr_o <= {addr_rw[31:LINE_WORDS_WIDTH+2], 
	next_word_count, 2'b00};
	end
endcase

//cache