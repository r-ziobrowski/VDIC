class triangle extends shape;
	function new(real a, real h);
		width_1 = a;
		height = h;
	endfunction
	
	function real get_area();
		return ((width_1*height)/2);
	endfunction
	
	function void print();
		$display($sformatf("Area of triangle (a: %g, h: %g): %g", width_1, height, get_area()));
	endfunction
	
endclass