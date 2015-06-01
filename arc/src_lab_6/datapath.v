`include "define.vh"

/**
 * Data Path for MIPS 5-stage pipelined CPU.
 * Author: Zhao, Hongyu, Zhejiang University
 */
 
module datapath (
	input wire clk,  // main clock
	// debug
	`ifdef DEBUG
	input wire [5:0] debug_addr,  // debug address
	output wire [31:0] debug_data,  // debug data
	`endif
	// control signals
	output reg [31:0] inst_data_ctrl,  // instruction
    output reg rs_rt_equal,
    output reg is_load_exe,
    output reg is_store_exe,
    output reg [4:0] regw_addr_exe,
    output reg wb_wen_exe,
    output reg is_load_mem,
    output reg is_store_mem,
    output reg [4:0] addr_rt_mem,
    output reg [4:0] regw_addr_mem,
    output reg wb_wen_mem,
    output reg [4:0] regw_addr_wb,
    output reg wb_wen_wb,

    input wire [1:0] pc_src_ctrl,
	input wire imm_ext_ctrl,  // whether using sign extended to immediate data
	input wire exe_a_src_ctrl,
	input wire [1:0] exe_b_src_ctrl,  // data source of operand B for ALU

	input wire [4:0] exe_alu_oper_ctrl,  // ALU operation type


	input wire mem_ren_ctrl,  // memory read enable signal
	input wire mem_wen_ctrl,  // memory write enable signal
	input wire [1:0] wb_addr_src_ctrl,  // address source to write data back to registers
	input wire wb_data_src_ctrl,  // data source of data being written back to registers
	input wire wb_wen_ctrl,  // register write enable signal
    input wire [2:0] fwd_a_ctrl,
    input wire [2:0] fwd_b_ctrl,
    input wire fwd_m_ctrl,
    input wire is_load_ctrl,
    input wire is_store_ctrl,
	
	// IF signals
	input wire if_rst,  // stage reset signal
	input wire if_en,  // stage enable signal
	output reg if_valid,  // working flag
	output reg inst_ren,  // instruction read enable signal
	output reg [31:0] inst_addr,  // address of instruction needed
	input wire [31:0] inst_data,  // instruction fetched
	// ID signals
	input wire id_rst,
	input wire id_en,
	output reg id_valid,
	// EXE signals
	input wire exe_rst,
	input wire exe_en,
	output reg exe_valid,
	// MEM signals
	input wire mem_rst,
	input wire mem_en,
	output reg mem_valid,
	output wire mem_ren,  // memory read enable signal
	output wire mem_wen,  // memory write enable signal
	output wire [31:0] mem_addr,  // address of memory
	output wire [31:0] mem_dout,  // data writing to memory
	input wire [31:0] mem_din,  // data read from memory
	// WB signals
	input wire wb_rst,
	input wire wb_en,
	output reg wb_valid,
    // CP0 control signal
    output wire epc_ctrl,
    input wire [1:0] cp_oper,
    input wire interrupt
	);
	
	`include "mips_define.vh"
	
	// control signals
	reg [4:0] exe_alu_oper_exe;
	reg mem_ren_exe, mem_ren_mem;
	reg mem_wen_exe, mem_wen_mem;
	reg wb_data_src_exe, wb_data_src_mem;
	
	
	// IF signals
	wire [31:0] inst_addr_next;
	
	// ID signals
	reg [31:0] inst_addr_id;
	reg [31:0] inst_addr_next_id;
	reg [4:0] regw_addr_id;
	wire [4:0] addr_rs, addr_rt;
	wire [31:0] data_rs, data_rt, data_imm;
	reg AFromEXLW,BFromEXLW;	
	
	// EXE signals
	reg [31:0] inst_addr_exe;
	reg [31:0] inst_data_exe;
	reg [31:0] inst_addr_next_exe;
	reg [31:0] data_rt_exe;
	wire [31:0] alu_a_exe, alu_b_exe;
	wire [31:0] alu_out_exe;
    reg [31:0] data_rs_fwd, data_rt_fwd;
    reg [4:0] addr_rs_exe, addr_rt_exe;
    reg [31:0] data_rs_exe, data_imm_exe;
    reg [1:0]exe_b_src_exe;
	 reg exe_a_src_exe;
	
	// MEM signals
	reg [31:0] inst_addr_mem;
	reg [31:0] inst_data_mem;
	reg [31:0] data_rt_mem;
	reg [31:0] alu_out_mem;
	reg [31:0] regw_data_mem;
	
	// WB signals
	reg [31:0] regw_data_wb;
    reg [4:0] regw_addr_final;
    reg [31:0] regw_data_final;
    reg wb_wen_final;

    // cp0 signals
    wire [31:0] epc, return_addr;
    wire [31:0] cpr_cs;
	
	// debug
	`ifdef DEBUG
	wire [31:0] debug_data_reg;
	reg [31:0] debug_data_signal;
	
	always @(posedge clk) begin
		case (debug_addr[4:0])
			0: debug_data_signal <= inst_addr;
			1: debug_data_signal <= inst_data;
			2: debug_data_signal <= inst_addr_id;
			3: debug_data_signal <= inst_data_ctrl;
			4: debug_data_signal <= inst_addr_exe;
			5: debug_data_signal <= inst_data_exe;
			6: debug_data_signal <= inst_addr_mem;
			7: debug_data_signal <= inst_data_mem;
			8: debug_data_signal <= {27'b0, addr_rs};
			9: debug_data_signal <= data_rs;
			10: debug_data_signal <= {27'b0, addr_rt};
			11: debug_data_signal <= data_rt;
			12: debug_data_signal <= data_imm;
			13: debug_data_signal <= alu_a_exe;
			14: debug_data_signal <= alu_b_exe;
			15: debug_data_signal <= alu_out_exe;
			16: debug_data_signal <= 0;
			17: debug_data_signal <= 0;
			18: debug_data_signal <= {19'b0, inst_ren, 7'b0, mem_ren, 3'b0, mem_wen};
			19: debug_data_signal <= mem_addr;
			20: debug_data_signal <= mem_din;
			21: debug_data_signal <= mem_dout;
			22: debug_data_signal <= {27'b0, regw_addr_wb};
			23: debug_data_signal <= regw_data_wb;
			default: debug_data_signal <= 32'hFFFF_FFFF;
		endcase
	end
	
	assign
		debug_data = debug_addr[5] ? debug_data_signal : debug_data_reg;
	`endif
	
	// IF stage
	assign
		inst_addr_next = inst_addr + 4;
	
	always @(posedge clk) begin
		if (if_rst) begin
			if_valid <= 0;
			inst_ren <= 0;
			inst_addr <= 0;
		end
		else if (if_en) begin
			if_valid <= 1;
			inst_ren <= 1;
            if (epc_ctrl == 1) begin
                inst_addr <= epc;
            end
            else begin
                case (pc_src_ctrl)
                    PC_NEXT: inst_addr <= inst_addr_next;
                    PC_JUMP: inst_addr <= {inst_addr_id[31:28],inst_data_ctrl[25:0], 2'b0};
                    PC_BRANCH: inst_addr <= inst_addr_next_id + {data_imm[29:0] , 2'b0};
                    PC_JR:inst_addr <= data_rs_fwd;
                endcase
            end
		end
	end
	
	// ID stage
	always @(posedge clk) begin
		if (id_rst) begin
			id_valid <= 0;
			inst_addr_id <= 0;
			inst_data_ctrl <= 0;
			inst_addr_next_id <= 0;
		end
		else if (id_en) begin
			id_valid <= if_valid;
			inst_addr_id <= inst_addr;
			inst_data_ctrl <= inst_data;
			inst_addr_next_id <= inst_addr_next;
		end
	end
	

   assign
        addr_rs = inst_data_ctrl[25:21],
        addr_rt = inst_data_ctrl[20:16],
        data_imm = imm_ext_ctrl ? (inst_data_ctrl[15] == 1 ? {16'hffff, inst_data_ctrl[15:0]} : {16'h0, inst_data_ctrl[15:0]}) : {16'h0, inst_data_ctrl[15:0]};
	
	always @(*) begin
		regw_addr_id = inst_data_ctrl[15:11];
		case (wb_addr_src_ctrl)
			WB_ADDR_RD: regw_addr_id = inst_data_ctrl[15:11];
			WB_ADDR_RT: regw_addr_id = inst_data_ctrl[20:16];
			WB_ADDR_LINK: regw_addr_id = 5'd31;
		endcase
	end

    assign return_addr = (pc_src_ctrl == 0) ? inst_addr : inst_addr_id;
	
	regfile REGFILE (
		.clk(clk),
		`ifdef DEBUG
		.debug_addr(debug_addr[4:0]),
		.debug_data(debug_data_reg),
		`endif
		.addr_a(addr_rs),
		.data_a(data_rs),
		.addr_b(addr_rt),
		.data_b(data_rt),
		.en_w(wb_wen_wb),
		.addr_w(regw_addr_wb),
		.data_w(regw_data_wb)
		);

	// CP0
    cp0 CP0(
        .clk(clk),
        `ifdef debug
        .debug_addr(), 
        .debug_data(),
        `endif
        .oper(cp_oper),
        .addr_r(inst_data_ctrl[15:11]),
        .data_r(cpr_cs),
        .addr_w(inst_data_ctrl[15:11]),
        .data_w(data_rt_fwd),
        .rst(rst),
        .ir_en(1'b1),
        .ir_in(interrupt),
        .ret_addr(return_addr),
        .jump_en(epc_ctrl),
        .jump_addr(epc)
    );


	always @(*) begin 
		data_rs_fwd = data_rs;
		data_rt_fwd = data_rt;
		case (fwd_a_ctrl)
            FWD_A_FROM_ID: data_rs_fwd = data_rs;
            FWD_A_FROM_EXE: data_rs_fwd = alu_out_exe;
            FWD_A_FROM_MEM: data_rs_fwd = alu_out_mem;
            FWD_A_FROM_DIN: data_rs_fwd = mem_din;
            FWD_A_FROM_WB: data_rs_fwd = regw_data_wb;
		endcase
        case (fwd_b_ctrl)
            FWD_B_FROM_ID: data_rt_fwd = data_rt;
            FWD_B_FROM_EXE: data_rt_fwd = alu_out_exe;
            FWD_B_FROM_MEM: data_rt_fwd = alu_out_mem;
            FWD_B_FROM_DIN: data_rt_fwd = mem_din;
            FWD_B_FROM_WB: data_rt_fwd = regw_data_wb;
            FWD_B_FROM_CP0: data_rt_fwd = cpr_cs;
        endcase
        rs_rt_equal = (data_rs_fwd == data_rt_fwd);
	end
	
	// EXE stage
	always @(posedge clk) begin
		if (exe_rst) begin
			exe_valid <= 0;
			inst_addr_exe <= 0;
			inst_data_exe <= 0;
			regw_addr_exe <= 0;
			   exe_a_src_exe <= 0;
            exe_b_src_exe <= 0;
            addr_rs_exe <= 0;
            addr_rt_exe <= 0;
            data_rs_exe <= 0;
            data_rt_exe <= 0;
            data_imm_exe <= 0;
			exe_alu_oper_exe <= 0;
			mem_ren_exe <= 0;
			mem_wen_exe <= 0;
			wb_data_src_exe <= 0;
			wb_wen_exe <= 0;
            is_load_exe <= 0;
            is_store_exe <= 0;
            inst_addr_next_exe <= 0;
		end
		else if (exe_en) begin
			exe_valid <= id_valid;
			inst_addr_exe <= inst_addr_id;
			inst_addr_next_exe <= inst_addr_next_id;
			inst_data_exe <= inst_data_ctrl;
			regw_addr_exe <= regw_addr_id;
			exe_a_src_exe <= exe_a_src_ctrl;
            exe_b_src_exe <= exe_b_src_ctrl;
            addr_rs_exe <= addr_rs;
            addr_rt_exe <= addr_rt;
            data_rs_exe <= data_rs_fwd;
            data_rt_exe <= data_rt_fwd;
            data_imm_exe <= data_imm;
			exe_alu_oper_exe <= exe_alu_oper_ctrl;
			mem_ren_exe <= mem_ren_ctrl;
			mem_wen_exe <= mem_wen_ctrl;
			wb_data_src_exe <= wb_data_src_ctrl;
			wb_wen_exe <= wb_wen_ctrl;
            is_load_exe <= is_load_ctrl;
            is_store_exe <= is_store_ctrl;
		end
	end

	assign alu_a_exe = exe_a_src_exe ? inst_addr_next_exe:data_rs_exe;
    assign alu_b_exe = exe_b_src_exe[1] ? 4:(exe_b_src_exe[0] ? data_imm_exe : data_rt_exe);
		
	alu ALU (
		.inst(inst_data_exe),
		.a(alu_a_exe),
		.b(alu_b_exe),
		.oper(exe_alu_oper_exe),
		.result(alu_out_exe)
		);
	
	// MEM stage
	always @(posedge clk) begin
		if (mem_rst) begin
			mem_valid <= 0;
			inst_addr_mem <= 0;
			inst_data_mem <= 0;
			regw_addr_mem <= 0;
			data_rt_mem <= 0;
			alu_out_mem <= 0;
			mem_ren_mem <= 0;
			mem_wen_mem <= 0;
			wb_data_src_mem <= 0;
			wb_wen_mem <= 0;
            is_load_mem <= 0;
            is_store_mem <= 0;
		end
		else if (mem_en) begin
			mem_valid <= exe_valid;
			inst_addr_mem <= inst_addr_exe;
			inst_data_mem <= inst_data_exe;
			regw_addr_mem <= regw_addr_exe;
			data_rt_mem <= data_rt_exe;
			alu_out_mem <= alu_out_exe;
			mem_ren_mem <= mem_ren_exe;
			mem_wen_mem <= mem_wen_exe;
			wb_data_src_mem <= wb_data_src_exe;
			wb_wen_mem <= wb_wen_exe;
            is_load_mem <= is_load_exe;
            is_store_mem <= is_store_exe;
		end
	end

	always @(*) begin
		regw_data_mem = alu_out_mem;
		case (wb_data_src_mem)
			WB_DATA_ALU: regw_data_mem = alu_out_mem;
			WB_DATA_MEM: regw_data_mem = mem_din;
		endcase
	end
	
	assign
		mem_ren = mem_ren_mem,
		mem_wen = mem_wen_mem,
		mem_addr = alu_out_mem,
        mem_dout = fwd_m_ctrl ? regw_data_wb : data_rt_mem;//forwarding

// WB stage		
    always @(posedge clk) begin
        if (wb_rst) begin
            wb_valid <= 0;
            wb_wen_wb <= 0;
            regw_addr_wb <= 0;
            regw_data_wb <= 0;
        end
        else if (wb_en) begin
            wb_valid <= mem_valid;
            wb_wen_wb <= wb_wen_mem;
            regw_addr_wb <= regw_addr_mem;
            regw_data_wb <= regw_data_mem;
        end
    end

    always @(*) begin
        wb_wen_final = wb_wen_mem & wb_en;
        regw_addr_final = regw_addr_mem;
        regw_data_final = regw_data_mem;
    end

endmodule
