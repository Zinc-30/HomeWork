`include "define.vh"

/**
 * MIPS 5-stage pipeline CPU Core, including data path and co-processors.
 * Author: Zhao, Hongyu, Zhejiang University
 */

module mips_core (
	input wire clk,  // main clock
	input wire rst,  // synchronous reset
	// debug
	`ifdef DEBUG
	input wire debug_en,  // debug enable
	input wire debug_step,  // debug step clock
	input wire [5:0] debug_addr,  // debug address
	output wire [31:0] debug_data,  // debug data
	`endif
	// instruction interfaces
	output wire inst_ren,  // instruction read enable signal
	output wire [31:0] inst_addr,  // address of instruction needed
	input wire [31:0] inst_data,  // instruction fetched
	// memory interfaces
	output wire mem_ren,  // memory read enable signal
	output wire mem_wen,  // memory write enable signal
	output wire [31:0] mem_addr,  // address of memory
	output wire [31:0] mem_dout,  // data writing to memory
	input wire [31:0] mem_din  // data read from memory
	);
	
	// control signals
	wire [31:0] inst_data_ctrl;
	
	wire imm_ext_ctrl;
	wire [1:0] exe_b_src_ctrl;
	wire exe_a_src_ctrl;
	wire [4:0] exe_alu_oper_ctrl;
	wire mem_ren_ctrl;
	wire mem_wen_ctrl;
	wire [1:0] wb_addr_src_ctrl;
	wire wb_data_src_ctrl;
	wire wb_wen_ctrl;
    wire [1:0] pc_src_ctrl;
	
	wire reg_stall;
	wire if_rst, if_en, if_valid;
	wire id_rst, id_en, id_valid;
	wire exe_rst, exe_en, exe_valid;
	wire mem_rst, mem_en, mem_valid;
	wire wb_rst, wb_en, wb_valid;

    wire [2:0] fwd_a, fwd_b;
    wire fwd_m;
    wire is_load_ctrl, is_load_exe;
    wire is_store_ctrl, is_store_exe, is_store_mem;
    wire rs_rt_equal;
    wire wb_wen_exe, wb_wen_mem, wb_wen_wb;
    wire [4:0] addr_rt_mem, regw_addr_exe, regw_addr_mem, regw_addr_wb;
	
	// controller
	controller CONTROLLER (
		.clk(clk),
		.rst(rst),
		`ifdef DEBUG
		.debug_en(debug_en),
		.debug_step(debug_step),
		`endif
        // instruction decode
		.inst(inst_data_ctrl),
        .rs_rt_equal(rs_rt_equal),
        .is_load_exe(is_load_exe),
        .is_store_exe(is_store_exe),
        .regw_addr_exe(regw_addr_exe),
        .wb_wen_exe(wb_wen_exe),
        .is_load_mem(is_load_mem),
        .is_store_mem(is_store_mem),
        .addr_rt_mem(addr_rt_mem),
        .regw_addr_mem(regw_addr_mem),
        .wb_wen_mem(wb_wen_mem),
        .regw_addr_wb(regw_addr_wb),
        .wb_wen_wb(wb_wen_wb),

		.imm_ext(imm_ext_ctrl),
		.exe_b_src(exe_b_src_ctrl),
		.exe_a_src(exe_a_src_ctrl),
		.exe_alu_oper(exe_alu_oper_ctrl),
		.mem_ren(mem_ren_ctrl),
		.mem_wen(mem_wen_ctrl),
		.wb_addr_src(wb_addr_src_ctrl),
		.wb_data_src(wb_data_src_ctrl),
		.wb_wen(wb_wen_ctrl),
        .pc_src(pc_src_ctrl),
		.unrecognized(),

        .is_load(is_load_ctrl),
        .is_store(is_store_ctrl),
        .fwd_a(fwd_a),
        .fwd_b(fwd_b),
        .fwd_m(fwd_m),

		.if_rst(if_rst),
		.if_en(if_en),
		.if_valid(if_valid),
        
		.id_rst(id_rst),
		.id_en(id_en),
		.id_valid(id_valid),

		.exe_rst(exe_rst),
		.exe_en(exe_en),
		.exe_valid(exe_valid),

		.mem_rst(mem_rst),
		.mem_en(mem_en),
		.mem_valid(mem_valid),

		.wb_rst(wb_rst),
		.wb_en(wb_en),
		.wb_valid(wb_valid)
	);
	
	// data path
	datapath DATAPATH (
		.clk(clk),
		`ifdef DEBUG
		.debug_addr(debug_addr),
		.debug_data(debug_data),
		`endif
		.inst_data_ctrl(inst_data_ctrl),
        .rs_rt_equal(rs_rt_equal),
        .is_load_exe(is_load_exe),
        .is_store_exe(is_store_exe),
        .regw_addr_exe(regw_addr_exe),
        .wb_wen_exe(wb_wen_exe),
        .is_load_mem(is_load_mem),
        .is_store_mem(is_store_mem),
        .addr_rt_mem(addr_rt_mem),
        .regw_addr_mem(regw_addr_mem),
        .wb_wen_mem(wb_wen_mem),
        .regw_addr_wb(regw_addr_wb),
        .wb_wen_wb(wb_wen_wb),

        .pc_src_ctrl(pc_src_ctrl),
		.imm_ext_ctrl(imm_ext_ctrl),
		.exe_a_src_ctrl(exe_a_src_ctrl),
		.exe_b_src_ctrl(exe_b_src_ctrl),
		.exe_alu_oper_ctrl(exe_alu_oper_ctrl),
		.mem_ren_ctrl(mem_ren_ctrl),
		.mem_wen_ctrl(mem_wen_ctrl),
		.wb_addr_src_ctrl(wb_addr_src_ctrl),
		.wb_data_src_ctrl(wb_data_src_ctrl),
		.wb_wen_ctrl(wb_wen_ctrl),
        .fwd_a_ctrl(fwd_a),
        .fwd_b_ctrl(fwd_b),
        .fwd_m_ctrl(fwd_m),
        .is_load_ctrl(is_load_ctrl),
        .is_store_ctrl(is_store_ctrl),

        // IF signals
		.if_rst(if_rst),
		.if_en(if_en),
		.if_valid(if_valid),
		.inst_ren(inst_ren),
		.inst_addr(inst_addr),
		.inst_data(inst_data),
        // ID signals
		.id_rst(id_rst),
		.id_en(id_en),
		.id_valid(id_valid),
        // EXE signals
		.exe_rst(exe_rst),
		.exe_en(exe_en),
		.exe_valid(exe_valid),
        // MEM signals
		.mem_rst(mem_rst),
		.mem_en(mem_en),
		.mem_valid(mem_valid),
		.mem_ren(mem_ren),
		.mem_wen(mem_wen),
		.mem_addr(mem_addr),
		.mem_dout(mem_dout),
		.mem_din(mem_din),
        // WB signals
		.wb_rst(wb_rst),
		.wb_en(wb_en),
		.wb_valid(wb_valid)
	);
	
endmodule
