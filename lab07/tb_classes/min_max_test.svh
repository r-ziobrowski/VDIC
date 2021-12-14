class min_max_test extends random_test;

    `uvm_component_utils(min_max_test)
    
    function new (string name, uvm_component parent);
        super.new(name,parent);
    endfunction : new

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
	    random_command::type_id::set_type_override(minmax_command::get_type());
    endfunction : build_phase


endclass

