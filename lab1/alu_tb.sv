`timescale 1ns/1ps

module top;

	typedef enum bit[2:0] {
		and_op = 3'b000,
		or_op  = 3'b001,
		add_op = 3'b100,
		sub_op = 3'b101
		} operation_t;
	
	typedef struct {
		bit [31:0] A;
		bit [31:0] B;
		bit [2:0] OP;
		bit [3:0] CRC;
	} ALU_input_t;
	
	typedef struct {
		bit ERR_DATA;
		bit ERR_CRC;
		bit ERR_OP;
	} ERR_FLAGS_expected_t;
//------------------------------------------------------------------------------
// DUT instantiation
//------------------------------------------------------------------------------

	bit clk;
	bit rst_n;
	bit sin;
	bit [7:0] data;
	bit cmd;
	wire sout;
	bit [31:0] C_out;
	bit [3:0] FLAGS_out;
	bit [5:0] ERR_FLAGS;
	bit ERR_PARITY;
	bit ERROR;
	bit [2:0] CRC;
	ALU_input_t ALU_input;
	ERR_FLAGS_expected_t ERR_FLAGS_expected;
	string test_result = "PASSED";
	
	
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

//------------------------------------------------------------------------------
// Serial write tasks
//------------------------------------------------------------------------------
	task serial_write(bit [7:0] data_in, bit is_cmd);
		automatic bit [10:0] serial_data = {1'b0, is_cmd, data_in, 1'b1};
		foreach(serial_data[i])begin
			@(negedge clk);
			sin = serial_data[i];
		end
	endtask : serial_write

	task send_message(ALU_input_t ALU_in, bit [2:0] A_nr_of_bytes, bit [2:0] B_nr_of_bytes);
		for(int i = B_nr_of_bytes; i > 0; i--)begin
			serial_write(ALU_in.B[i*8-1 -: 8], 1'b0);
		end
		for(int i = A_nr_of_bytes; i > 0; i--)begin
			serial_write(ALU_in.A[i*8-1 -: 8], 1'b0);
		end
		serial_write({1'b0, ALU_in.OP, ALU_in.CRC}, 1'b1);
		
		if((A_nr_of_bytes != 4) || (B_nr_of_bytes != 4))
			ERR_FLAGS_expected.ERR_DATA = 1'b1;
		else
			ERR_FLAGS_expected.ERR_DATA = 1'b0;
	endtask : send_message
	
//------------------------------------------------------------------------------
// Serial read tasks
//------------------------------------------------------------------------------
	task serial_read(output bit [7:0] data_out, bit is_cmd);
		@(negedge sout);
		for(int i = 0; i < 11; i++)begin
			@(negedge clk);
			case(i) inside 
				1: is_cmd = sout;
				[2:9]: data_out[(7-(i-2))] = sout;
			endcase
		end
	endtask : serial_read

	task read_message(output bit [31:0] C, bit [3:0] FLAGS, bit [5:0] ERR_FLAGS, bit ERR_PARITY, bit ERROR, bit [2:0] CRC);
		automatic bit [7:0] data_tmp;
		automatic bit is_cmd = 1'b0;
		ERROR = 1'b0;
		FLAGS = 4'h0;
		ERR_FLAGS = 6'h0;
		ERR_PARITY = 1'b0;
		for(int i = $rtoi($ceil($size(C)/8)); i > 0; i--)begin
			serial_read(data_tmp, is_cmd);
			if (is_cmd == 1'b1)begin
				ERROR = 1'b1;
				ERR_FLAGS = data_tmp[6 -: 5];
				ERR_PARITY = data_tmp[0];
				break;
			end else begin
				C[i*8-1 -: 8] = data_tmp;
			end			
		end
		if (!ERROR) begin
			serial_read(data_tmp, is_cmd);
			FLAGS = data_tmp[6:3];
			CRC = data_tmp[2:0];
		end
	endtask : read_message

//------------------------------------------------------------------------------
// CRC generation
//------------------------------------------------------------------------------

// polynomial: x^4 + x^1 + 1
function bit [3:0] CRC_input(bit [67:0] data, bit [3:0] crc);
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
endfunction : CRC_input

// polynomial: x^3 + x^1 + 1
function bit [2:0] CRC_output(bit [36:0] data, bit [2:0] crc);
    bit [36:0] d;
    bit [2:0] c;
    bit [2:0] newcrc;
  	begin
	    d = data;
	    c = crc;
	
	    newcrc[0] = d[35] ^ d[32] ^ d[31] ^ d[30] ^ d[28] ^ d[25] ^ d[24] ^ d[23] ^ d[21] ^ d[18] ^ d[17] ^ d[16] ^ d[14] ^ d[11] ^ d[10] ^ d[9] ^ d[7] ^ d[4] ^ d[3] ^ d[2] ^ d[0] ^ c[1];
	    newcrc[1] = d[36] ^ d[35] ^ d[33] ^ d[30] ^ d[29] ^ d[28] ^ d[26] ^ d[23] ^ d[22] ^ d[21] ^ d[19] ^ d[16] ^ d[15] ^ d[14] ^ d[12] ^ d[9] ^ d[8] ^ d[7] ^ d[5] ^ d[2] ^ d[1] ^ d[0] ^ c[1] ^ c[2];
	    newcrc[2] = d[36] ^ d[34] ^ d[31] ^ d[30] ^ d[29] ^ d[27] ^ d[24] ^ d[23] ^ d[22] ^ d[20] ^ d[17] ^ d[16] ^ d[15] ^ d[13] ^ d[10] ^ d[9] ^ d[8] ^ d[6] ^ d[3] ^ d[2] ^ d[1] ^ c[0] ^ c[2];
	    return newcrc;
  	end
endfunction : CRC_output

function bit [2:0] get_op();
    bit [2:0] op_choice;
    op_choice = $random;
	
	if (!(op_choice inside {3'b000, 3'b001, 3'b100, 3'b101}))
		ERR_FLAGS_expected.ERR_OP= 1'b1;
	else
		ERR_FLAGS_expected.ERR_OP= 1'b0;
	
    return op_choice;
endfunction : get_op

function bit [31:0] get_data();
	bit [31:0] data_tmp;
	
	automatic int status = std::randomize(data_tmp) with {
		data_tmp dist {32'h0 := 1, [32'h1 : 32'hFFFF_FFFE] :/ 2, 32'hFFFF_FFFF := 1};
	};
	
	assert (status) else begin
		$display("Randomization in get_data failed");
		test_result = "FAILED";
	end
	
	return data_tmp;
endfunction : get_data

function bit [3:0] get_crc(bit [36:0] data);
    bit [1:0] crc_ok;
    crc_ok = 2'($random);
	
    if (crc_ok == 2'b00) begin
	    ERR_FLAGS_expected.ERR_CRC = 1'b1;
        return 2'($random);
    end else begin
	    ERR_FLAGS_expected.ERR_CRC = 1'b0;
    	return CRC_input(data, 1'b0);
    end
endfunction : get_crc

function void ALU_input_generate();
	ALU_input.A = get_data();
	ALU_input.B = get_data();
	ALU_input.OP = get_op();
	ALU_input.CRC = get_crc({ALU_input.B, ALU_input.A, 1'b1, ALU_input.OP});	
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
//		send_message(32'h15, 32'h11, 3'b111, CRC_input({32'h11,32'h15,1'b1,3'b111}, 4'b0));
//		read_message(C_out, FLAGS_out, ERR_FLAGS, ERR_PARITY,ERROR,CRC);
		$display("data: %0d, FLAGS_out: %0d, ERR_FLAGS: %0d, ERR_PARITY: %0d, ERROR: %0d, CRC: %0d",C_out, FLAGS_out, ERR_FLAGS, ERR_PARITY,ERROR,CRC);
//		serial_read(data, cmd);
//		$display("data: %0d, is_cmd=%b",data, cmd);
//		serial_read(data, cmd);
//		$display("data: %0d, is_cmd=%b",data, cmd);
//		serial_read(data, cmd);
//		$display("data: %0d, is_cmd=%b",data, cmd);
//		serial_read(data, cmd);
//		$display("data: %0d, is_cmd=%b",data, cmd);
//		serial_read(data, cmd);
		$display("data: %0d, is_cmd=%b, FLAGS_out = %0d",C_out, cmd, FLAGS_out);
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