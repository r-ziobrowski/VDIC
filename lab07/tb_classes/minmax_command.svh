class minmax_command extends random_command;
    `uvm_object_utils(minmax_command)

    constraint minmax_data {
        A dist {32'h0 := 1, 32'hFFFF_FFFF := 1};
        B dist {32'h0 := 1, 32'hFFFF_FFFF := 1};
    }

    function new(string name="");
        super.new(name);
    endfunction
    
endclass : minmax_command