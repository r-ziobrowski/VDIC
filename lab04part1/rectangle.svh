class rectangle extends shape;
	function new(real w, real l);
		width_1 = w;
		width_2 = l;
	endfunction
	
	function real get_area();
		return width_1*width_2;
	endfunction
	
	function void print();
		$display($sformatf("Area of rectangle (w: %g, l: %g): %g", width_1, width_2, get_area()));
	endfunction
	
endclass