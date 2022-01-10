class minmax_sequence extends uvm_sequence #(sequence_item);
    `uvm_object_utils(minmax_sequence)
 
    function new(string name = "minmax_sequence");
        super.new(name);
    endfunction : new

    task body();
        `uvm_info("SEQ_MINMAX","",UVM_MEDIUM)
        
        `uvm_do_with(req, {op_mode == rst_op;} )
        
        repeat (1000) begin
        	`uvm_do_with(req, {A dist {32'h0 := 1, 32'hFFFF_FFFF := 1};
	        				   B dist {32'h0 := 1, 32'hFFFF_FFFF := 1};})
//            req.print();
        end
    endtask : body
    
endclass : minmax_sequence
