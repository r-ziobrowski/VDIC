/******************************************************************************
* DVT CODE TEMPLATE: sequencer
* Created by rziobrowski on Jan 20, 2022
* uvc_company = rz, uvc_name = alu
*******************************************************************************/

`ifndef IFNDEF_GUARD_rz_alu_sequencer
`define IFNDEF_GUARD_rz_alu_sequencer

//------------------------------------------------------------------------------
//
// CLASS: rz_alu_sequencer
//
//------------------------------------------------------------------------------

class rz_alu_sequencer extends uvm_sequencer #(rz_alu_item);

    `uvm_component_utils(rz_alu_sequencer)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction : new

endclass : rz_alu_sequencer

`endif // IFNDEF_GUARD_rz_alu_sequencer
