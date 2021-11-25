class scoreboard extends uvm_component;

    `uvm_component_utils(scoreboard)

    virtual alu_bfm bfm;
	
	protected string test_result = "PASSED";

	protected bit ERROR_out;
	protected ERR_FLAGS_expected_t ERR_FLAGS_expected;
	protected ALU_output_t ALU_output;
	protected ALU_output_t ALU_output_expected;
	protected ALU_ERR_output_t ALU_ERR_output;
	protected ALU_ERR_output_t ALU_ERR_output_expected;

	//------------------------------------------------------------------------------
	// Expected result generation
	//------------------------------------------------------------------------------
	
	protected task get_expected(input ALU_input_t ALU_in, output ALU_output_t ALU_out, output ERR_FLAGS_expected_t ERR_FLAGS_exp, output ALU_ERR_output_t ALU_ERR_out);
		automatic bit [3:0] crc_in_tmp = CRC_input({ALU_in.B, ALU_in.A, 1'b1, ALU_in.OP}, 1'b0);
		automatic bit [32:0] C_tmp_carry;
		automatic bit signed [31:0] C_tmp;
		automatic bit overflow;

		ERR_FLAGS_exp.ERR_expected = 1'b0;
		ERR_FLAGS_exp.ERR_DATA = 1'b0;
		ERR_FLAGS_exp.ERR_OP = 1'b0;
		ERR_FLAGS_exp.ERR_CRC = 1'b0;

		if((ALU_in.A_nr_of_bytes != 3'h4) || (ALU_in.B_nr_of_bytes != 3'h4)) begin : ERR_DATA_check
			ERR_FLAGS_exp.ERR_DATA = 1'b1;
			ERR_FLAGS_exp.ERR_expected = 1'b1;
		end
		else if (ALU_in.CRC != crc_in_tmp) begin : ERR_CRC_check
			ERR_FLAGS_exp.ERR_CRC = 1'b1;
			ERR_FLAGS_exp.ERR_expected = 1'b1;
		end
		else if (!(ALU_in.OP inside {3'b000, 3'b001, 3'b100, 3'b101})) begin : ERR_OP_check
			ERR_FLAGS_exp.ERR_OP = 1'b1;
			ERR_FLAGS_exp.ERR_expected = 1'b1;
		end

		bfm.ERR_CRC = ERR_FLAGS_exp.ERR_CRC;

		ALU_ERR_out.ERR_FLAGS = {   ERR_FLAGS_exp.ERR_DATA,
			ERR_FLAGS_exp.ERR_CRC,
			ERR_FLAGS_exp.ERR_OP,
			ERR_FLAGS_exp.ERR_DATA,
			ERR_FLAGS_exp.ERR_CRC,
			ERR_FLAGS_exp.ERR_OP};

		ALU_ERR_out.PARITY = ^{1'b1, ALU_ERR_out.ERR_FLAGS};

		`ifdef DEBUG
		$display("%0t DEBUG: get_expected(%0d,%0d,%0d)",$time, ALU_in.A, ALU_in.B, ALU_in.OP);
		`endif


		if(!ERR_FLAGS_exp.ERR_expected) begin : RESULT_calc
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
	endtask

    function new (string name, uvm_component parent);
        super.new(name, parent);
    endfunction : new

    function void build_phase(uvm_phase phase);
        if(!uvm_config_db #(virtual alu_bfm)::get(null, "*","bfm", bfm))
            $fatal(1,"Failed to get BFM");
    endfunction : build_phase

    task run_phase(uvm_phase phase);
        forever begin : scoreboard
			@(negedge bfm.clk)
				if (bfm.chk_flag) begin
					bfm.read_message(ALU_output, ALU_ERR_output, ERROR_out);
					get_expected(bfm.ALU_input, ALU_output_expected, ERR_FLAGS_expected, ALU_ERR_output_expected);

					CHK_ERROR_EXPECTED : assert (ERR_FLAGS_expected.ERR_expected === ERROR_out) else begin
						$display("Test FAILED - did not return ERR_FLAGS");
						test_result = "FAILED";
					end;

					if (!ERROR_out) begin
						CHK_RESULT : assert(ALU_output.C === ALU_output_expected.C) begin
						`ifdef DEBUG
							$display("Test passed for A=%0d B=%0d op_set=%0b", bfm.ALU_input.A, bfm.ALU_input.B, (operation_t'(bfm.ALU_input.OP)));
						`endif
						end else begin
							$display("Test FAILED for A=%0h B=%0h op_set=%0b", bfm.ALU_input.A, bfm.ALU_input.B, (operation_t'(bfm.ALU_input.OP)));
							$display("Expected: %h  received: %h", ALU_output_expected.C, ALU_output.C);
							test_result = "FAILED";
						end;

						CHK_FLAGS : assert(ALU_output.FLAGS === ALU_output_expected.FLAGS) begin
						`ifdef DEBUG
							$display("Test passed for A=%0d B=%0d op_set=%0b", bfm.ALU_input.A, bfm.ALU_input.B, (operation_t'(bfm.ALU_input.OP)));
						`endif
						end else begin
							$display("Test FAILED for A=%0h B=%0h op_set=%0b", bfm.ALU_input.A, bfm.ALU_input.B, (operation_t'(bfm.ALU_input.OP)));
							$display("Expected flags: %4b  received: %4b", ALU_output_expected.FLAGS, ALU_output.FLAGS);
							test_result = "FAILED";
						end;

						CHK_CRC : assert(ALU_output.CRC === ALU_output_expected.CRC) begin
						`ifdef DEBUG
							$display("Test passed for A=%0d B=%0d op_set=%0b", bfm.ALU_input.A, bfm.ALU_input.B, (operation_t'(bfm.ALU_input.OP)));
						`endif
						end else begin
							$display("Test FAILED for A=%0h B=%0h op_set=%0b", bfm.ALU_input.A, bfm.ALU_input.B, (operation_t'(bfm.ALU_input.OP)));
							$display("Expected CRC: %3b  received: %3b", ALU_output_expected.CRC, ALU_output.CRC);
							test_result = "FAILED";
						end;

					end else begin // ERROR_out
						if(ERR_FLAGS_expected.ERR_DATA) begin
							CHK_ERR_DATA : assert((ALU_ERR_output.ERR_FLAGS & `ERR_DATA_mask) === `ERR_DATA_mask) else begin
								$display("Test FAILED - expected ERR_DATA");
								$display("Received ERR_FLAGS: %b", ALU_ERR_output.ERR_FLAGS);
								test_result = "FAILED";
							end;
						end

						else if(ERR_FLAGS_expected.ERR_CRC) begin
							CHK_ERR_CRC : assert((ALU_ERR_output.ERR_FLAGS & `ERR_CRC_mask) === `ERR_CRC_mask) else begin
								$display("Test FAILED - expected ERR_CRC");
								$display("Received ERR_FLAGS: %b", ALU_ERR_output.ERR_FLAGS);
								test_result = "FAILED";
							end;
						end

						else if(ERR_FLAGS_expected.ERR_OP) begin
							CHK_ERR_OP : assert((ALU_ERR_output.ERR_FLAGS & `ERR_OP_mask) === `ERR_OP_mask) else begin
								$display("Test FAILED - expected ERR_OP");
								$display("Received ERR_FLAGS: %b", ALU_ERR_output.ERR_FLAGS);
								test_result = "FAILED";
							end;
						end

						CHK_ERR_PARITY : assert(ALU_ERR_output.PARITY === ALU_ERR_output_expected.PARITY) else begin
							$display("Test FAILED - invalid parity bit");
							$display("Received parity: %b", ALU_ERR_output.PARITY);
							test_result = "FAILED";
						end;
					end
				end
			bfm.chk_flag = 1'b0;
		end : scoreboard
    endtask : run_phase

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