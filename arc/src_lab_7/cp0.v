`include "define.vh"

module cp0 (
    input wire clk, // main clock
    // debug
    `ifdef DEBUG
    input wire [4:0] debug_addr, // debug address
    output reg [31:0] debug_data, // debug data
    `endif
    // operations (read in ID stage and write in EXE stage)
    input wire [1:0] oper, // CP0 operation type
    input wire [4:0] addr_r, // read address
    output reg [31:0] data_r, // read data
    input wire [4:0] addr_w, // write address
    input wire [31:0] data_w, // write data
    // control signal
    input wire rst, // synchronous reset
    input wire ir_en, // interrupt enable
    input wire ir_in, // external interrupt input
    input wire [31:0] ret_addr, // target instruction address to store when interrupt occurred
    output reg jump_en, // force jump enable signal when interrupt authorised or ERET occurred
    output reg [31:0] jump_addr, // target instruction address to jump to
    output wire ir
);

`include "mips_define.vh"
// interrupt determination
//wire ir;
reg ir_wait, ir_valid;
reg eret;
initial begin
    ir_wait = 0;
    ir_valid = 1;
    eret = 0;
end
reg [31:0] regfile [0:31];

always @(posedge clk) begin
    if (rst) begin
        ir_wait = 0;
    end 
    else if (ir_en) begin
        if (ir_in) begin
            ir_wait = 1;
        end
        else if (eret) begin
            ir_wait = 0;
        end
    end
end

always @(posedge clk) begin
    if(rst) begin
        ir_valid = 1;
    end 
    else if (ir_en) begin
        if (eret) begin
            ir_valid = 1;
        end
        else if (ir) begin
            ir_valid = 0; // prevent exception reenter
        end
    end
end

assign ir = ir_en & ir_wait & ir_valid;
//assign ir = ir_wait & ir_valid;
//assign ir = clk;
// CP0 operations(read at id stage)
always @(negedge clk) begin
    data_r <= regfile[addr_r];
end

// CP0 operations(write at exe stage)
always @(posedge clk) begin
    if (rst) begin
        jump_en <= 0;
        jump_addr <= 0;
        eret <= 0;
    end
	else if (ir) begin
        jump_en <= 1;
        jump_addr <= regfile[CP0_EHBR];
    end
    else if (ir_en) begin
        case (oper) 
            EXE_CP_NONE: begin
                jump_en <= 0;
                eret <= 0;
            end
            EXE_CP_STORE: begin
                eret <= 0;
                if (addr_w != CP0_EPCR) begin
                    regfile[addr_w] <= data_w;
                end
            end
            EXE_CP0_ERET: begin
                jump_en <= 1;
                jump_addr <= regfile[CP0_EPCR];
                eret <= 1;
            end
        endcase
    end
    if (jump_en && eret) begin
        regfile[CP0_EPCR] <= 0;
    end
    else if (jump_en) begin
        regfile[CP0_EPCR] <= ret_addr;
    end
end


// debug
`ifdef DEBUG
always @(negedge clk) begin
    debug_data <= regfile[debug_addr];
end
`endif

endmodule
