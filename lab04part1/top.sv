`timescale 1ns/1ps
module top;

initial begin
	
	shape shape_h;
	
	rectangle rectangle_h;
	triangle triangle_h;
	square square_h;
	
	int cast_ok;
	int file, status;
	string shape_type;
	real w, h;
	
	file = $fopen("lab04part1_shapes.txt","r");
	while (!$feof(file)) begin
		status = $fscanf(file,"%s %g %g\n",shape_type, w, h);
			
		shape_h = shape_factory::make_shape(shape_type, w, h);
		
		case(shape_type)
			"rectangle" : begin
				cast_ok = $cast(rectangle_h, shape_h);
				if(!cast_ok) $fatal(1, "Failed to cast shape_h to rectangle_h");
				shape_reporter#(rectangle)::add_shape(rectangle_h);
			end
			
			"triangle" : begin
				cast_ok = $cast(triangle_h, shape_h);
				if(!cast_ok) $fatal(1, "Failed to cast shape_h to triangle_h");
				shape_reporter#(triangle)::add_shape(triangle_h);
			end
			
			"square" : begin
				cast_ok = $cast(square_h, shape_h);
				if(!cast_ok) $fatal(1, "Failed to cast shape_h to square_h");
				shape_reporter#(square)::add_shape(square_h);
			end
			
			default : $fatal(1, {"No such shape: ", shape_type});
			
		endcase	
	end

	shape_reporter#(rectangle)::report_shapes();
	shape_reporter#(square)::report_shapes();
	shape_reporter#(triangle)::report_shapes();

end

	
endmodule
