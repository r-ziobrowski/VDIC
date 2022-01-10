`timescale 1ns/1ps
package alu_pkg;
	import uvm_pkg::*;
	`include "uvm_macros.svh"

	`define ERR_DATA_mask   (6'b100100)
	`define ERR_CRC_mask    (6'b010010)
	`define ERR_OP_mask     (6'b001001)

	typedef enum bit[1:0] {
		nop_op = 2'b00,
		rst_op = 2'b01,
		def_op = 2'b10
	} op_mode_t;

	typedef enum bit[2:0] {
		and_op = 3'b000,
		or_op  = 3'b001,
		bad1_op= 3'b010,
		bad2_op= 3'b011,
		add_op = 3'b100,
		sub_op = 3'b101,
		bad3_op= 3'b110,
		bad4_op= 3'b111
	} operation_t;

	typedef struct packed{
		bit [31:0] A;
		bit [31:0] B;
		bit [2:0] OP;
		bit [3:0] CRC;
		bit [2:0] A_nr_of_bytes;
		bit [2:0] B_nr_of_bytes;
		op_mode_t op_mode;
		bit ERR_DATA;
		bit ERR_CRC;
		bit ERR_OP;
		bit ERR_expected;
	} ALU_input_t;

	typedef struct packed{
		bit [31:0] C;
		bit [3:0] FLAGS;
		bit [2:0] CRC;
		bit is_ERROR;
		bit [5:0] ERR_FLAGS;
		bit PARITY;
	} ALU_output_t;

	typedef enum {
		COLOR_BOLD_BLACK_ON_GREEN,
		COLOR_BOLD_BLACK_ON_RED,
		COLOR_BOLD_BLACK_ON_YELLOW,
		COLOR_BOLD_BLUE_ON_WHITE,
		COLOR_BLUE_ON_WHITE,
		COLOR_DEFAULT
	} print_color;

	function void set_print_color ( print_color c );
		string ctl;
		case(c)
			COLOR_BOLD_BLACK_ON_GREEN : ctl  = "\033\[1;30m\033\[102m";
			COLOR_BOLD_BLACK_ON_RED : ctl    = "\033\[1;30m\033\[101m";
			COLOR_BOLD_BLACK_ON_YELLOW : ctl = "\033\[1;30m\033\[103m";
			COLOR_BOLD_BLUE_ON_WHITE : ctl   = "\033\[1;34m\033\[107m";
			COLOR_BLUE_ON_WHITE : ctl        = "\033\[0;34m\033\[107m";
			COLOR_DEFAULT : ctl              = "\033\[0m\n";
			default : begin
				$error("set_print_color: bad argument");
				ctl                          = "";
			end
		endcase
		$write(ctl);
	endfunction

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

`include "sequence_item.svh"

// to be converted into sequence items
`include "result_transaction.svh"

//------------------------------------------------------------------------------
// sequencer
//------------------------------------------------------------------------------

//`include "sequencer.svh"

// we can use typedef instead of the sequencer class
    typedef uvm_sequencer #(sequence_item) sequencer;

//------------------------------------------------------------------------------
// sequences
//------------------------------------------------------------------------------

`include "random_sequence.svh"
`include "minmax_sequence.svh"

//------------------------------------------------------------------------------
// testbench components (no agent here)
//------------------------------------------------------------------------------

`include "coverage.svh"
`include "scoreboard.svh"
`include "driver.svh"
`include "command_monitor.svh"
`include "result_monitor.svh"
`include "env.svh"

//------------------------------------------------------------------------------
// tests
//------------------------------------------------------------------------------

`include "alu_base_test.svh"
`include "random_test.svh"
`include "min_max_test.svh"

endpackage