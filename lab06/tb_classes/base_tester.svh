virtual class base_tester extends uvm_component;

    `uvm_component_utils(base_tester)
    
    uvm_put_port #(ALU_input_t) command_port;

    function new (string name, uvm_component parent);
        super.new(name, parent);
    endfunction : new

    function void build_phase(uvm_phase phase);
	    command_port = new("command_port", this);
    endfunction : build_phase

	pure virtual protected function bit [2:0] get_op();

	pure virtual protected function bit [31:0] get_data();

	pure virtual protected function bit [3:0] get_crc(bit [67:0] data);

	pure virtual protected function bit [2:0] get_data_len();

	pure virtual protected function ALU_input_t ALU_input_generate();

	pure virtual protected function op_mode_t get_op_mode();

    task run_phase(uvm_phase phase);
	    ALU_input_t command;

        phase.raise_objection(this);

	    command.op_mode = rst_op;
	    command_port.put(command);

		repeat (1_000) begin : tester_main
			command = ALU_input_generate();
			command_port.put(command);
		end
		
		#3000;
		
        phase.drop_objection(this);

    endtask : run_phase


endclass : base_tester
