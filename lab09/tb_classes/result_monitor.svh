class result_monitor extends uvm_component;
	`uvm_component_utils(result_monitor)
	
	local virtual alu_bfm bfm;
	uvm_analysis_port #(result_transaction) ap;

	function new (string name, uvm_component parent);
		super.new(name, parent);
	endfunction : new

	function void build_phase(uvm_phase phase);
		if(!uvm_config_db #(virtual alu_bfm)::get(null, "*","bfm", bfm))
			$fatal(1, "Failed to get BFM");
		ap = new("ap",this);
	endfunction : build_phase
	
   function void connect_phase(uvm_phase phase);
      bfm.result_monitor_h = this;
   endfunction : connect_phase

	function void write_to_monitor(ALU_output_t r);
		result_transaction result_t;
		result_t            = new("result_t");

		result_t.C          = r.C;
		result_t.CRC        = r.CRC;
		result_t.ERR_FLAGS  = r.ERR_FLAGS;
		result_t.FLAGS      = r.FLAGS;
		result_t.is_ERROR   = r.is_ERROR;
		result_t.PARITY     = r.PARITY;

		ap.write(result_t);
	endfunction : write_to_monitor

endclass : result_monitor






