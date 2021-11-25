class triangle extends shape;
	function new(real a, real h);
		width = a;
		height = h;
	endfunction
	
	function real get_area();
		return ((width*height)/2);
	endfunction
	
	function void print();
		$display($sformatf("Area of triangle (a: %g, h: %g): %g", width, height, get_area()));
	endfunction
	
endclass