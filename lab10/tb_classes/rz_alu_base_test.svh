/******************************************************************************
* DVT CODE TEMPLATE: base test
* Created by rziobrowski on Jan 20, 2022
* uvc_company = rz, uvc_name = alu
*******************************************************************************/

`ifndef IFNDEF_GUARD_rz_alu_base_test
`define IFNDEF_GUARD_rz_alu_base_test

class rz_alu_base_test extends uvm_test;

    // Env instance
    rz_alu_env m_env;

    // Table printer instance(optional)
    uvm_table_printer printer;

    `uvm_component_utils(rz_alu_base_test)

    function new(string name = "rz_alu_base_test", uvm_component parent=null);
        super.new(name,parent);
    endfunction : new

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        // Create the env
        m_env = rz_alu_env::type_id::create("m_env", this);

        // Create a specific depth printer for printing the created topology
        printer = new();
        printer.knobs.depth = 3;
    endfunction : build_phase

    virtual function void end_of_elaboration_phase(uvm_phase phase);
        // Print the test topology
        `uvm_info(get_type_name(), $sformatf("Printing the test topology :\n%s", this.sprint(printer)), UVM_LOW)
    endfunction : end_of_elaboration_phase

    task run_phase(uvm_phase phase);
        super.run_phase(phase);
        // phase.phase_done.set_drain_time(this, 10);
    endtask : run_phase

endclass : rz_alu_base_test

`endif // IFNDEF_GUARD_rz_alu_base_test
