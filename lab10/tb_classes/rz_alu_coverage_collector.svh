/******************************************************************************
* DVT CODE TEMPLATE: coverage collector
* Created by rziobrowski on Jan 20, 2022
* uvc_company = rz, uvc_name = alu
*******************************************************************************/

`ifndef IFNDEF_GUARD_rz_alu_coverage_collector
`define IFNDEF_GUARD_rz_alu_coverage_collector

//------------------------------------------------------------------------------
//
// CLASS: rz_alu_coverage_collector
//
//------------------------------------------------------------------------------

class rz_alu_coverage_collector extends uvm_component;

    // Configuration object
    protected rz_alu_config_obj m_config_obj;

    // Item collected from the monitor
    protected rz_alu_item m_collected_item;

    // Using suffix to handle more ports
    `uvm_analysis_imp_decl(_collected_item)

    // Connection to the monitor
    uvm_analysis_imp_collected_item#(rz_alu_item, rz_alu_coverage_collector) m_monitor_port;

    local bit ERR_CRC;

    `uvm_component_utils(rz_alu_coverage_collector)

covergroup op_cov;

        option.name = "cg_op_cov";

        A_alu_op : coverpoint m_collected_item.OP {

            // #A1 test all operations
            bins A1_all_op[] = {and_op, or_op, add_op, sub_op};
        }

        A_alu_op_comb : coverpoint m_collected_item.OP {

            // #A4 run every operation after every operation
            bins A4_evr_after_evr[] = (and_op, or_op, add_op, sub_op => and_op, or_op, add_op, sub_op);

            // #A5 two operations in row
            bins A5_twoops[] = (and_op, or_op, add_op, sub_op [* 2]);
        }

        A_op_mode : coverpoint m_collected_item.op_mode {
            bins A_rst_2_def = (rst_op => def_op);

            bins A_def_2_rst = (def_op => rst_op);
        }

        A_rst_op: cross A_alu_op, A_op_mode {

            // #A2 test all operations after reset
            bins A2_rst_add      = (binsof(A_alu_op.A1_all_op) intersect {add_op} && binsof(A_op_mode.A_rst_2_def));
            bins A2_rst_and      = (binsof(A_alu_op.A1_all_op) intersect {and_op} && binsof(A_op_mode.A_rst_2_def));
            bins A2_rst_or       = (binsof(A_alu_op.A1_all_op) intersect {or_op}  && binsof(A_op_mode.A_rst_2_def));
            bins A2_rst_sub      = (binsof(A_alu_op.A1_all_op) intersect {sub_op} && binsof(A_op_mode.A_rst_2_def));

            // #A3 test reset after all operations
            bins A3_add_rst      = (binsof(A_alu_op.A1_all_op) intersect {add_op} && binsof(A_op_mode.A_def_2_rst));
            bins A3_and_rst      = (binsof(A_alu_op.A1_all_op) intersect {and_op} && binsof(A_op_mode.A_def_2_rst));
            bins A3_or_rst       = (binsof(A_alu_op.A1_all_op) intersect {or_op}  && binsof(A_op_mode.A_def_2_rst));
            bins A3_sub_rst      = (binsof(A_alu_op.A1_all_op) intersect {sub_op} && binsof(A_op_mode.A_def_2_rst));
        }

    endgroup

    // Covergroup checking for min and max arguments of the ALU
    covergroup zeros_or_ones_on_ops;

        option.name = "cg_zeros_or_ones_on_ops";

        all_ops : coverpoint m_collected_item.OP {
            bins all_op[] = {and_op, or_op, add_op, sub_op};
        }

        a_leg: coverpoint m_collected_item.A {
            bins zeros = {'h0000_0000};
            bins others= {['h0000_0001:'hFFFF_FFFE]};
            bins ones  = {'hFFFF_FFFF};
        }

        b_leg: coverpoint m_collected_item.B {
            bins zeros = {'h0000_0000};
            bins others= {['h0000_0001:'hFFFF_FFFE]};
            bins ones  = {'hFFFF_FFFF};
        }

        B_op_00_FF: cross a_leg, b_leg, all_ops {

            // #B1 simulate all zero input for all the operations
            bins B1_add_00          = binsof (all_ops) intersect {add_op} &&
            (binsof (a_leg.zeros) || binsof (b_leg.zeros));

            bins B1_and_00          = binsof (all_ops) intersect {and_op} &&
            (binsof (a_leg.zeros) || binsof (b_leg.zeros));

            bins B1_or_00           = binsof (all_ops) intersect {or_op} &&
            (binsof (a_leg.zeros) || binsof (b_leg.zeros));

            bins B1_sub_00          = binsof (all_ops) intersect {sub_op} &&
            (binsof (a_leg.zeros) || binsof (b_leg.zeros));

            // #B2 simulate all one input for all the operations
            bins B2_add_FF          = binsof (all_ops) intersect {add_op} &&
            (binsof (a_leg.ones) || binsof (b_leg.ones));

            bins B2_and_FF          = binsof (all_ops) intersect {and_op} &&
            (binsof (a_leg.ones) || binsof (b_leg.ones));

            bins B2_or_FF           = binsof (all_ops) intersect {or_op} &&
            (binsof (a_leg.ones) || binsof (b_leg.ones));

            bins B2_sub_FF          = binsof (all_ops) intersect {sub_op} &&
            (binsof (a_leg.ones) || binsof (b_leg.ones));

            ignore_bins others_only =
            binsof(a_leg.others) && binsof(b_leg.others);
        }

    endgroup

    // Covergroup checking error handling
    covergroup err_cov;

        option.name = "cg_err_cov";

        err_op : coverpoint m_collected_item.OP {
            // #C1 test all invalid operations
            bins C1_range[] = {'b000, 'b111};
            ignore_bins inv_ops[] = {and_op, or_op, add_op, sub_op};
        }

        err_crc : coverpoint ERR_CRC {
            // #C2 test invalid CRC
            bins C2_err_crc = {1'b1};
        }

        err_data_A : coverpoint m_collected_item.A_nr_of_bytes {
            // #C3 test sending incorrect amount of data
            bins C3_inv_range_A[] = {[3'd0 : 3'd3]};
        }

        err_data_B : coverpoint m_collected_item.B_nr_of_bytes {
            // #C3 test sending incorrect amount of data
            bins C3_inv_range_B[] = {[3'd0 : 3'd3]};
        }

    endgroup

    function new(string name, uvm_component parent);
        super.new(name, parent);
        op_cov                  = new();
        zeros_or_ones_on_ops    = new();
        err_cov                 = new();
    endfunction : new

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        m_monitor_port = new("m_monitor_port",this);

        // Get the configuration object
        if(!uvm_config_db#(rz_alu_config_obj)::get(this, "", "m_config_obj", m_config_obj))
            `uvm_fatal("NOCONFIG", {"Config object must be set for: ", get_full_name(), ".m_config_obj"})
    endfunction : build_phase

    function void write_collected_item(rz_alu_item item);
        m_collected_item = item;
        ERR_CRC = (item.CRC != CRC_input({item.B, item.A, 1'b1, item.OP}, 1'b0));
        op_cov.sample();
        zeros_or_ones_on_ops.sample();
        err_cov.sample();
    endfunction : write_collected_item

endclass : rz_alu_coverage_collector

`endif // IFNDEF_GUARD_rz_alu_coverage_collector
