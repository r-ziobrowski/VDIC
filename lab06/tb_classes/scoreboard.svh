class scoreboard extends uvm_subscriber #(ALU_output_t);

	`uvm_component_utils(scoreboard)

//    virtual alu_bfm bfm;
	uvm_tlm_analysis_fifo #(ALU_input_t) cmd_f;

	protected string test_result = "PASSED";

	function new (string name, uvm_component parent);
		super.new(name, parent);
	endfunction : new

	function void build_phase(uvm_phase phase);
		cmd_f = new ("cmd_f", this);
	endfunction : build_phase

	//------------------------------------------------------------------------------
	// Expected result generation
	//------------------------------------------------------------------------------

	protected function ALU_output_t get_expected(input ALU_input_t ALU_in);
		automatic bit [32:0] C_tmp_carry;
		automatic bit signed [31:0] C_tmp;
		automatic bit overflow;
		automatic ALU_output_t ALU_out;

		ALU_out.is_ERROR = ALU_in.ERR_expected;

		ALU_out.ERR_FLAGS = {   ALU_in.ERR_DATA,
			ALU_in.ERR_CRC,
			ALU_in.ERR_OP,
			ALU_in.ERR_DATA,
			ALU_in.ERR_CRC,
			ALU_in.ERR_OP};

		ALU_out.PARITY = ^{1'b1, ALU_out.ERR_FLAGS};

		`ifdef DEBUG
		$display("%0t DEBUG: get_expected(%0d,%0d,%0d)",$time, ALU_in.A, ALU_in.B, ALU_in.OP);
		`endif


		if(!ALU_in.ERR_expected) begin : RESULT_calc
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
					test_result = "FAILED";
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

	function void check_results(ALU_input_t ALU_in, ALU_output_t ALU_out, ALU_output_t ALU_exp_out);
		CHK_ERROR_EXPECTED : assert (ALU_exp_out.is_ERROR === ALU_out.is_ERROR) else begin
			$display("Test FAILED - did not return ERR_FLAGS");
			test_result = "FAILED";
		end;

		if (!ALU_out.is_ERROR) begin
			CHK_RESULT : assert(ALU_out.C === ALU_exp_out.C) begin
				`ifdef DEBUG
				$display("Test passed for A=%0d B=%0d op_set=%0b", ALU_in.A, ALU_in.B, (operation_t'(ALU_in.OP)));
				`endif
			end else begin
				$display("Test FAILED for A=%0h B=%0h op_set=%0b", ALU_in.A, ALU_in.B, (operation_t'(ALU_in.OP)));
				$display("Expected: %h  received: %h", ALU_exp_out.C, ALU_out.C);
				test_result = "FAILED";
			end;

			CHK_FLAGS : assert(ALU_out.FLAGS === ALU_exp_out.FLAGS) begin
				`ifdef DEBUG
				$display("Test passed for A=%0d B=%0d op_set=%0b", ALU_in.A, ALU_in.B, (operation_t'(ALU_in.OP)));
				`endif
			end else begin
				$display("Test FAILED for A=%0h B=%0h op_set=%0b", ALU_in.A, ALU_in.B, (operation_t'(ALU_in.OP)));
				$display("Expected flags: %4b  received: %4b", ALU_exp_out.FLAGS, ALU_out.FLAGS);
				test_result = "FAILED";
			end;

			CHK_CRC : assert(ALU_out.CRC === ALU_exp_out.CRC) begin
				`ifdef DEBUG
				$display("Test passed for A=%0d B=%0d op_set=%0b", ALU_in.A, ALU_in.B, (operation_t'(ALU_in.OP)));
				`endif
			end else begin
				$display("Test FAILED for A=%0h B=%0h op_set=%0b", ALU_in.A, ALU_in.B, (operation_t'(ALU_in.OP)));
				$display("Expected CRC: %3b  received: %3b", ALU_exp_out.CRC, ALU_out.CRC);
				test_result = "FAILED";
			end;

		end else begin // ERROR_out
			if(ALU_in.ERR_DATA) begin
				CHK_ERR_DATA : assert((ALU_out.ERR_FLAGS & `ERR_DATA_mask) === `ERR_DATA_mask) else begin
					$display("Test FAILED - expected ERR_DATA");
					$display("Received ERR_FLAGS: %b", ALU_out.ERR_FLAGS);
					test_result = "FAILED";
				end;
			end

			else if(ALU_in.ERR_CRC) begin
				CHK_ERR_CRC : assert((ALU_out.ERR_FLAGS & `ERR_CRC_mask) === `ERR_CRC_mask) else begin
					$display("Test FAILED - expected ERR_CRC");
					$display("Received ERR_FLAGS: %b", ALU_out.ERR_FLAGS);
					test_result = "FAILED";
				end;
			end

			else if(ALU_in.ERR_OP) begin
				CHK_ERR_OP : assert((ALU_out.ERR_FLAGS & `ERR_OP_mask) === `ERR_OP_mask) else begin
					$display("Test FAILED - expected ERR_OP");
					$display("Received ERR_FLAGS: %b", ALU_out.ERR_FLAGS);
					test_result = "FAILED";
				end;
			end

			CHK_ERR_PARITY : assert(ALU_out.PARITY === ALU_exp_out.PARITY) else begin
				$display("Test FAILED - invalid parity bit");
				$display("Received parity: %b", ALU_out.PARITY);
				test_result = "FAILED";
			end;
		end
//      end
//  bfm.chk_flag = 1'b0;
	endfunction

	function void write(ALU_output_t t);
		ALU_output_t predicted_out;

		ALU_input_t cmd;
		cmd.op_mode = nop_op;

		do
			if (!cmd_f.try_get(cmd))
				$fatal(1, "Missing command in self checker");
		while ((cmd.op_mode == nop_op) || (cmd.op_mode == rst_op));

		predicted_out = get_expected(cmd);
		check_results(cmd, t, predicted_out);
	endfunction

	function void report_phase(uvm_phase phase);
		if(test_result == "PASSED")begin
			$display("\n####################################################\n");
			$display("            #     ################       _   _           ");
			$display("           #      #              #       *   *           ");
			$display("      #   #       #    PASSED    #         |             ");
			$display("       # #        #              #       \\___/          ");
			$display("        #         ################                       ");
			$display("\n####################################################\n");
		end else begin
			$display("\n####################################################\n");
			$display("      #   #       ################       _   _           ");
			$display("       # #        #              #       *   *           ");
			$display("        #         #    FAILED    #        ___             ");
			$display("       # #        #              #       /   \\          ");
			$display("      #   #       ################                       ");
			$display("\n####################################################\n");
		end
	endfunction

endclass : scoreboard