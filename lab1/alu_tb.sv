module top;
	
//------------------------------------------------------------------------------
// DUT instantiation
//------------------------------------------------------------------------------

bit clk;
bit rst_n;
bit sin;
wire sout;

mtm_Alu DUT (
	.clk  (clk), 	//posedge active clock
	.rst_n(rst_n), 	//synchronous reset active low
	.sin  (sin), 	//serial data input
	.sout (sout) 	//serial data output
);
	
//------------------------------------------------------------------------------
// Clock generator
//------------------------------------------------------------------------------

initial begin : clk_gen
    clk = 0;
    forever begin : clk_frv
        #10;
        clk = ~clk;
    end
end
	
//------------------------------------------------------------------------------
// reset task
//------------------------------------------------------------------------------
task reset_dut();
    `ifdef DEBUG
    $display("%0t DEBUG: reset_alu", $time);
    `endif
    rst_n = 1'b0;
    @(negedge clk);
    rst_n = 1'b1;
endtask
endmodule