class minmax_sequence extends uvm_sequence #(minmax_sequence_item);
    `uvm_object_utils(minmax_sequence)
 
    function new(string name = "minmax_sequence");
        super.new(name);
    endfunction : new

    task body();
        `uvm_info("SEQ_MINMAX","",UVM_MEDIUM)
        
        `uvm_do_with(req, {op_mode == rst_op;} )
        
        repeat (1000) begin
            `uvm_do(req);
//            req.print();
        end
    endtask : body
    
endclass : minmax_sequence
