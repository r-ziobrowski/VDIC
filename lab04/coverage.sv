`timescale 1ns/1ps
module coverage(alu_bfm bfm);
	import alu_pkg::*;

	bit [31:0] A;
	bit [31:0] B;
	bit [2:0] OP;
	bit [1:0] op_mode;
	bit [2:0] A_nr_of_bytes;
	bit [2:0] B_nr_of_bytes;
	bit ERR_CRC;
	
	// Covergroup checking the op codes and their sequences
	covergroup op_cov;
	
	    option.name = "cg_op_cov";
		
		A_alu_op : coverpoint OP {
		    
	        // #A1 test all operations
	        bins A1_all_op[] = {and_op, or_op, add_op, sub_op}; //TODO check this and fix others if works
		}
	
	    A_alu_op_comb : coverpoint OP {
	
	        // #A4 run every operation after every operation
	        bins A4_evr_after_evr[] = (and_op, or_op, add_op, sub_op => and_op, or_op, add_op, sub_op);
	
	        // #A5 two operations in row
	        bins A5_twoops[] = (and_op, or_op, add_op, sub_op [* 2]);
	    }
	    
	    A_op_mode : coverpoint op_mode {
			bins A_rst_2_def = (rst_op => def_op);
		    
			bins A_def_2_rst = (def_op => rst_op);
	    }
	    
	    A_rst_op: cross A_alu_op, A_op_mode {
	
	        // #A2 test all operations after reset
	        bins A2_rst_add      = (binsof(A_alu_op.A1_all_op) intersect {add_op} && binsof(A_op_mode.A_rst_2_def));
	        bins A2_rst_and      = (binsof(A_alu_op.A1_all_op) intersect {and_op} && binsof(A_op_mode.A_rst_2_def));
	        bins A2_rst_or       = (binsof(A_alu_op.A1_all_op) intersect {or_op}  && binsof(A_op_mode.A_rst_2_def));
	        bins A2_rst_sub      = (binsof(A_alu_op.A1_all_op) intersect {sub_op} && binsof(A_op_mode.A_rst_2_def));
	
	        // #A3 test reset after all operations
	        bins A3_add_rst      = (binsof(A_alu_op.A1_all_op) intersect {add_op} && binsof(A_op_mode.A_def_2_rst));
	        bins A3_and_rst      = (binsof(A_alu_op.A1_all_op) intersect {and_op} && binsof(A_op_mode.A_def_2_rst));
	        bins A3_or_rst       = (binsof(A_alu_op.A1_all_op) intersect {or_op}  && binsof(A_op_mode.A_def_2_rst));
	        bins A3_sub_rst      = (binsof(A_alu_op.A1_all_op) intersect {sub_op} && binsof(A_op_mode.A_def_2_rst));
	    }
	
	endgroup
	
	// Covergroup checking for min and max arguments of the ALU
	covergroup zeros_or_ones_on_ops;
	
	    option.name = "cg_zeros_or_ones_on_ops";
	
	    all_ops : coverpoint OP {
	        bins all_op[] = {and_op, or_op, add_op, sub_op};
	    }
	
	    a_leg: coverpoint A {
	        bins zeros = {'h0000_0000};
	        bins others= {['h0000_0001:'hFFFF_FFFE]};
	        bins ones  = {'hFFFF_FFFF};
	    }
	
	    b_leg: coverpoint B {
	        bins zeros = {'h0000_0000};
	        bins others= {['h0000_0001:'hFFFF_FFFE]};
	        bins ones  = {'hFFFF_FFFF};
	    }
	
	    B_op_00_FF: cross a_leg, b_leg, all_ops {
	
	        // #B1 simulate all zero input for all the operations
	        bins B1_add_00          = binsof (all_ops) intersect {add_op} &&
	        (binsof (a_leg.zeros) || binsof (b_leg.zeros));
	
	        bins B1_and_00          = binsof (all_ops) intersect {and_op} &&
	        (binsof (a_leg.zeros) || binsof (b_leg.zeros));
	
	        bins B1_or_00         	= binsof (all_ops) intersect {or_op} &&
	        (binsof (a_leg.zeros) || binsof (b_leg.zeros));
	
	        bins B1_sub_00          = binsof (all_ops) intersect {sub_op} &&
	        (binsof (a_leg.zeros) || binsof (b_leg.zeros));
	
	        // #B2 simulate all one input for all the operations
	        bins B2_add_FF          = binsof (all_ops) intersect {add_op} &&
	        (binsof (a_leg.ones) || binsof (b_leg.ones));
	
	        bins B2_and_FF          = binsof (all_ops) intersect {and_op} &&
	        (binsof (a_leg.ones) || binsof (b_leg.ones));
	
	        bins B2_or_FF          	= binsof (all_ops) intersect {or_op} &&
	        (binsof (a_leg.ones) || binsof (b_leg.ones));
	
	        bins B2_sub_FF          = binsof (all_ops) intersect {sub_op} &&
	        (binsof (a_leg.ones) || binsof (b_leg.ones));
	
	        ignore_bins others_only =
	        binsof(a_leg.others) && binsof(b_leg.others);
	    }
	
	endgroup
	
	// Covergroup checking error handling
	covergroup err_cov;
	
	    option.name = "cg_err_cov";
	
	    err_op : coverpoint OP {
		    // #C1 test all invalid operations
		    bins C1_range[] = {'b000, 'b111};
	        ignore_bins inv_ops[] = {and_op, or_op, add_op, sub_op};
	    }
	    
	    err_crc : coverpoint ERR_CRC {
		    // #C2 test invalid CRC
		    bins C2_err_crc = {1'b1};
	    }
	    
	    err_data_A : coverpoint A_nr_of_bytes {
		    // #C3 test sending incorrect amount of data
		    bins C3_inv_range_A[] = {[3'd0 : 3'd3]};
	    }
	        
	    err_data_B : coverpoint B_nr_of_bytes {
		    // #C3 test sending incorrect amount of data
		    bins C3_inv_range_B[] = {[3'd0 : 3'd3]};
	    }
	
	endgroup
	
	op_cov                      oc;
	zeros_or_ones_on_ops        c_00_FF;
	err_cov						err_c;
	
	initial begin : coverage
	    oc      = new();
	    c_00_FF = new();
		err_c	= new();
	    forever begin : sample_cov
	        @(posedge bfm.clk);
	        if(bfm.chk_flag || !bfm.rst_n) begin
	        	A 				= bfm.ALU_input.A;
				B 				= bfm.ALU_input.B;
				OP 				= bfm.ALU_input.OP;
				op_mode 		= bfm.op_mode;
				A_nr_of_bytes 	= bfm.ALU_input.A_nr_of_bytes;
				B_nr_of_bytes 	= bfm.ALU_input.A_nr_of_bytes;
				ERR_CRC 		= bfm.ERR_CRC;
	            oc.sample();
	            c_00_FF.sample();
		        err_c.sample();
	        end
	    end
	end : coverage
	
endmodule