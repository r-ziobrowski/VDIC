class square extends rectangle;
	
	function new(real side);
		super.new(.l(side), .w(side));
	endfunction
	
	function void print();
		$display($sformatf("Area of square (w: %g): %g", width_1, get_area()));
	endfunction
	
endclass