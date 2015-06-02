`timescale 1ns / 1ps

`include "define.vh"	

module sim_mips_top;

	// Inputs
	reg CCLK;
	reg [3:0] SW;
	reg BTNN;// reset signal 
	reg BTNE;
	reg BTNS;// step signal
	reg BTNW;// interrupt signal
	reg ROTA;
	reg ROTB;
	reg ROTCTR;

	// Outputs
	wire [7:0] LED;
	wire LCDE;
	wire LCDRS;
	wire LCDRW;
	wire [3:0] LCDDAT;

	// Instantiate the Unit Under Test (UUT)
	mips_top uut (
		.CCLK(CCLK), 
		.SW(SW), 
		.BTNN(BTNN), 
		.BTNE(BTNE), 
		.BTNS(BTNS), 
		.BTNW(BTNW), 
		.ROTA(ROTA), 
		.ROTB(ROTB), 
		.ROTCTR(ROTCTR), 
		.LED(LED), 
		.LCDE(LCDE), 
		.LCDRS(LCDRS), 
		.LCDRW(LCDRW), 
		.LCDDAT(LCDDAT)
	);

	initial begin
		// Initialize Inputs
		CCLK = 0;
		SW = 0;
		BTNN = 0;
		BTNE = 0;
		BTNS = 0;
		BTNW = 0;
		ROTA = 0;
		ROTB = 0;
		ROTCTR = 0;

		// Wait 100 ns for global reset to finish
		// Add stimulus here
        #1565 BTNW = 1;
        #50 BTNW = 0;
        #550 BTNW = 1;
        #50 BTNW = 0;
		#500 BTNW = 1;
		#50 BTNW = 0;

	end
	
	initial forever #5 CCLK = ~CCLK;
      
endmodule

