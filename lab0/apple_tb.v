module apple_tb();
	reg a =0;
	reg b =0;
	reg clk =0;
	wire q;
	
	apple u_apple (
		.a  (a),
		.b  (b),
		.clk(clk),
		.q  (q)
		);
	
	initial
		forever begin
			clk = #5 !clk;
			end
	
	initial begin
	
		a=0;
		b=1;
		#50;
		
		a=0;
		b=0;
		#50;
		
		a=1;
		b=0;
		#50;
		
		a=1;
		b=1;
		#50;
		$finish();
	
	end
	
endmodule
