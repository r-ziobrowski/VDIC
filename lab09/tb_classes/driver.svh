class driver extends uvm_component;
	`uvm_component_utils(driver)

	virtual alu_bfm bfm;
	uvm_get_port #(random_command) command_port;

	function new (string name, uvm_component parent);
		super.new(name, parent);
	endfunction : new

	function void build_phase(uvm_phase phase);
		if(!uvm_config_db #(virtual alu_bfm)::get(null, "*","bfm", bfm))
			$fatal(1, "Failed to get BFM");
		command_port = new("command_port", this);
	endfunction : build_phase

	task run_phase(uvm_phase phase);
		random_command command;
		ALU_input_t ALU_in;

		forever begin : command_loop
			command_port.get(command);

			ALU_in.A                = command.A;
			ALU_in.B                = command.B;
			ALU_in.A_nr_of_bytes    = command.A_nr_of_bytes;
			ALU_in.B_nr_of_bytes    = command.B_nr_of_bytes;
			ALU_in.CRC              = command.CRC;
			ALU_in.OP               = command.OP;
			ALU_in.op_mode          = command.op_mode;

			bfm.send_op(ALU_in);
		end : command_loop
	endtask : run_phase


endclass : driver

