class min_max_tester extends random_tester;

    `uvm_component_utils(min_max_tester)
    
	protected function bit [31:0] get_data();
		bit [31:0] data_tmp;

		automatic int status = std::randomize(data_tmp) with {
			data_tmp dist {32'h0 := 1, 32'hFFFF_FFFF := 1};
		};

		assert (status) else begin
			$display("Randomization in get_data() failed");
		end

		return data_tmp;
	endfunction : get_data

    function new (string name, uvm_component parent);
        super.new(name, parent);
    endfunction : new

endclass : min_max_tester
