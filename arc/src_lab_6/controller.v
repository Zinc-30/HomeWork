`include "define.vh"

/**
 * Controller for MIPS 5-stage pipelined CPU.
 * Author: Zhao, Hongyu, Zhejiang University
 */

module controller (/*AUTOARG*/
	input wire clk,  // main clock
	input wire rst,  // synchronous reset
	// debug
	`ifdef DEBUG
	input wire debug_en,  // debug enable
	input wire debug_step,  // debug step clock
	`endif
	// instruction decode
	input wire [31:0] inst,  // instruction
	input wire rs_rt_equal,//whether data from rs and rt are equal
	input wire is_load_exe,//whether instruction in EXE is lw
	inout wire is_store_exe,//whether instruction in EXE is sw
	input wire [4:0] regw_addr_exe, // register write address from EXE stage
	input wire wb_wen_exe, // register write enable signal feedback from EXE stage
	input wire is_load_mem, // whether instruction in MEM stage is LW
	input wire is_store_mem, // whether instruction in MEM stage is SW
	input wire [4:0] addr_rt_mem, // address of RT from MEM stage
	input wire [4:0] regw_addr_mem, // register write address from MEM stage
	input wire wb_wen_mem, // register write enable signal feedback from MEM stage
	input wire [4:0] regw_addr_wb, // register write address from WB stage
	input wire wb_wen_wb, // register write enable signal feedback from WB stage

	output reg imm_ext,  // whether using sign extended to immediate data
	output reg [1:0] exe_b_src,  // data source of operand B for ALU
	output reg exe_a_src,
	output reg [4:0] exe_alu_oper,  // ALU operation type
	output reg mem_ren,  // memory read enable signal
	output reg mem_wen,  // memory write enable signal
	output reg [1:0] wb_addr_src,  // address source to write data back to registers
	output reg wb_data_src,  // data source of data being written back to registers
	output reg wb_wen,  // register write enable signal
	output reg [1:0] pc_src, // how would Pc change to next
	//output reg is_branch,  // whether current instruction is a branch instruction
	//output reg rs_used,  // whether RS is used
	//output reg rt_used,  // whether RT is used
	output reg is_load, // whether current is lw
	output reg is_store, // whether current is sw
	output reg unrecognized,  // whether current instruction can not be recognized
	
	output reg [2:0] fwd_a,//forwarding selection for a
	output reg [2:0] fwd_b,//selection for b
	output reg fwd_m,//selection for memory
	// pipeline control
//	input wire reg_stall,  // stall signal when LW instruction followed by an related R instruction
	output reg if_rst,  // stage reset signal
	output reg if_en,  // stage enable signal
	input wire if_valid,  // stage valid flag

	output reg id_rst,
	output reg id_en,
	input wire id_valid,

	output reg exe_rst,
	output reg exe_en,
	input wire exe_valid,

	output reg mem_rst,
	output reg mem_en,
	input wire mem_valid,

	output reg wb_rst,
	output reg wb_en,
	input wire wb_valid,
    // CP0 control signal
    input wire jump_en,
    output reg [1:0] cp_oper
	);

    reg reg_stall;
    wire [4:0] addr_rs, addr_rt;
	
	`include "mips_define.vh"
	reg rs_used,rt_used;
	// instruction decode
	always @(*) begin
		imm_ext = 0;
		exe_b_src = EXE_B_RT;
		exe_a_src = EXE_A_RS;
		exe_alu_oper = EXE_ALU_ADD;
		mem_ren = 0;
		mem_wen = 0;
		wb_addr_src = WB_ADDR_RD;
		wb_data_src = WB_DATA_ALU;
		wb_wen = 0;
		pc_src = 2'b00;
		rs_used = 0;
		rt_used = 0;
        is_load = 0;
        is_store = 0;
		unrecognized = 0;
        cp_oper = EXE_CP_NONE;
		case (inst[31:26])
			INST_R: begin
				case (inst[5:0])
					R_FUNC_ADD: begin
						exe_alu_oper = EXE_ALU_ADD;
						wb_addr_src = WB_ADDR_RD;
						wb_data_src = WB_DATA_ALU;
						wb_wen = 1;
						rs_used = 1;
						rt_used = 1;
					end
					R_FUNC_ADDU: begin
						exe_alu_oper = EXE_ALU_ADDU;
						wb_addr_src = WB_ADDR_RD;
						wb_data_src = WB_DATA_ALU;
						wb_wen = 1;
						rs_used = 1;
						rt_used = 1;
					end
					R_FUNC_SUB: begin
						exe_alu_oper = EXE_ALU_SUB;
						wb_addr_src = WB_ADDR_RD;
						wb_data_src = WB_DATA_ALU;
						wb_wen = 1;
						rs_used = 1;
						rt_used = 1;
					end
					R_FUNC_SUBU: begin
						exe_alu_oper = EXE_ALU_SUBU;
						wb_addr_src = WB_ADDR_RD;
						wb_data_src = WB_DATA_ALU;
						wb_wen = 1;
						rs_used = 1;
						rt_used = 1;
					end
					R_FUNC_AND: begin
						exe_alu_oper = EXE_ALU_AND;
						wb_addr_src = WB_ADDR_RD;
						wb_data_src = WB_DATA_ALU;
						wb_wen = 1;
						rs_used = 1;
						rt_used = 1;
					end
					R_FUNC_OR: begin
						exe_alu_oper = EXE_ALU_OR;
						wb_addr_src = WB_ADDR_RD;
						wb_data_src = WB_DATA_ALU;
						wb_wen = 1;
						rs_used = 1;
						rt_used = 1;
					end
					R_FUNC_XOR: begin
						exe_alu_oper = EXE_ALU_XOR;
						wb_addr_src = WB_ADDR_RD;
						wb_data_src = WB_DATA_ALU;
						wb_wen = 1;
						rs_used = 1;
						rt_used = 1;
					end
					R_FUNC_NOR: begin
						exe_alu_oper = EXE_ALU_NOR;
						wb_addr_src = WB_ADDR_RD;
						wb_data_src = WB_DATA_ALU;
						wb_wen = 1;
						rs_used = 1;
						rt_used = 1;
					end
					R_FUNC_SLT: begin
						exe_alu_oper = EXE_ALU_SLT;
						wb_addr_src = WB_ADDR_RD;
						wb_data_src = WB_DATA_ALU;
						wb_wen = 1;
						rs_used = 1;
						rt_used = 1;
					end
					R_FUNC_SLTU: begin
						exe_alu_oper = EXE_ALU_SLTU;
						wb_addr_src = WB_ADDR_RD;
						wb_data_src = WB_DATA_ALU;
						wb_wen = 1;
						rt_used = 1;
					end
					R_FUNC_SLL: begin
						exe_alu_oper = EXE_ALU_SLL;
						wb_addr_src = WB_ADDR_RD;
						wb_data_src = WB_DATA_ALU;
						wb_wen = 1;
						rt_used = 1;
					end
					R_FUNC_SRL: begin
						exe_alu_oper = EXE_ALU_SRL;
						wb_addr_src = WB_ADDR_RD;
						wb_data_src = WB_DATA_ALU;
						wb_wen = 1;
						rt_used = 1;
					end
					R_FUNC_SRA: begin
						exe_alu_oper = EXE_ALU_SRA;
						wb_addr_src = WB_ADDR_RD;
						wb_data_src = WB_DATA_ALU;
						wb_wen = 1;
						rt_used = 1;
					end
					R_FUNC_SLLV: begin
						exe_alu_oper = EXE_ALU_SLLV;
						wb_addr_src = WB_ADDR_RD;
						wb_data_src = WB_DATA_ALU;
						wb_wen = 1;
						rs_used = 1;
						rt_used = 1;
					end
					R_FUNC_SRLV: begin
						exe_alu_oper = EXE_ALU_SRLV;
						wb_addr_src = WB_ADDR_RD;
						wb_data_src = WB_DATA_ALU;
						wb_wen = 1;
						rs_used = 1;
						rt_used = 1;
					end
					R_FUNC_SRAV: begin
						exe_alu_oper = EXE_ALU_SRAV;
						wb_addr_src = WB_ADDR_RD;
						wb_data_src = WB_DATA_ALU;
						wb_wen = 1;
						rs_used = 1;
						rt_used = 1;
					end
					R_FUNC_JR: begin
						rs_used = 1;
						pc_src = PC_JR;
					end
					default: begin
						unrecognized = 1;
					end
				endcase
			end
            INST_CP0: begin
                if (inst[5:0] == CP0_CO_ERET) begin
                    cp_oper = EXE_CP0_ERET;
                end
                else if(inst[25] == 0) begin
                    case (inst[24:21])
                        CP_FUNC_MF: begin
                            rt_used = 1;
                            cp_oper = EXE_CP_NONE;
                            wb_addr_src = WB_ADDR_RT;
                            wb_data_src = WB_DATA_ALU;
                            wb_wen = 1;
                            exe_alu_oper = EXE_ALU_B;
                        end
                        CP_FUNC_MT: begin
                            rt_used = 1;
                            cp_oper = EXE_CP_STORE;
                        end
                    endcase
                end
            end
			INST_ADDI:begin
				imm_ext = 1;
				rs_used = 1;
				exe_b_src = EXE_B_IMM;
				exe_alu_oper = EXE_ALU_ADD;
				wb_addr_src = WB_ADDR_RT;
				wb_data_src = WB_DATA_ALU;
				wb_wen = 1;
			end
			INST_ADDIU:begin
				exe_alu_oper = EXE_ALU_ADDU;
				exe_b_src = EXE_B_IMM;
				imm_ext = 1;
				rs_used = 1;
				wb_addr_src = WB_ADDR_RT;
				wb_data_src = WB_DATA_ALU;
				wb_wen = 1;
			end
			INST_ANDI:begin
				exe_alu_oper = EXE_ALU_AND;
				exe_b_src = EXE_B_IMM;
				rs_used = 1;
				wb_addr_src = WB_ADDR_RT;
				wb_data_src = WB_DATA_ALU;
				wb_wen = 1;
			end
			INST_ORI:begin
				exe_alu_oper = EXE_ALU_OR;
				exe_b_src = EXE_B_IMM;
				rs_used = 1;
				wb_addr_src = WB_ADDR_RT;
				wb_data_src = WB_DATA_ALU;
				wb_wen = 1;
			end
			INST_XORI:begin
				exe_alu_oper = EXE_ALU_XOR;
				exe_b_src = EXE_B_IMM;
				rs_used = 1;
				wb_addr_src = WB_ADDR_RT;
				wb_data_src = WB_DATA_ALU;
				wb_wen = 1;
			end
			INST_LUI:begin
				exe_alu_oper = EXE_ALU_LUI;
				exe_b_src = EXE_B_IMM;
				wb_addr_src = WB_ADDR_RT;
				wb_data_src = WB_DATA_ALU;
				wb_wen = 1;
			end

			INST_SLTI:begin
				exe_alu_oper = EXE_ALU_SLT;
				exe_b_src = EXE_B_IMM;
				imm_ext = 1;
				wb_addr_src = WB_ADDR_RT;
				wb_data_src = WB_DATA_ALU;
				wb_wen = 1;
			end
			INST_SLTIU:begin
				exe_alu_oper = EXE_ALU_SLT;
				exe_b_src = EXE_B_IMM;
				wb_addr_src = WB_ADDR_RT;
				wb_data_src = WB_DATA_ALU;
				wb_wen = 1;
			end

			INST_BEQ: begin
				if (rs_rt_equal) pc_src = PC_BRANCH;
				exe_b_src = EXE_B_IMM;
				imm_ext = 1;
				rs_used = 1;
				rt_used = 1;
			end
			INST_BNE: begin
				if (!rs_rt_equal) pc_src = PC_BRANCH;
				exe_b_src = EXE_B_IMM;
				imm_ext = 1;
				rs_used = 1;
				rt_used = 1;
			end
			INST_J: begin
				pc_src = PC_JUMP;
			end
			INST_JAL: begin
				pc_src = PC_JUMP;
				wb_addr_src = WB_ADDR_LINK;
				wb_data_src = WB_DATA_ALU;
				exe_b_src = EXE_B_LINK;
				exe_a_src = EXE_A_PC;
				wb_wen = 1;
			end
			INST_LW: begin
				imm_ext = 1;
				exe_b_src = EXE_B_IMM;
				exe_alu_oper = EXE_ALU_ADD;
				mem_ren = 1;
				wb_addr_src = WB_ADDR_RT;
				wb_data_src = WB_DATA_MEM;
				wb_wen = 1;
				rs_used = 1;
				is_load = 1;
			end
			INST_SW: begin
				imm_ext = 1;
				exe_b_src = EXE_B_IMM;
				exe_alu_oper = EXE_ALU_ADD;
				mem_wen = 1;
				rs_used = 1;
				rt_used = 1;
				is_store = 1;
			end
			default: begin
				unrecognized = 1;
			end
		endcase
	end
	
	// pipeline control
	`ifdef DEBUG
	reg debug_step_prev;
	
	always @(posedge clk) begin
		debug_step_prev <= debug_step;
	end
	`endif

	assign
        addr_rs = inst[25:21],
        addr_rt = inst[20:16];

	always @(*) begin
		reg_stall = 0;
		fwd_a = 0;
		fwd_b = 0;
		fwd_m = 0;
		//a
		if (rs_used && addr_rs!=0) begin
			if (regw_addr_exe == addr_rs && wb_wen_exe) begin
                if (is_load_exe) begin
					reg_stall = 1;
                end 
				else begin
					fwd_a = FWD_A_FROM_EXE;
				end
			end
			else if (regw_addr_mem == addr_rs && wb_wen_mem) begin
                if (is_load_mem) begin
					fwd_a = FWD_A_FROM_DIN;
                end
				else begin
					fwd_a = FWD_A_FROM_MEM;			
				end
			end
            else if (regw_addr_wb == addr_rs && wb_wen_wb) begin
                fwd_a = FWD_A_FROM_WB;
            end
		end
		//b
		if (rt_used && addr_rt!=0) begin
			if (regw_addr_exe == addr_rt && wb_wen_exe) begin
                if (is_load_exe) begin
					reg_stall = 1;
                end
				else begin
					fwd_b = FWD_B_FROM_EXE;
				end
			end
			else if (regw_addr_mem == addr_rt && wb_wen_mem) begin
				if (is_load_mem)
					fwd_b = FWD_B_FROM_DIN;
				else begin
					fwd_b = FWD_B_FROM_MEM;			
				end
			end
            else if (regw_addr_wb == addr_rt && wb_wen_wb) begin
                fwd_b = FWD_B_FROM_WB;
            end
			else if (inst[24:21] == CP_FUNC_MF) begin
				fwd_b = FWD_B_FROM_CP0;
			end
		end
	end
	
	always @(*) begin
		if_rst = 0;
		if_en = 1;
		id_rst = 0;
		id_en = 1;
		exe_rst = 0;
		exe_en = 1;
		mem_rst = 0;
		mem_en = 1;
		wb_rst = 0;
		wb_en = 1;
		if (rst) begin
			if_rst = 1;
			id_rst = 1;
			exe_rst = 1;
			mem_rst = 1;
			wb_rst = 1;
		end
		`ifdef DEBUG
		// suspend and step execution
		else if ((debug_en) && ~(~debug_step_prev && debug_step)) begin
			if_en = 0;
			id_en = 0;
			exe_en = 0;
			mem_en = 0;
			wb_en = 0;
		end
		`endif
		// this stall indicate that ID is waiting for previous LW instruction, insert one NOP between ID and EXE.
		else if (reg_stall) begin
			if_en = 0;
			id_en = 0;
			exe_rst = 1;
		end
        // interrupt
        else if (jump_en) begin
            id_rst = 1;
        end
	end
	
endmodule
