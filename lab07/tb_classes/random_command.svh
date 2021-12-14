class random_command extends uvm_transaction;
    `uvm_object_utils(random_command)

	rand bit [31:0] A;
	rand bit [31:0] B;
	rand bit [2:0] OP;
	rand bit [3:0] CRC; //TODO randomizacja???????
	rand bit [2:0] A_nr_of_bytes;
	rand bit [2:0] B_nr_of_bytes;
	rand op_mode_t op_mode;

    constraint data_len {
    	A_nr_of_bytes dist {[3'h0 : 3'h3] :/ 25, 3'h4 := 75};
    	B_nr_of_bytes dist {[3'h0 : 3'h3] :/ 25, 3'h4 := 75};
    }
    
    constraint crc_val {
	    CRC dist {[4'h0 : 4'hF] :/ 25, CRC_input({B, A, 1'b1, OP}, 1'b0) := 75};
    }

    function new (string name = "");
        super.new(name);
    endfunction : new

    function void do_copy(uvm_object rhs);
        random_command copied_transaction_h;
	    
        if(rhs == null)
            `uvm_fatal("COMMAND TRANSACTION", "Tried to copy from a null pointer")

        super.do_copy(rhs); // copy all parent class data

        if(!$cast(copied_transaction_h,rhs))
            `uvm_fatal("COMMAND TRANSACTION", "Tried to copy wrong type.")
            
        A  = copied_transaction_h.A;
        B  = copied_transaction_h.B;
        OP = copied_transaction_h.OP;
        CRC = copied_transaction_h.CRC;
        A_nr_of_bytes = copied_transaction_h.A_nr_of_bytes;
        B_nr_of_bytes = copied_transaction_h.B_nr_of_bytes;
        op_mode = copied_transaction_h.op_mode;

    endfunction : do_copy


//    function random_command clone_me();
//        
//        random_command clone;
//        uvm_object tmp;
//
//        tmp = this.clone();
//        $cast(clone, tmp);
//        return clone;
//        
//    endfunction : clone_me


    function bit do_compare(uvm_object rhs, uvm_comparer comparer);
        
        random_command compared_transaction_h;
        bit same;

        if (rhs==null) `uvm_fatal("RANDOM COMMAND",
                "Tried to do comparison to a null pointer");

        if (!$cast(compared_transaction_h,rhs))
            same = 0;
        else
            same = super.do_compare(rhs, comparer) &&
            (compared_transaction_h.A == A) &&
            (compared_transaction_h.B == B) &&
            (compared_transaction_h.OP == OP) &&
            (compared_transaction_h.CRC == CRC) &&
            (compared_transaction_h.A_nr_of_bytes == A_nr_of_bytes) &&
            (compared_transaction_h.B_nr_of_bytes == B_nr_of_bytes) &&
            (compared_transaction_h.op_mode == op_mode);
        return same;
        
    endfunction : do_compare


    function string convert2string();
        string s;
        s = $sformatf("A: %8h B: %8h OP: %h CRC: %h A_nr_of_bytes: %h B_nr_of_bytes: %h op_mode: %s", A, B, OP, CRC, A_nr_of_bytes, B_nr_of_bytes, op_mode.name());
        return s;
    endfunction : convert2string


endclass : random_command


