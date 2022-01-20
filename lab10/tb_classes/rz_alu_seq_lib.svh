/******************************************************************************
* DVT CODE TEMPLATE: sequence library
* Created by rziobrowski on Jan 20, 2022
* uvc_company = rz, uvc_name = alu
*******************************************************************************/

`ifndef IFNDEF_GUARD_rz_alu_seq_lib
`define IFNDEF_GUARD_rz_alu_seq_lib

//------------------------------------------------------------------------------
//
// CLASS: rz_alu_base_sequence
//
//------------------------------------------------------------------------------

virtual class rz_alu_base_sequence extends uvm_sequence#(rz_alu_item);

    `uvm_declare_p_sequencer(rz_alu_sequencer)

    function new(string name="rz_alu_base_sequence");
        super.new(name);
    endfunction : new

    virtual task pre_body();
        uvm_phase starting_phase = get_starting_phase();
        if (starting_phase!=null) begin
            `uvm_info(get_type_name(),
                $sformatf("%s pre_body() raising %s objection",
                    get_sequence_path(),
                    starting_phase.get_name()), UVM_MEDIUM)
            starting_phase.raise_objection(this);
        end
    endtask : pre_body

    virtual task post_body();
        uvm_phase starting_phase = get_starting_phase();
        if (starting_phase!=null) begin
            `uvm_info(get_type_name(),
                $sformatf("%s post_body() dropping %s objection",
                    get_sequence_path(),
                    starting_phase.get_name()), UVM_MEDIUM)
            starting_phase.drop_objection(this);
        end
    endtask : post_body

endclass : rz_alu_base_sequence

class rz_alu_random_sequence extends rz_alu_base_sequence;
    `uvm_object_utils(rz_alu_random_sequence)

    function new(string name = "rz_alu_random_sequence");
        super.new(name);
    endfunction : new

    task body();
        `uvm_info("SEQ_RANDOM","",UVM_MEDIUM)

        `uvm_do_with(req, {op_mode == rst_op;} )

        `uvm_create(req);

        repeat (2000) begin : random_loop
            `uvm_rand_send(req)
        end : random_loop
    endtask : body

endclass : rz_alu_random_sequence

class rz_alu_minmax_sequence extends rz_alu_base_sequence;
    `uvm_object_utils(rz_alu_minmax_sequence)

    function new(string name = "rz_alu_minmax_sequence");
        super.new(name);
    endfunction : new

    task body();
        `uvm_info("SEQ_MINMAX","",UVM_MEDIUM)

        `uvm_do_with(req, {op_mode == rst_op;} )

        repeat (2000) begin
            `uvm_do_with(req, {A dist {32'h0 := 1, 32'hFFFF_FFFF := 1};
                               B dist {32'h0 := 1, 32'hFFFF_FFFF := 1};})
        end
    endtask : body

endclass : rz_alu_minmax_sequence

`endif // IFNDEF_GUARD_rz_alu_seq_lib
