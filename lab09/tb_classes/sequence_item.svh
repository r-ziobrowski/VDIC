class sequence_item extends uvm_sequence_item;

	rand bit [31:0] A;
	rand bit [31:0] B;
	rand bit [2:0] OP;
	rand bit [3:0] CRC;
	rand bit [2:0] A_nr_of_bytes;
	rand bit [2:0] B_nr_of_bytes;
	rand op_mode_t op_mode;
	
    ALU_output_t ALU_out;

//------------------------------------------------------------------------------
// Macros providing copy, compare, pack, record, print functions.
// Individual functions can be enabled/disabled with the last
// `uvm_field_*() macro argument.
// Note: this is an expanded version of the `uvm_object_utils with additional
//       fields added. DVT has a dedicated editor for this (ctrl-space).
//------------------------------------------------------------------------------

`uvm_object_utils_begin(sequence_item)
	`uvm_field_int(A, UVM_ALL_ON | UVM_DEC)
	`uvm_field_int(B, UVM_ALL_ON | UVM_DEC)
	`uvm_field_int(OP, UVM_DEFAULT)
	`uvm_field_int(CRC, UVM_DEFAULT)
	`uvm_field_int(A_nr_of_bytes, UVM_DEFAULT)
	`uvm_field_int(B_nr_of_bytes, UVM_DEFAULT)
	`uvm_field_enum(op_mode_t, op_mode, UVM_DEFAULT)
	`uvm_field_int(ALU_out, UVM_DEFAULT)
`uvm_object_utils_end

//------------------------------------------------------------------------------
// constraints
//------------------------------------------------------------------------------

	constraint data_len {
		A_nr_of_bytes dist {[3'h0 : 3'h3] :/ 25, 3'h4 := 75};
		B_nr_of_bytes dist {[3'h0 : 3'h3] :/ 25, 3'h4 := 75};
	}

	constraint crc_val {
		CRC dist {[4'h0 : 4'hF] :/ 25, CRC_input({B, A, 1'b1, OP}, 1'b0) := 75};
	}

//------------------------------------------------------------------------------
// constructor
//------------------------------------------------------------------------------

    function new(string name = "sequence_item");
        super.new(name);
    endfunction : new

//------------------------------------------------------------------------------
// convert2string 
//------------------------------------------------------------------------------
	function string convert2string();
		string s;
		s = $sformatf("A: %8h B: %8h OP: %h CRC: %h A_nr_of_bytes: %h B_nr_of_bytes: %h op_mode: %s ALU_output: %p", A, B, OP, CRC, A_nr_of_bytes, B_nr_of_bytes, op_mode.name(), ALU_out);
		return s;
	endfunction : convert2string

endclass : sequence_item


