`timescale 1ns/1ps
module top;
	import alu_pkg::*;
	alu_bfm bfm();

	testbench testbench_h;

	mtm_Alu DUT (
		.clk  (bfm.clk),    //posedge active clock
		.rst_n(bfm.rst_n),  //synchronous reset active low
		.sin  (bfm.sin),    //serial data input
		.sout (bfm.sout)    //serial data output
	);

	initial begin
		testbench_h = new(bfm);
		testbench_h.execute();
	end

	final begin : finish_of_the_test
		testbench_h.end_results();
	end

endmodule
