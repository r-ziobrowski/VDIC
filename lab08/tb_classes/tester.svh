class tester extends uvm_component;
	`uvm_component_utils(tester)

	uvm_put_port #(random_command) command_port;

	function new (string name, uvm_component parent);
		super.new(name, parent);
	endfunction : new

	function void build_phase(uvm_phase phase);
		command_port = new("command_port", this);
	endfunction : build_phase

	task run_phase(uvm_phase phase);
		random_command command;

		phase.raise_objection(this);

		command = new("command");
		command.op_mode = rst_op;
		command_port.put(command);

		command = random_command::type_id::create("command");
		
		set_print_color(COLOR_BOLD_BLACK_ON_YELLOW);
        $write("*** Created transaction type: %s", command.get_type_name());
        set_print_color(COLOR_DEFAULT);
		
		repeat (1000) begin : tester_main
			assert(command.randomize());
			command_port.put(command);
		end

		#500;

		phase.drop_objection(this);

	endtask : run_phase


endclass : tester
