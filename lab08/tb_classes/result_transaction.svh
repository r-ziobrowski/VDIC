class result_transaction extends uvm_transaction;

	bit [31:0] C;
	bit [3:0] FLAGS;
	bit [2:0] CRC;
	bit is_ERROR;
	bit [5:0] ERR_FLAGS;
	bit PARITY;
	
	function new(string name = "");
		super.new(name);
	endfunction : new

    extern function void do_copy(uvm_object rhs);
    extern function bit do_compare(uvm_object rhs, uvm_comparer comparer);
    extern function string convert2string();

endclass : result_transaction
	
	function void result_transaction::do_copy(uvm_object rhs);
		result_transaction copied_transaction_h;

		assert(rhs != null) else
			`uvm_fatal("RESULT TRANSACTION","Tried to copy null transaction");

		super.do_copy(rhs);

		assert($cast(copied_transaction_h,rhs)) else
			`uvm_fatal("RESULT TRANSACTION","Failed cast in do_copy");

		C           = copied_transaction_h.C;
		FLAGS       = copied_transaction_h.FLAGS;
		CRC         = copied_transaction_h.CRC;
		is_ERROR    = copied_transaction_h.is_ERROR;
		ERR_FLAGS   = copied_transaction_h.ERR_FLAGS;
		PARITY      = copied_transaction_h.PARITY;

	endfunction : do_copy

	function string result_transaction::convert2string();
		string s;
		s = $sformatf("C: %8h, FLAGS: %h, CRC: %h, is_ERROR: %h, ERR_FLAGS: %6b, PARITY: %h", C, FLAGS, CRC, is_ERROR, ERR_FLAGS, PARITY);
		return s;
	endfunction : convert2string

	function bit result_transaction::do_compare(uvm_object rhs, uvm_comparer comparer);
		result_transaction compared_result_h;
		bit same;

		assert(rhs != null) else
			`uvm_fatal("RESULT TRANSACTION","Tried to compare null transaction");

		if (!$cast(compared_result_h,rhs))
			same = 0;
		else
			same = super.do_compare(rhs, comparer) &&
			(compared_result_h.C == C) &&
			(compared_result_h.FLAGS == FLAGS) &&
			(compared_result_h.CRC == CRC) &&
			(compared_result_h.is_ERROR == is_ERROR) &&
			(compared_result_h.ERR_FLAGS == ERR_FLAGS) &&
			(compared_result_h.PARITY == PARITY);
		return same;
	endfunction : do_compare
