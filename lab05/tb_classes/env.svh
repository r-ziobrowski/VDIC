class env extends uvm_env;
    `uvm_component_utils(env)

    /* xrun 18.1 warns about object definition from abstract class, will be
     * upgraded to error in future releases.
     * This is temporary solution -> sequencer/driver will not have this problem
     */

    //XXX variables will be used later

    function void build_phase(uvm_phase phase);
        void'(base_tester::type_id::create("tester_h",this));
        void'(coverage::type_id::create ("coverage_h",this));
        void'(scoreboard::type_id::create("scoreboard_h",this));
    endfunction : build_phase

    function new (string name, uvm_component parent);
        super.new(name,parent);
    endfunction : new

endclass


