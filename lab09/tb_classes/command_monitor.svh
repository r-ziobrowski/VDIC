class command_monitor extends uvm_component;
	`uvm_component_utils(command_monitor)

	local virtual alu_bfm bfm;
	uvm_analysis_port #(sequence_item) ap;

	function new (string name, uvm_component parent);
		super.new(name,parent);
	endfunction

	function void build_phase(uvm_phase phase);
		if(!uvm_config_db #(virtual alu_bfm)::get(null, "*","bfm", bfm))
			$fatal(1, "Failed to get BFM");
		ap = new("ap",this);
	endfunction : build_phase

    function void connect_phase(uvm_phase phase);
        bfm.command_monitor_h = this;
    endfunction : connect_phase
    
	function void write_to_monitor(ALU_input_t ALU_in);
		sequence_item cmd;
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

