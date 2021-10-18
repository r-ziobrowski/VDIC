`timescale 1ns/1ps
`define ERR_DATA_mask 	(6'b100100)
`define ERR_CRC_mask 	(6'b010010)
`define ERR_OP_mask 	(6'b001001)


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
	
	bit ERROR_out;
	ALU_input_t ALU_input;
	ERR_FLAGS_expected_t ERR_FLAGS_expected;
	ALU_output_t ALU_output;
	ALU_ERR_output_t ALU_ERR_output;
	
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

	task read_message(output ALU_output_t ALU_out, ALU_ERR_output_t ALU_ERR_out, bit is_ERROR);
		automatic bit [7:0] data_tmp;
		automatic bit is_cmd = 1'b0;
		is_ERROR = 1'b0;
		ALU_out.FLAGS = 4'h0;
		ALU_ERR_out.ERR_FLAGS = 6'h0;
		ALU_ERR_out.PARITY = 1'b0;
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

function bit [2:0] get_op();
    bit [2:0] op_choice;
    op_choice = $random;
	
	if (!(op_choice inside {3'b000, 3'b001, 3'b100, 3'b101})) begin
		ERR_FLAGS_expected.ERR_OP= 1'b1;
		ERR_FLAGS_expected.ERR_expected = 1'b1;
	end else begin
		ERR_FLAGS_expected.ERR_OP= 1'b0;
	end
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
	    ERR_FLAGS_expected.ERR_CRC = 1'b1;
		ERR_FLAGS_expected.ERR_expected = 1'b1;
        return crc_rand;
    end else begin
	    ERR_FLAGS_expected.ERR_CRC = 1'b0;
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
	
	if((ALU_input.A_nr_of_bytes != 3'h4) || (ALU_input.B_nr_of_bytes != 3'h4)) begin
		ERR_FLAGS_expected.ERR_DATA = 1'b1;
		ERR_FLAGS_expected.ERR_expected = 1'b1;
	end else begin
		ERR_FLAGS_expected.ERR_DATA = 1'b0;
	end 
endfunction : ALU_input_generate

//------------------------------------------------------------------------------
// calculate expected result
//------------------------------------------------------------------------------
function logic [31:0] get_expected(bit [31:0] A, bit [31:0] B, operation_t op_set);
    bit [31:0] ret;
    `ifdef DEBUG
    $display("%0t DEBUG: get_expected(%0d,%0d,%0d)",$time, A, B, op_set);
    `endif
    case(op_set)
        and_op : ret = B & A;
        add_op : ret = B + A;
        or_op  : ret = B | A;
        sub_op : ret = B - A;
        default: begin
            $display("%0t INTERNAL ERROR. get_expected: unexpected case argument: %s", $time, op_set);
            test_result = "FAILED";
            return -1;
        end
    endcase
    return ret;
endfunction

//------------------------------------------------------------------------------
// Tester main
//------------------------------------------------------------------------------
	initial begin : tester
	reset_dut();
    repeat (1_000_000) begin : tester_main
		ERR_FLAGS_expected.ERR_expected = 1'b0;
	    ALU_input_generate();
	    send_message(ALU_input);
	    read_message(ALU_output, ALU_ERR_output, ERROR_out);
	    
	    assert (ERR_FLAGS_expected.ERR_expected === ERROR_out) else begin
		    $display("Test FAILED - did not return ERR_FLAGS");
		    test_result = "FAILED";
		    continue;
	    end;
	    
	    if (!ERROR_out) begin
            //------------------------------------------------------------------------------
            // temporary data check - scoreboard will do the job later
            //------------------------------------------------------------------------------
            automatic bit [31:0] expected = get_expected(ALU_input.A, ALU_input.B, operation_t'(ALU_input.OP));
            assert(ALU_output.C === expected) begin
                `ifdef DEBUG
                $display("Test passed for A=%0d B=%0d op_set=%0b", A, B, (operation_t'(ALU_input.OP)));
                `endif
            end else begin
                $display("Test FAILED for A=%0h B=%0h op_set=%0b", ALU_input.A, ALU_input.B, (operation_t'(ALU_input.OP)));
                $display("Expected: %h  received: %h", expected, ALU_output.C);
                test_result = "FAILED";
            end;
            
	    end else begin //ERROR_out
		    if(ERR_FLAGS_expected.ERR_DATA) begin
			   assert((ALU_ERR_output.ERR_FLAGS & `ERR_DATA_mask) === `ERR_DATA_mask) else begin
                    $display("Test FAILED - expected ERR_DATA");
                    $display("Received ERR_FLAGS %b", ALU_ERR_output.ERR_FLAGS);
                    test_result = "FAILED";
                end;
		    end
		    
//		    if(ERR_FLAGS_expected.ERR_CRC) begin
//			   assert((ALU_ERR_output.ERR_FLAGS & `ERR_CRC_mask) === `ERR_CRC_mask) else begin
//                    $display("Test FAILED - expected ERR_CRC");
//                    $display("Received ERR_FLAGS %b", ALU_ERR_output.ERR_FLAGS);
//                    test_result = "FAILED";
//                end;
//		    end
//		    
//		    if(ERR_FLAGS_expected.ERR_OP) begin
//		   		assert((ALU_ERR_output.ERR_FLAGS & `ERR_OP_mask) === `ERR_OP_mask) else begin
//                    $display("Test FAILED - expected ERR_OP");
//                    $display("Received ERR_FLAGS %b", ALU_ERR_output.ERR_FLAGS);
//                    test_result = "FAILED";
//                end;
//			end
		end
    end
    $finish;
end : tester

//------------------------------------------------------------------------------
// reset task
//------------------------------------------------------------------------------
task reset_dut();
`ifdef DEBUG
	$display("%0t DEBUG: reset_alu", $time);
`endif
	sin = 1'b1;
	rst_n = 1'b0;
	@(negedge clk);
	rst_n = 1'b1;
endtask : reset_dut

//------------------------------------------------------------------------------
// Temporary. The scoreboard data will be later used.
final begin : finish_of_the_test
    $display("Test %s.",test_result);
end
//------------------------------------------------------------------------------
endmodule