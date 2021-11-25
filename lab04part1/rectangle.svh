class rectangle extends shape;
	function new(real w, real l);
		width = w;
		height = l;
	endfunction
	
	function real get_area();
		return width*height;
	endfunction
	
	function void print();
		$display($sformatf("Area of rectangle (w: %g, l: %g): %g", width, height, get_area()));
	endfunction
	
endclass