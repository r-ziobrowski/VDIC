class driver extends uvm_driver #(sequence_item);
	`uvm_component_utils(driver)

	protected virtual alu_bfm bfm;

	function new (string name, uvm_component parent);
		super.new(name, parent);
	endfunction : new

	function void build_phase(uvm_phase phase);
		if(!uvm_config_db #(virtual alu_bfm)::get(null, "*","bfm", bfm))
			$fatal(1, "Failed to get BFM");
	endfunction : build_phase

	task run_phase(uvm_phase phase);
		sequence_item command;
		
		void'(begin_tr(command));

		forever begin : command_loop
			ALU_input_t ALU_in;
			ALU_output_t ALU_out;
            seq_item_port.get_next_item(command);
			
			ALU_in.A                = command.A;
			ALU_in.B                = command.B;
			ALU_in.A_nr_of_bytes    = command.A_nr_of_bytes;
			ALU_in.B_nr_of_bytes    = command.B_nr_of_bytes;
			ALU_in.CRC              = command.CRC;
			ALU_in.OP               = command.OP;
			ALU_in.op_mode          = command.op_mode;

			bfm.send_op(ALU_in, ALU_out);
			
			command.ALU_out = ALU_out;
			seq_item_port.item_done();
		end : command_loop
		
		end_tr(command);
	endtask : run_phase


endclass : driver

