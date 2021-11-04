`timescale 1ns/1ps
module tester(alu_bfm bfm);
	import alu_pkg::*;
		
	//------------------------------------------------------------------------------
	// Data generation
	//------------------------------------------------------------------------------
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
//			test_result = "FAILED";
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
//			test_result = "FAILED";
		end
		
		return data_tmp;
	endfunction : get_data_len
	
	function void ALU_input_generate();
		bfm.ALU_input.A = get_data();
		bfm.ALU_input.B = get_data();
		bfm.ALU_input.OP = get_op();
		bfm.ALU_input.CRC = get_crc({bfm.ALU_input.B, bfm.ALU_input.A, 1'b1, bfm.ALU_input.OP});	
		bfm.ALU_input.A_nr_of_bytes = get_data_len();
		bfm.ALU_input.B_nr_of_bytes = get_data_len();
	endfunction : ALU_input_generate
	
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
	
	//------------------------------------------------------------------------------
	// Tester main
	//------------------------------------------------------------------------------
	initial begin : tester
		bfm.reset_dut();
	    repeat (100_000) begin : tester_main
		    wait(bfm.chk_flag == 1'b0);
		    bfm.op_mode = get_op_mode();
		    case (bfm.op_mode) // handle of nop and rst
	            nop_op: begin : case_nop_op
	                @(negedge bfm.clk);
	            end
	            
	            rst_op: begin : case_rst_op
	                bfm.reset_dut();
	            end
	            
	            default: begin : case_default
		    		ALU_input_generate();
				    bfm.send_message(bfm.ALU_input);
					bfm.chk_flag = 1'b1;		    
	            end
		    endcase
	        if($get_coverage() == 100) break;
	    end
	    $finish;
	end : tester
endmodule