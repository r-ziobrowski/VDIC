/******************************************************************************
* DVT CODE TEMPLATE: sequence item
* Created by rziobrowski on Jan 20, 2022
* uvc_company = rz, uvc_name = alu
*******************************************************************************/

`ifndef IFNDEF_GUARD_rz_alu_item
`define IFNDEF_GUARD_rz_alu_item

//------------------------------------------------------------------------------
//
// CLASS: rz_alu_item
//
//------------------------------------------------------------------------------

class  rz_alu_item extends uvm_sequence_item;

    // This bit should be set when you want all the fields to be
    // constrained to some default values or ranges at randomization
    rand bit default_values;


    rand bit [31:0] A;
    rand bit [31:0] B;
    rand bit [2:0] OP;
    rand bit [3:0] CRC;
    rand bit [2:0] A_nr_of_bytes;
    rand bit [2:0] B_nr_of_bytes;
    rand op_mode_t op_mode;

    ALU_output_t ALU_out;

    constraint data_len {
        A_nr_of_bytes dist {[3'h0 : 3'h3] :/ 25, 3'h4 := 75};
        B_nr_of_bytes dist {[3'h0 : 3'h3] :/ 25, 3'h4 := 75};
    }

    constraint crc_val {
        CRC dist {[4'h0 : 4'hF] :/ 25, CRC_input({B, A, 1'b1, OP}, 1'b0) := 75};
    }
    `uvm_object_utils_begin(rz_alu_item)
        `uvm_field_int(A, UVM_ALL_ON | UVM_DEC)
        `uvm_field_int(B, UVM_ALL_ON | UVM_DEC)
        `uvm_field_int(OP, UVM_DEFAULT)
        `uvm_field_int(CRC, UVM_DEFAULT)
        `uvm_field_int(A_nr_of_bytes, UVM_DEFAULT)
        `uvm_field_int(B_nr_of_bytes, UVM_DEFAULT)
        `uvm_field_enum(op_mode_t, op_mode, UVM_DEFAULT)
        `uvm_field_int(ALU_out, UVM_HEX)
    `uvm_object_utils_end

    function new (string name = "rz_alu_item");
        super.new(name);
    endfunction : new

    // HINT UVM field macros don't work with unions and structs, you may have to override rz_alu_item.do_copy().
    virtual function void do_copy(uvm_object rhs);
        super.do_copy(rhs);
    endfunction : do_copy

    // HINT UVM field macros don't work with unions and structs, you may have to override rz_alu_item.do_pack().
    virtual function void do_pack(uvm_packer packer);
        super.do_pack(packer);
    endfunction : do_pack

    // HINT UVM field macros don't work with unions and structs, you may have to override rz_alu_item.do_unpack().
    virtual function void do_unpack(uvm_packer packer);
        super.do_unpack(packer);
    endfunction : do_unpack

    // HINT UVM field macros don't work with unions and structs, you may have to override rz_alu_item.do_print().
    virtual function void do_print(uvm_printer printer);
        super.do_print(printer);
    endfunction : do_print

endclass :  rz_alu_item

`endif // IFNDEF_GUARD_rz_alu_item
