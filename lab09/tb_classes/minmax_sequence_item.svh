class minmax_sequence_item extends sequence_item;
    `uvm_object_utils(minmax_sequence_item)

	constraint minmax_data {
		A dist {32'h0 := 1, 32'hFFFF_FFFF := 1};
		B dist {32'h0 := 1, 32'hFFFF_FFFF := 1};
	}

    function new(string name = "minmax_sequence_item");
        super.new(name);
    endfunction : new

endclass : minmax_sequence_item


