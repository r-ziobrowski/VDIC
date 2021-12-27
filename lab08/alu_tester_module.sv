module alu_tester_module(alu_bfm bfm);
   import alu_pkg::*;

    static ALU_input_t ALU_prev;

	function bit [2:0] get_op();
		bit [2:0] op_choice;
		op_choice = 3'($random);

		return op_choice;
	endfunction : get_op

	function bit [31:0] get_data();
		bit [31:0] data_tmp;
		
		automatic int status = std::randomize(data_tmp) with {
			data_tmp dist {32'h0 := 1, [32'h1 : 32'hFFFF_FFFE] :/ 2, 32'hFFFF_FFFF := 1};
		};
		
		assert (status) else begin
			$display("Randomization in get_data() failed");
		end
		
		return data_tmp;
	endfunction : get_data

	function bit [3:0] get_crc(bit [67:0] data);
		bit [1:0] crc_ok;
		automatic bit [3:0] crc_rand = 4'($random);
		automatic bit [3:0] crc_tmp = CRC_input(data, 1'b0);

		crc_ok = 2'($random);

		if ((crc_ok == 2'b00) && (crc_rand != crc_tmp)) begin
			return crc_rand;
		end else begin
			return crc_tmp;
		end
	endfunction : get_crc

	function bit [2:0] get_data_len();
		bit [2:0] data_tmp;

		automatic int status = std::randomize(data_tmp) with {
			data_tmp dist {[3'h0 : 3'h3] :/ 25, 3'h4 := 75};
		};

		assert (status) else begin
			$display("Randomization in get_data_len() failed");
		end

		return data_tmp;
	endfunction : get_data_len

	function op_mode_t get_op_mode();
		bit [1:0] op_mode_choice;
		op_mode_choice = 2'($random);
		unique case (op_mode_choice)
			2'b00 : return nop_op;
			2'b01 : return rst_op;
			2'b10 : return def_op;
			2'b11 : return def_op;
		endcase // case (op_mode_choice)
	endfunction

	function ALU_input_t ALU_input_generate();
		bit [3:0] crc_in_tmp;
		ALU_input_t ALU_in;
		
		ALU_in.op_mode = get_op_mode();
		
		if(ALU_in.op_mode == def_op) begin
			ALU_in.A = get_data();
			ALU_in.B = get_data();
			ALU_in.OP = get_op();
			ALU_in.CRC = get_crc({ALU_in.B, ALU_in.A, 1'b1, ALU_in.OP});
			ALU_in.A_nr_of_bytes = get_data_len();
			ALU_in.B_nr_of_bytes = get_data_len();
			ALU_prev = ALU_in;
		end else begin
			ALU_in.A = ALU_prev.A;
			ALU_in.B = ALU_prev.B;
			ALU_in.OP = ALU_prev.OP;
			ALU_in.CRC = ALU_prev.CRC;
			ALU_in.A_nr_of_bytes = ALU_prev.A_nr_of_bytes;
			ALU_in.B_nr_of_bytes = ALU_prev.B_nr_of_bytes;
		end
		
		crc_in_tmp = CRC_input({ALU_in.B, ALU_in.A, 1'b1, ALU_in.OP}, 1'b0);
		
		ALU_in.ERR_expected = 1'b0;
		ALU_in.ERR_DATA = 1'b0;
		ALU_in.ERR_OP = 1'b0;
		ALU_in.ERR_CRC = 1'b0;

		if((ALU_in.A_nr_of_bytes != 3'h4) || (ALU_in.B_nr_of_bytes != 3'h4)) begin : ERR_DATA_check
			ALU_in.ERR_DATA = 1'b1;
			ALU_in.ERR_expected = 1'b1;
		end
		else if (ALU_in.CRC != crc_in_tmp) begin : ERR_CRC_check
			ALU_in.ERR_CRC = 1'b1;
			ALU_in.ERR_expected = 1'b1;
		end
		else if (!(ALU_in.OP inside {3'b000, 3'b001, 3'b100, 3'b101})) begin : ERR_OP_check
			ALU_in.ERR_OP = 1'b1;
			ALU_in.ERR_expected = 1'b1;
		end
		
		return ALU_in;
	endfunction : ALU_input_generate

	//------------------------------------------------------------------------------
	// Tester main
	//------------------------------------------------------------------------------

	initial begin
		ALU_input_t iALU_in;
		
		bfm.reset_dut();
		repeat (1_000) begin : tester_main
			iALU_in = ALU_input_generate();
			bfm.send_op(iALU_in);
		end
			
	end
endmodule : alu_tester_module




