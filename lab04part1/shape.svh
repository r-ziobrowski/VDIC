virtual class shape;
	real width_1;
	real width_2;
	real height;
	
	function new();
	endfunction
	
	pure virtual function real get_area();
	
	pure virtual function void print();
	
endclass
