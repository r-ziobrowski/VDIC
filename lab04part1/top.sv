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
	end

	shape_reporter#(rectangle)::report_shapes();
	shape_reporter#(square)::report_shapes();
	shape_reporter#(triangle)::report_shapes();

end

	
endmodule
