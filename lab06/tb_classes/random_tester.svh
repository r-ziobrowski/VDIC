class random_tester extends base_tester;
    
    `uvm_component_utils (random_tester)
    
    protected static ALU_input_t ALU_prev;

    function new (string name, uvm_component parent);
        super.new(name, parent);
    endfunction : new

	//------------------------------------------------------------------------------
	// Data generation
	//------------------------------------------------------------------------------
	protected function bit [2:0] get_op();
		bit [2:0] op_choice;
		op_choice = 3'($random);

		return op_choice;
	endfunction : get_op

	protected function bit [31:0] get_data();
		bit [31:0] data_tmp;
		data_tmp = 32'($random);
		
		return data_tmp;
	endfunction : get_data

	protected function bit [3:0] get_crc(bit [67:0] data);
		bit [1:0] crc_ok;
		automatic bit [3:0] crc_rand = 4'($random);
		automatic bit [3:0] crc_tmp = CRC_input(data, 1'b0);

		crc_ok = 2'($random);

		if ((crc_ok == 2'b00) && (crc_rand != crc_tmp)) begin
			return crc_rand;
		end else begin
			return crc_tmp;
		end
	endfunction : get_crc

	protected function bit [2:0] get_data_len();
		bit [2:0] data_tmp;

		automatic int status = std::randomize(data_tmp) with {
			data_tmp dist {[3'h0 : 3'h3] :/ 25, 3'h4 := 75};
		};

		assert (status) else begin
			$display("Randomization in get_data_len() failed");
		end

		return data_tmp;
	endfunction : get_data_len

	protected function op_mode_t get_op_mode();
		bit [1:0] op_mode_choice;
		op_mode_choice = 2'($random);
		unique case (op_mode_choice)
			2'b00 : return nop_op;
			2'b01 : return rst_op;
			2'b10 : return def_op;
			2'b11 : return def_op;
		endcase // case (op_mode_choice)
	endfunction

	protected function ALU_input_t ALU_input_generate();
		ALU_input_t ALU_in;
		ALU_in.op_mode = get_op_mode();
		if(ALU_in.op_mode == def_op) begin
			ALU_in.A = get_data();
			ALU_in.B = get_data();
			ALU_in.OP = get_op();
			ALU_in.CRC = get_crc({ALU_in.B, ALU_in.A, 1'b1, ALU_in.OP});
			ALU_in.A_nr_of_bytes = get_data_len();
			ALU_in.B_nr_of_bytes = get_data_len();
			ALU_prev = ALU_in;
		end else begin
			ALU_in.A = ALU_prev.A;
			ALU_in.B = ALU_prev.B;
			ALU_in.OP = ALU_prev.OP;
			ALU_in.CRC = ALU_prev.CRC;
			ALU_in.A_nr_of_bytes = ALU_prev.A_nr_of_bytes;
			ALU_in.B_nr_of_bytes = ALU_prev.B_nr_of_bytes;
		end
		
		return ALU_in;
	endfunction : ALU_input_generate
endclass : random_tester






