class scoreboard extends uvm_subscriber #(result_transaction);

	`uvm_component_utils(scoreboard)

	typedef enum bit {
		TEST_PASSED,
		TEST_FAILED
	} test_result;

	uvm_tlm_analysis_fifo #(random_command) cmd_f;

	protected test_result tr = TEST_PASSED;

	protected bit ERR_DATA = 1'b0;
	protected bit ERR_OP = 1'b0;
	protected bit ERR_CRC = 1'b0;

	function new (string name, uvm_component parent);
		super.new(name, parent);
	endfunction : new

	function void build_phase(uvm_phase phase);
		cmd_f = new ("cmd_f", this);
	endfunction : build_phase

	//------------------------------------------------------------------------------
	// Expected result generation
	//------------------------------------------------------------------------------

	protected function result_transaction get_expected(random_command ALU_in);
		automatic bit [32:0] C_tmp_carry;
		automatic bit signed [31:0] C_tmp;
		automatic bit overflow;
		bit [3:0] crc_in_tmp = CRC_input({ALU_in.B, ALU_in.A, 1'b1, ALU_in.OP}, 1'b0);

		result_transaction ALU_out;

		ERR_DATA = 1'b0;
		ERR_OP = 1'b0;
		ERR_CRC = 1'b0;

		ALU_out = new("ALU_out");

		ALU_out.is_ERROR = 1'b0;

		if((ALU_in.A_nr_of_bytes != 3'h4) || (ALU_in.B_nr_of_bytes != 3'h4)) begin : ERR_DATA_check
			ERR_DATA = 1'b1;
			ALU_out.is_ERROR = 1'b1;
		end
		else if (ALU_in.CRC != crc_in_tmp) begin : ERR_CRC_check
			ERR_CRC = 1'b1;
			ALU_out.is_ERROR = 1'b1;
		end
		else if (!(ALU_in.OP inside {3'b000, 3'b001, 3'b100, 3'b101})) begin : ERR_OP_check
			ERR_OP = 1'b1;
			ALU_out.is_ERROR = 1'b1;
		end

		ALU_out.ERR_FLAGS = {ERR_DATA, ERR_CRC, ERR_OP, ERR_DATA, ERR_CRC, ERR_OP};

		if(ALU_out.is_ERROR)
			ALU_out.PARITY = ^{1'b1, ALU_out.ERR_FLAGS};
		else
			ALU_out.PARITY = 1'b0;

		`uvm_info ("GET EXPECTED", ALU_in.convert2string(), UVM_HIGH)

		if(!ALU_out.is_ERROR) begin : RESULT_calc
			case(ALU_in.OP)
				and_op : C_tmp = ALU_in.B & ALU_in.A;
				or_op  : C_tmp = ALU_in.B | ALU_in.A;
				add_op : begin
					C_tmp = ALU_in.B + ALU_in.A;
					C_tmp_carry = ALU_in.B + ALU_in.A;
					overflow = ~(ALU_in.B[31] ^ ALU_in.A[31]) & (ALU_in.B[31] ^ C_tmp[31]);
				end
				sub_op : begin
					C_tmp = ALU_in.B - ALU_in.A;
					C_tmp_carry = ALU_in.B - ALU_in.A;
					overflow = (ALU_in.B[31] ^ ALU_in.A[31]) & (ALU_in.B[31] ^ C_tmp[31]);
				end
				default: begin
					`uvm_error("INTERNAL ERROR", $sformatf("get_expected: unexpected case argument: %h", ALU_in.OP))
					tr = TEST_FAILED;
				end
			endcase

			ALU_out.C = C_tmp;

			ALU_out.FLAGS = 4'h0;

			if(C_tmp < 0)               ALU_out.FLAGS[0] = 1;
			if(C_tmp == 0)              ALU_out.FLAGS[1] = 1;
			if(overflow)                ALU_out.FLAGS[2] = 1;
			if(C_tmp_carry[32] == 1'b1) ALU_out.FLAGS[3] = 1;

			ALU_out.CRC = CRC_output({ALU_out.C, 1'b0, ALU_out.FLAGS}, 1'b0);
		end
		return ALU_out;
	endfunction

	function void write(result_transaction t);
		string data_str;
		random_command cmd;
		result_transaction predicted;

		do
			if (!cmd_f.try_get(cmd))
				$fatal(1, "Missing command in self checker");
		while ((cmd.op_mode == nop_op) || (cmd.op_mode == rst_op));

		predicted = get_expected(cmd);

		data_str  = { cmd.convert2string(),
			" ==>  Actual \n" , t.convert2string(),
			"/Predicted \n",predicted.convert2string()};

		if (!predicted.compare(t)) begin
			`uvm_error("SELF CHECKER", {"FAIL: ",data_str})
			tr = TEST_FAILED;
		end
		else
			`uvm_info ("SELF CHECKER", {"PASS: ", data_str}, UVM_HIGH)

	endfunction : write

	function void report_phase(uvm_phase phase);
		super.report_phase(phase);
		if(tr == TEST_PASSED) begin
			$write ("\n");
			set_print_color(COLOR_BOLD_BLACK_ON_GREEN);
			$write("####################################################\n\n");
			$write("            #     ################       _   _           \n");
			$write("           #      #              #       *   *           \n");
			$write("      #   #       #    PASSED    #         |             \n");
			$write("       # #        #              #       \\___/          \n");
			$write("        #         ################                       \n");
			$write("\n####################################################");
			set_print_color(COLOR_DEFAULT);
			$write ("\n");
		end else begin
			$write ("\n");
			set_print_color(COLOR_BOLD_BLACK_ON_RED);
			$write("####################################################\n\n");
			$write("      #   #       ################       _   _           \n");
			$write("       # #        #              #       *   *           \n");
			$write("        #         #    FAILED    #        ___            \n");
			$write("       # #        #              #       /   \\          \n");
			$write("      #   #       ################                       \n");
			$write("\n####################################################");
			set_print_color(COLOR_DEFAULT);
			$write ("\n");
		end
	endfunction

endclass : scoreboard