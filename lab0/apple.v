module apple(
	input wire a,
	input wire b,
	input wire clk,
	output reg q
	);

always @(posedge clk) begin
	q <= a & b;
end

endmodule
