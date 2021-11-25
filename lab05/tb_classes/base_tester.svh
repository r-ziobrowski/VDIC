virtual class base_tester extends uvm_component;

    `uvm_component_utils(base_tester)

    virtual alu_bfm bfm;

    function new (string name, uvm_component parent);
        super.new(name, parent);
    endfunction : new

    function void build_phase(uvm_phase phase);
        if(!uvm_config_db #(virtual alu_bfm)::get(null, "*","bfm", bfm))
            $fatal(1,"Failed to get BFM");
    endfunction : build_phase

	pure virtual protected function bit [2:0] get_op();

	pure virtual protected function bit [31:0] get_data();

	pure virtual protected function bit [3:0] get_crc(bit [67:0] data);

	pure virtual protected function bit [2:0] get_data_len();

	pure virtual protected function void ALU_input_generate();

	pure virtual protected function op_mode_t get_op_mode();

    task run_phase(uvm_phase phase);
        ALU_input_t i_ALU;
        shortint result;

        phase.raise_objection(this);

        bfm.reset_dut();

		repeat (100_000) begin : tester_main
			wait(bfm.chk_flag == 1'b0);
			bfm.op_mode = get_op_mode();
			case (bfm.op_mode) // handle of nop and rst
				nop_op: begin : case_nop_op
					@(negedge bfm.clk);
				end

				rst_op: begin : case_rst_op
					bfm.reset_dut();
				end

				default: begin : case_default
            		ALU_input_generate();
					bfm.send_message(bfm.ALU_input);
					bfm.chk_flag = 1'b1;
				end
			endcase
		end

        phase.drop_objection(this);

    endtask : run_phase


endclass : base_tester
