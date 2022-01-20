/******************************************************************************
* DVT CODE TEMPLATE: example test
* Created by rziobrowski on Jan 20, 2022
* uvc_company = rz, uvc_name = alu
*******************************************************************************/

`ifndef IFNDEF_GUARD_rz_alu_minmax_test
`define IFNDEF_GUARD_rz_alu_minmax_test

class  rz_alu_minmax_test extends rz_alu_base_test;

    `uvm_component_utils(rz_alu_minmax_test)

    function new(string name = "rz_alu_minmax_test", uvm_component parent);
        super.new(name, parent);
    endfunction: new

    virtual function void build_phase(uvm_phase phase);
        uvm_config_db#(uvm_object_wrapper)::set(this,
            "m_env.m_rz_alu_agent.m_sequencer.run_phase",
            "default_sequence",
            rz_alu_minmax_sequence::type_id::get());

           // Create the env
        super.build_phase(phase);
    endfunction

endclass


`endif // IFNDEF_GUARD_rz_alu_minmax_test
