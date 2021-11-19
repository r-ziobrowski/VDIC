class shape_reporter #(type T = shape);
	
	protected static T shape_storage[$];
	
	static function void add_shape(T s);
		shape_storage.push_back(s);
	endfunction
	
	static function void report_shapes();
		real total_area;
		
		foreach(shape_storage[i])begin
			shape_storage[i].print();
			total_area += shape_storage[i].get_area();
		end
		
		$display($sformatf("Total area: %g", total_area));
	
	endfunction
	
endclass