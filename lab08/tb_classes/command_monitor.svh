class command_monitor extends uvm_component;
	`uvm_component_utils(command_monitor)

	uvm_analysis_port #(random_command) ap;

	function new (string name, uvm_component parent);
		super.new(name,parent);
	endfunction

	function void build_phase(uvm_phase phase);
        alu_agent_config alu_agent_config_h;

        // get the BFM
        if(!uvm_config_db #(alu_agent_config)::get(this, "","config", alu_agent_config_h))
            `uvm_fatal("COMMAND MONITOR", "Failed to get CONFIG");

        // pass the command_monitor handler to the BFM
        alu_agent_config_h.bfm.command_monitor_h = this;
    	ap                                       = new("ap",this);
	endfunction : build_phase

	function void write_to_monitor(ALU_input_t ALU_in);
		random_command cmd;
		`uvm_info("COMMAND MONITOR",$sformatf("A: %8h B: %8h OP: %h CRC: %h A_nr_of_bytes: %h B_nr_of_bytes: %h op_mode: %s",
				ALU_in.A, ALU_in.B, ALU_in.OP, ALU_in.CRC, ALU_in.A_nr_of_bytes, ALU_in.B_nr_of_bytes, ALU_in.op_mode.name()), UVM_HIGH);
		cmd    = new("cmd");

		cmd.A  = ALU_in.A;
		cmd.B  = ALU_in.B;
		cmd.OP = ALU_in.OP;
		cmd.CRC = ALU_in.CRC;
		cmd.A_nr_of_bytes = ALU_in.A_nr_of_bytes;
		cmd.B_nr_of_bytes = ALU_in.B_nr_of_bytes;
		cmd.op_mode = ALU_in.op_mode;
		ap.write(cmd);
	endfunction : write_to_monitor

endclass : command_monitor

