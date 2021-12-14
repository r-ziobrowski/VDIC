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

		`ifdef DEBUG
		$display("%0t DEBUG: get_expected(%0d,%0d,%0d)",$time, ALU_in.A, ALU_in.B, ALU_in.OP);
		`endif


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
					$display("%0t INTERNAL ERROR. get_expected: unexpected case argument: %s", $time, ALU_in.OP);
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

//	function void check_results(random_command ALU_in, result_transaction ALU_out, result_transaction ALU_exp_out);
//		CHK_ERROR_EXPECTED : assert (ALU_exp_out.is_ERROR === ALU_out.is_ERROR) else begin
//			$display("Test FAILED - did not return ERR_FLAGS");
//			tr = TEST_FAILED;
//		end;
//
//		if (!ALU_out.is_ERROR) begin
//			CHK_RESULT : assert(ALU_out.C === ALU_exp_out.C) begin
//				`ifdef DEBUG
//				$display("Test passed for A=%0d B=%0d op_set=%0b", ALU_in.A, ALU_in.B, (operation_t'(ALU_in.OP)));
//				`endif
//			end else begin
//				$display("Test FAILED for A=%0h B=%0h op_set=%0b", ALU_in.A, ALU_in.B, (operation_t'(ALU_in.OP)));
//				$display("Expected: %h  received: %h", ALU_exp_out.C, ALU_out.C);
//				tr = TEST_FAILED;
//			end;
//
//			CHK_FLAGS : assert(ALU_out.FLAGS === ALU_exp_out.FLAGS) begin
//				`ifdef DEBUG
//				$display("Test passed for A=%0d B=%0d op_set=%0b", ALU_in.A, ALU_in.B, (operation_t'(ALU_in.OP)));
//				`endif
//			end else begin
//				$display("Test FAILED for A=%0h B=%0h op_set=%0b", ALU_in.A, ALU_in.B, (operation_t'(ALU_in.OP)));
//				$display("Expected flags: %4b  received: %4b", ALU_exp_out.FLAGS, ALU_out.FLAGS);
//				tr = TEST_FAILED;
//			end;
//
//			CHK_CRC : assert(ALU_out.CRC === ALU_exp_out.CRC) begin
//				`ifdef DEBUG
//				$display("Test passed for A=%0d B=%0d op_set=%0b", ALU_in.A, ALU_in.B, (operation_t'(ALU_in.OP)));
//				`endif
//			end else begin
//				$display("Test FAILED for A=%0h B=%0h op_set=%0b", ALU_in.A, ALU_in.B, (operation_t'(ALU_in.OP)));
//				$display("Expected CRC: %3b  received: %3b", ALU_exp_out.CRC, ALU_out.CRC);
//				tr = TEST_FAILED;
//			end;
//
//		end else begin // ERROR_out
//			if(ERR_DATA) begin
//				CHK_ERR_DATA : assert((ALU_out.ERR_FLAGS & `ERR_DATA_mask) === `ERR_DATA_mask) else begin
//					$display("Test FAILED - expected ERR_DATA");
//					$display("Received ERR_FLAGS: %b", ALU_out.ERR_FLAGS);
//					tr = TEST_FAILED;
//				end;
//			end
//
//			else if(ERR_CRC) begin
//				CHK_ERR_CRC : assert((ALU_out.ERR_FLAGS & `ERR_CRC_mask) === `ERR_CRC_mask) else begin
//					$display("Test FAILED - expected ERR_CRC");
//					$display("Received ERR_FLAGS: %b", ALU_out.ERR_FLAGS);
//					tr = TEST_FAILED;
//				end;
//			end
//
//			else if(ERR_OP) begin
//				CHK_ERR_OP : assert((ALU_out.ERR_FLAGS & `ERR_OP_mask) === `ERR_OP_mask) else begin
//					$display("Test FAILED - expected ERR_OP");
//					$display("Received ERR_FLAGS: %b", ALU_out.ERR_FLAGS);
//					tr = TEST_FAILED;
//				end;
//			end
//
//			CHK_ERR_PARITY : assert(ALU_out.PARITY === ALU_exp_out.PARITY) else begin
//				$display("Test FAILED - invalid parity bit");
//				$display("Received parity: %b", ALU_out.PARITY);
//				tr = TEST_FAILED;
//			end;
//		end
//	endfunction

//	function void write(ALU_output_t t);
//		ALU_output_t predicted_out;
//
//		ALU_input_t cmd;
//		cmd.op_mode = nop_op;
//
//		do
//			if (!cmd_f.try_get(cmd))
//				$fatal(1, "Missing command in self checker");
//		while ((cmd.op_mode == nop_op) || (cmd.op_mode == rst_op));
//
//		predicted_out = get_expected(cmd);
//		check_results(cmd, t, predicted_out);
//	endfunction
//	

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