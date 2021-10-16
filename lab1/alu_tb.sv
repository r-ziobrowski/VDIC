`timescale 1ns/1ps

module top;

	typedef enum bit[2:0] {
		and_op = 3'b000,
		or_op  = 3'b001,
		add_op = 3'b100,
		sub_op = 3'b101
		} operation_t;

//------------------------------------------------------------------------------
// DUT instantiation
//------------------------------------------------------------------------------

	bit clk;
	bit rst_n;
	bit sin;
	bit [7:0] data;
	bit cmd;
	wire sout;

	mtm_Alu DUT (
		.clk  (clk),    //posedge active clock
		.rst_n(rst_n),  //synchronous reset active low
		.sin  (sin),    //serial data input
		.sout (sout)    //serial data output
	);

//------------------------------------------------------------------------------
// Clock generator
//------------------------------------------------------------------------------
	initial begin : clk_gen
		clk = 0;
		forever begin : clk_frv
			#10;
			clk = ~clk;
		end
	end

	task serial_write(bit [7:0] data_in, bit is_cmd);
		automatic bit [10:0] serial_data = {1'b0, is_cmd, data_in, 1'b1};
		foreach(serial_data[i])begin
			@(negedge clk);
			sin = serial_data[i];
		end
	endtask

	task send_message(bit [31:0] A, bit [31:0] B, operation_t OP, bit [3:0] CRC);
		for(int i = $rtoi($ceil($size(B)/8)); i > 0; i--)begin
			serial_write(B[i*8-1 -: 8], 1'b0);
		end
		for(int i = $rtoi($ceil($size(A)/8)); i > 0; i--)begin
			serial_write(A[i*8-1 -: 8], 1'b0);
		end
		$display(CRC);
		serial_write({1'b0, OP, CRC}, 1'b1);
	endtask
	
	task serial_read(output bit [7:0] data_out, bit is_cmd);
		@(negedge sout);
		for(int i = 0; i < 11; i++)begin
			@(negedge clk);
			case(i) inside 
				1: is_cmd = sout;
				[2:9]: data_out[(7-(i-2))] = sout;
			endcase
		end
	endtask

	task read_message(output bit [31:0] C, bit [3:0] FLAGS, bit is_cmd);
		
	endtask

// polynomial: x^4 + x^1 + 1
function [3:0] CRC_input(bit [67:0] data, bit [3:0] crc);
    bit [67:0] d;
    bit [3:0] c;
    bit [3:0] newcrc;
	begin
	    d = data;
	    c = crc;
	
	    newcrc[0] = d[66] ^ d[64] ^ d[63] ^ d[60] ^ d[56] ^ d[55] ^ d[54] ^ d[53] ^ d[51] ^ d[49] ^ d[48] ^ d[45] ^ d[41] ^ d[40] ^ d[39] ^ d[38] ^ d[36] ^ d[34] ^ d[33] ^ d[30] ^ d[26] ^ d[25] ^ d[24] ^ d[23] ^ d[21] ^ d[19] ^ d[18] ^ d[15] ^ d[11] ^ d[10] ^ d[9] ^ d[8] ^ d[6] ^ d[4] ^ d[3] ^ d[0] ^ c[0] ^ c[2];
	    newcrc[1] = d[67] ^ d[66] ^ d[65] ^ d[63] ^ d[61] ^ d[60] ^ d[57] ^ d[53] ^ d[52] ^ d[51] ^ d[50] ^ d[48] ^ d[46] ^ d[45] ^ d[42] ^ d[38] ^ d[37] ^ d[36] ^ d[35] ^ d[33] ^ d[31] ^ d[30] ^ d[27] ^ d[23] ^ d[22] ^ d[21] ^ d[20] ^ d[18] ^ d[16] ^ d[15] ^ d[12] ^ d[8] ^ d[7] ^ d[6] ^ d[5] ^ d[3] ^ d[1] ^ d[0] ^ c[1] ^ c[2] ^ c[3];
	    newcrc[2] = d[67] ^ d[66] ^ d[64] ^ d[62] ^ d[61] ^ d[58] ^ d[54] ^ d[53] ^ d[52] ^ d[51] ^ d[49] ^ d[47] ^ d[46] ^ d[43] ^ d[39] ^ d[38] ^ d[37] ^ d[36] ^ d[34] ^ d[32] ^ d[31] ^ d[28] ^ d[24] ^ d[23] ^ d[22] ^ d[21] ^ d[19] ^ d[17] ^ d[16] ^ d[13] ^ d[9] ^ d[8] ^ d[7] ^ d[6] ^ d[4] ^ d[2] ^ d[1] ^ c[0] ^ c[2] ^ c[3];
	    newcrc[3] = d[67] ^ d[65] ^ d[63] ^ d[62] ^ d[59] ^ d[55] ^ d[54] ^ d[53] ^ d[52] ^ d[50] ^ d[48] ^ d[47] ^ d[44] ^ d[40] ^ d[39] ^ d[38] ^ d[37] ^ d[35] ^ d[33] ^ d[32] ^ d[29] ^ d[25] ^ d[24] ^ d[23] ^ d[22] ^ d[20] ^ d[18] ^ d[17] ^ d[14] ^ d[10] ^ d[9] ^ d[8] ^ d[7] ^ d[5] ^ d[3] ^ d[2] ^ c[1] ^ c[3];
	    return newcrc;
	end
endfunction


// polynomial: x^3 + x^1 + 1
function [2:0] CRC_output(bit [36:0] data, bit [2:0] crc);
    reg [36:0] d;
    reg [2:0] c;
    reg [2:0] newcrc;
  	begin
	    d = data;
	    c = crc;
	
	    newcrc[0] = d[35] ^ d[32] ^ d[31] ^ d[30] ^ d[28] ^ d[25] ^ d[24] ^ d[23] ^ d[21] ^ d[18] ^ d[17] ^ d[16] ^ d[14] ^ d[11] ^ d[10] ^ d[9] ^ d[7] ^ d[4] ^ d[3] ^ d[2] ^ d[0] ^ c[1];
	    newcrc[1] = d[36] ^ d[35] ^ d[33] ^ d[30] ^ d[29] ^ d[28] ^ d[26] ^ d[23] ^ d[22] ^ d[21] ^ d[19] ^ d[16] ^ d[15] ^ d[14] ^ d[12] ^ d[9] ^ d[8] ^ d[7] ^ d[5] ^ d[2] ^ d[1] ^ d[0] ^ c[1] ^ c[2];
	    newcrc[2] = d[36] ^ d[34] ^ d[31] ^ d[30] ^ d[29] ^ d[27] ^ d[24] ^ d[23] ^ d[22] ^ d[20] ^ d[17] ^ d[16] ^ d[15] ^ d[13] ^ d[10] ^ d[9] ^ d[8] ^ d[6] ^ d[3] ^ d[2] ^ d[1] ^ c[0] ^ c[2];
	    return newcrc;
  	end
endfunction
//------------------------------------------------------------------------------
// Tester main
//------------------------------------------------------------------------------
	initial begin : tester
//		reset_dut();
//    repeat (100) begin : tester_main
//		@(negedge clk);
		sin=1'b1;
		rst_n=1'b1;
		reset_dut();
		#1000;
//		serial_write(8'b11110000, 1'b1);

//    end
//$display({32'h87654321,32'h12345678,1'b1,3'b100});
		send_message(32'h15, 32'h11, add_op, CRC_input({32'h11,32'h15,1'b1,3'b100}, 4'b0));
		serial_read(data, cmd);
		$display("data: %0d, is_cmd=%b",data, cmd);
		serial_read(data, cmd);
		$display("data: %0d, is_cmd=%b",data, cmd);
		serial_read(data, cmd);
		$display("data: %0d, is_cmd=%b",data, cmd);
		serial_read(data, cmd);
		$display("data: %0d, is_cmd=%b",data, cmd);
		serial_read(data, cmd);
		$display("data: %0d, is_cmd=%b",data, cmd);
		#100
		$finish;
	end : tester

//------------------------------------------------------------------------------
// reset task
//------------------------------------------------------------------------------
	task reset_dut();
	`ifdef DEBUG
		$display("%0t DEBUG: reset_alu", $time);
	`endif
		rst_n = 1'b0;
		@(negedge clk);
		rst_n = 1'b1;
	endtask
endmodule