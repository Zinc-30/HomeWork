`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   13:43:30 06/16/2015
// Design Name:   cacheline
// Module Name:   /home/iiii/temp/HomeWork/arc/src_lab_7/sim_cacheline.v
// Project Name:  arc
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: cacheline
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module sim_cacheline;

	// Inputs
	reg clk;
	reg rst;
	reg [31:0] addr;
	reg load;
	reg edit;
	reg invalid;
	reg [31:0] din;

	// Outputs
	wire hit;
	wire valid;
	wire dirty;
	wire [21:0] tag;
	wire [31:0] dout;

	// Instantiate the Unit Under Test (UUT)
	cacheline uut (
		.clk(clk), 
		.rst(rst), 
		.addr(addr), 
		.load(load), 
		.edit(edit), 
		.invalid(invalid), 
		.din(din), 
		.hit(hit), 
		.valid(valid), 
		.dirty(dirty), 
		.tag(tag), 
		.dout(dout)
	);

	initial begin
		// Initialize Inputs
		clk = 0;
		rst = 0;
		addr = 0;
		load = 0;
		edit = 0;
		invalid = 0;
		din = 0;

		// Wait 100 ns for global reset to finish
        #210 load = 1; din = 32'h11111111; addr = 32'h00000000;
        #20 addr = 32'h00000004;
        #20 addr = 32'h000000a8;
        #20 addr = 32'h0000001c;
        #20 load = 0; addr = 32'h000000b4; din = 0;
        #100 edit = 1; din = 32'h22222222; addr = 32'h00000008;
        #100 edit = 0; din = 0; addr = 0;
        
	end

    initial forever #10 clk = ~clk;
      
endmodule

