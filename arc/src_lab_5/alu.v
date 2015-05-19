`include "define.vh"

/**
 * Arithmetic and Logic Unit for MIPS CPU.
 * Author: Zhao, Hongyu, Zhejiang University
 */
 
module alu (
	input wire [31:0] inst,  // instruction
	input wire [31:0] a, b,  // two operands
	input wire [3:0] oper,  // operation type
	output reg [31:0] result  // calculation result
	);
	
	`include "mips_define.vh"

	wire [4:0] sa;
	assign sa = inst[10:6]; 

	always @(*) begin
		//adder_mode = 0;
		result = 0;
		case (oper)
			EXE_ALU_ADD: begin
				result = a + b;
			end
			EXE_ALU_ADDU: begin
				result = a + b;
			end
			EXE_ALU_SUB: begin
				result = a - b;
			end
			EXE_ALU_SUBU: begin
				result = a - b;
			end
			EXE_ALU_AND: begin
				result = a & b;
			end
			EXE_ALU_OR: begin
				result = a | b;
			end
			EXE_ALU_XOR: begin
				result = a ^ b;
			end
			EXE_ALU_NOR: begin
				result = ~(a | b);
			end
			EXE_ALU_SLT: begin
				result = $signed(a) < $signed(b) ? 1 : 0;
			end
			EXE_ALU_SLTU: begin
				result = $unsigned(a) < $unsigned(b) ? 1 : 0;
			end
			EXE_ALU_SLL: begin
				result = $unsigned(b) << sa;				
			end
			EXE_ALU_SRL: begin
				result = $unsigned(b) >> sa;
			end
			EXE_ALU_SRA: begin
				result = $signed(b) >> sa;
			end
			EXE_ALU_SLLV: begin
				result = $unsigned(b) << a;
			end
			EXE_ALU_SRLV: begin
				result = $unsigned(b) >> a;
			end
			EXE_ALU_SRAV: begin
				result = $signed(b) >> a;
			end
			EXE_ALU_LUI: begin
				result = {b[15:0], 16'b0};
			end
		endcase
	end
	
endmodule
