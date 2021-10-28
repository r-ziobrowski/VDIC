`timescale 1ns/1ps

`define ERR_DATA_mask 	(6'b100100)
`define ERR_CRC_mask 	(6'b010010)
`define ERR_OP_mask 	(6'b001001)

module top;

typedef enum bit[1:0] {
	nop_op = 2'b00,
	rst_op = 2'b01,
	def_op = 2'b10
} op_mode_t;

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
	bit [2:0] A_nr_of_bytes;
	bit [2:0] B_nr_of_bytes;
} ALU_input_t;

typedef struct {
	bit [31:0] C;
	bit [3:0] FLAGS;
	bit [2:0] CRC;
} ALU_output_t;

typedef struct {
	bit [5:0] ERR_FLAGS;
	bit PARITY;
} ALU_ERR_output_t;

typedef struct {
	bit ERR_DATA;
	bit ERR_CRC;
	bit ERR_OP;
	bit ERR_expected;
} ERR_FLAGS_expected_t;
	
//------------------------------------------------------------------------------
// DUT instantiation
//------------------------------------------------------------------------------

bit clk;
bit rst_n;
bit sin;
wire sout;

bit chk_flag = 1'b0;
bit ERROR_out;
op_mode_t op_mode;
ALU_input_t ALU_input;
ERR_FLAGS_expected_t ERR_FLAGS_expected;
ALU_output_t ALU_output;
ALU_output_t ALU_output_expected;
ALU_ERR_output_t ALU_ERR_output;

string test_result = "PASSED";


mtm_Alu DUT (
		.clk  (clk),    //posedge active clock
		.rst_n(rst_n),  //synchronous reset active low
		.sin  (sin),    //serial data input
		.sout (sout)    //serial data output
	);

//------------------------------------------------------------------------------
// Coverage block
//------------------------------------------------------------------------------

// Covergroup checking the op codes and their sequences
covergroup op_cov;

    option.name = "cg_op_cov";
	
	A_alu_op : coverpoint ALU_input.OP {
	    
        // #A1 test all operations
        bins A1_all_op[] = {[and_op : sub_op]};
	}

    A_alu_op_comb : coverpoint ALU_input.OP {

        // #A4 run every operation after every operation
        bins A4_evr_after_evr[] = ([and_op : sub_op] => [and_op : sub_op]);

        // #A5 two operations in row
        bins A5_twoops[] = ([and_op : sub_op] [* 2]);
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

    all_ops : coverpoint ALU_input.OP {
        bins all_op[] = {[and_op : sub_op]};
    }

    a_leg: coverpoint ALU_input.A {
        bins zeros = {'h0000_0000};
        bins others= {['h0000_0001:'hFFFF_FFFE]};
        bins ones  = {'hFFFF_FFFF};
    }

    b_leg: coverpoint ALU_input.B {
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

    err_op : coverpoint ALU_input.OP {
	    // #C1 test all invalid operations
	    bins C1_range[] = {'b000, 'b111};
        ignore_bins inv_ops[] = {[and_op : sub_op]};
    }
    
    err_crc : coverpoint ERR_FLAGS_expected.ERR_CRC {
	    // #C2 test invalid CRC
	    bins C2_err_crc = {1'b1};
    }
    
    err_data_A : coverpoint ALU_input.A_nr_of_bytes {
	    // #C3 test sending incorrect amount of data
	    bins C3_inv_range_A[] = {[3'd0 : 3'd3]};
    }
        
    err_data_B : coverpoint ALU_input.B_nr_of_bytes {
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
        @(posedge clk);
        if(chk_flag || !rst_n) begin
            oc.sample();
            c_00_FF.sample();
	        err_c.sample();
        end
    end
end : coverage

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
// Serial write
//------------------------------------------------------------------------------
task serial_write(bit [7:0] data_in, bit is_cmd);
	automatic bit [10:0] serial_data = {1'b0, is_cmd, data_in, 1'b1};
	foreach(serial_data[i])begin
		@(negedge clk);
		sin = serial_data[i];
	end
endtask : serial_write

task send_message(ALU_input_t ALU_in);
	for(int i = ALU_in.B_nr_of_bytes; i > 0; i--)begin
		serial_write(ALU_in.B[i*8-1 -: 8], 1'b0);
	end
	for(int i = ALU_in.A_nr_of_bytes; i > 0; i--)begin
		serial_write(ALU_in.A[i*8-1 -: 8], 1'b0);
	end
	serial_write({1'b0, ALU_in.OP, ALU_in.CRC}, 1'b1);
endtask : send_message
	
//------------------------------------------------------------------------------
// Serial read
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

task read_message(output ALU_output_t ALU_out, ALU_ERR_output_t ALU_ERR_out, bit is_ERROR);
	automatic bit [7:0] data_tmp;
	automatic bit is_cmd = 1'b0;
	
	is_ERROR = 1'b0;
	
	ALU_ERR_out.ERR_FLAGS = 6'h0;
	ALU_ERR_out.PARITY = 1'b0;
	
	ALU_out.C = 32'h0;
	ALU_out.CRC = 3'h0;
	ALU_out.FLAGS = 4'h0;
	
	for(int i = $rtoi($ceil($size(ALU_out.C)/8)); i > 0; i--)begin
		serial_read(data_tmp, is_cmd);
		if (is_cmd == 1'b1)begin
			is_ERROR = 1'b1;
			ALU_ERR_out.ERR_FLAGS = data_tmp[6 -: 6];
			ALU_ERR_out.PARITY = data_tmp[0];
			break;
		end else begin
			ALU_out.C[i*8-1 -: 8] = data_tmp;
		end			
	end
	if (!is_ERROR) begin
		serial_read(data_tmp, is_cmd);
		ALU_out.FLAGS = data_tmp[6:3];
		ALU_out.CRC = data_tmp[2:0];
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
		test_result = "FAILED";
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
		test_result = "FAILED";
	end
	
	return data_tmp;
endfunction : get_data_len

function void ALU_input_generate();
	ALU_input.A = get_data();
	ALU_input.B = get_data();
	ALU_input.OP = get_op();
	ALU_input.CRC = get_crc({ALU_input.B, ALU_input.A, 1'b1, ALU_input.OP});	
	ALU_input.A_nr_of_bytes = get_data_len();
	ALU_input.B_nr_of_bytes = get_data_len();
endfunction : ALU_input_generate

function op_mode_t get_op_mode();
    bit [1:0] op_mode_choice;
    op_mode_choice = 2'($random);
    case (op_mode_choice)
        2'b00 : return nop_op;
        2'b01 : return rst_op;
        2'b10 : return def_op;
        2'b11 : return def_op;
    endcase // case (op_mode_choice)
endfunction

//------------------------------------------------------------------------------
// Expected result generation
//------------------------------------------------------------------------------
task get_expected(input ALU_input_t ALU_in, output ALU_output_t ALU_out, output ERR_FLAGS_expected_t ERR_FLAGS_exp);
	automatic bit [3:0] crc_in_tmp = CRC_input({ALU_in.B, ALU_in.A, 1'b1, ALU_in.OP}, 1'b0);
	
	ERR_FLAGS_exp.ERR_expected = 1'b0;
	
	if((ALU_in.A_nr_of_bytes != 3'h4) || (ALU_in.B_nr_of_bytes != 3'h4)) begin : ERR_DATA_check
		ERR_FLAGS_exp.ERR_DATA = 1'b1;
		ERR_FLAGS_exp.ERR_expected = 1'b1;
	end else begin
		ERR_FLAGS_exp.ERR_DATA = 1'b0;
	end 
	
	if (!(ALU_in.OP inside {3'b000, 3'b001, 3'b100, 3'b101})) begin : ERR_OP_check
		ERR_FLAGS_exp.ERR_OP = 1'b1;
		ERR_FLAGS_exp.ERR_expected = 1'b1;
	end else begin
		ERR_FLAGS_exp.ERR_OP= 1'b0;
	end
	
    if (ALU_in.CRC != crc_in_tmp) begin : ERR_CRC_check
	    ERR_FLAGS_exp.ERR_CRC = 1'b1;
		ERR_FLAGS_exp.ERR_expected = 1'b1;
    end else begin
	    ERR_FLAGS_exp.ERR_CRC = 1'b0;
    end
	
	
    `ifdef DEBUG
    $display("%0t DEBUG: get_expected(%0d,%0d,%0d)",$time, ALU_in.A, ALU_in.B, ALU_in.OP);
    `endif
    
    
    if(!ERR_FLAGS_exp.ERR_expected) begin : RESULT_calc
	    case(ALU_in.OP)
	        and_op : ALU_out.C = ALU_in.B & ALU_in.A;
	        add_op : ALU_out.C = ALU_in.B + ALU_in.A;
	        or_op  : ALU_out.C = ALU_in.B | ALU_in.A;
	        sub_op : ALU_out.C = ALU_in.B - ALU_in.A;
	        default: begin
	            $display("%0t INTERNAL ERROR. get_expected: unexpected case argument: %s", $time, ALU_in.OP);
	            test_result = "FAILED";
	        end
	    endcase
	    
	    ALU_out.FLAGS = 4'h0;
	    
	    if(ALU_out.C < 0)  ALU_out.FLAGS[0] = 1;
	    if(ALU_out.C == 0) ALU_out.FLAGS[1] = 1;
	    
	    ALU_out.CRC = CRC_output({ALU_out.C, 1'b0, ALU_out.FLAGS}, 1'b0);
    end
endtask

//------------------------------------------------------------------------------
// Tester main
//------------------------------------------------------------------------------
initial begin : tester
	reset_dut();
    repeat (100_000) begin : tester_main
	    wait(chk_flag == 1'b0);
	    op_mode = get_op_mode();
	    case (op_mode) // handle of nop and rst
            nop_op: begin : case_nop_op
                @(negedge clk);
            end
            
            rst_op: begin : case_rst_op
                reset_dut();
            end
            
            default: begin : case_default
	    		ALU_input_generate();
			    send_message(ALU_input);
				chk_flag = 1'b1;		    
            end
	    endcase
        if($get_coverage() == 100) break;
    end
    $finish;
end : tester

//------------------------------------------------------------------------------
// reset task
//------------------------------------------------------------------------------
task reset_dut();
`ifdef DEBUG
	$display("%0t DEBUG: reset_dut", $time);
`endif
	sin = 1'b1;
	rst_n = 1'b0;
	@(negedge clk);
	rst_n = 1'b1;
endtask : reset_dut

//------------------------------------------------------------------------------
// Temporary. The scoreboard data will be later used.
//------------------------------------------------------------------------------
final begin : finish_of_the_test
    $display("Test %s.",test_result);
end
//------------------------------------------------------------------------------


//------------------------------------------------------------------------------
// Scoreboard
//------------------------------------------------------------------------------
initial
forever begin : scoreboard 
	@(negedge clk)
	if (chk_flag) begin
		read_message(ALU_output, ALU_ERR_output, ERROR_out);
		get_expected(ALU_input, ALU_output_expected, ERR_FLAGS_expected);
				    
	    CHK_ERROR_EXPECTED : assert (ERR_FLAGS_expected.ERR_expected === ERROR_out) else begin
		    $display("Test FAILED - did not return ERR_FLAGS");
		    test_result = "FAILED";
	    end;
	    
	    if (!ERROR_out) begin		    
	        CHK_RESULT : assert(ALU_output.C === ALU_output_expected.C) begin
	            `ifdef DEBUG
	            $display("Test passed for A=%0d B=%0d op_set=%0b", ALU_input.A, ALU_input.B, (operation_t'(ALU_input.OP)));
	            `endif
	        end else begin
	            $display("Test FAILED for A=%0h B=%0h op_set=%0b", ALU_input.A, ALU_input.B, (operation_t'(ALU_input.OP)));
	            $display("Expected: %h  received: %h", ALU_output_expected.C, ALU_output.C);
	            test_result = "FAILED";
	        end;
	        
	    end else begin // ERROR_out
		    if(ERR_FLAGS_expected.ERR_DATA) begin
			   CHK_ERR_DATA : assert((ALU_ERR_output.ERR_FLAGS & `ERR_DATA_mask) === `ERR_DATA_mask) else begin
	                $display("Test FAILED - expected ERR_DATA");
	                $display("Received ERR_FLAGS %b", ALU_ERR_output.ERR_FLAGS);
	                test_result = "FAILED";
	            end;
		    end
		    
		    else if(ERR_FLAGS_expected.ERR_CRC) begin
			   CHK_ERR_CRC : assert((ALU_ERR_output.ERR_FLAGS & `ERR_CRC_mask) === `ERR_CRC_mask) else begin
                    $display("Test FAILED - expected ERR_CRC");
                    $display("Received ERR_FLAGS %b", ALU_ERR_output.ERR_FLAGS);
                    test_result = "FAILED";
                end;
		    end

		    else if(ERR_FLAGS_expected.ERR_OP) begin
		   		CHK_ERR_OP : assert((ALU_ERR_output.ERR_FLAGS & `ERR_OP_mask) === `ERR_OP_mask) else begin
                    $display("Test FAILED - expected ERR_OP");
                    $display("Received ERR_FLAGS %b", ALU_ERR_output.ERR_FLAGS);
                    test_result = "FAILED";
                end;
			end
		end
	end
	chk_flag = 1'b0;
end : scoreboard
endmodule