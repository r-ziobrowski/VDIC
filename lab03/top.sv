`timescale 1ns/1ps
module top;
	
	alu_bfm bfm();
	
	tester tester_i(bfm);
	coverage coverage_i(bfm);
	scoreboard scoreboard_i(bfm);
	
	mtm_Alu DUT (
		.clk  (bfm.clk),    //posedge active clock
		.rst_n(bfm.rst_n),  //synchronous reset active low
		.sin  (bfm.sin),    //serial data input
		.sout (bfm.sout)    //serial data output
	);
	
endmodule
