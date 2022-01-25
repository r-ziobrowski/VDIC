/******************************************************************************
* DVT CODE TEMPLATE: monitor
* Created by rziobrowski on Jan 20, 2022
* uvc_company = rz, uvc_name = alu
*******************************************************************************/

`ifndef IFNDEF_GUARD_rz_alu_monitor
`define IFNDEF_GUARD_rz_alu_monitor

//------------------------------------------------------------------------------
//
// CLASS: rz_alu_monitor
//
//------------------------------------------------------------------------------

class rz_alu_monitor extends uvm_monitor;

    // The virtual interface to HDL signals.
    protected virtual rz_alu_if m_rz_alu_vif;

    // Configuration object
    protected rz_alu_config_obj m_config_obj;

    // Collected item
    protected rz_alu_item m_collected_item;

    // Collected item is broadcast on this port
    uvm_analysis_port #(rz_alu_item) m_collected_item_port;

    `uvm_component_utils(rz_alu_monitor)

    protected bit ERR_DATA = 1'b0;
    protected bit ERR_OP = 1'b0;
    protected bit ERR_CRC = 1'b0;

    function new (string name, uvm_component parent);
        super.new(name, parent);

        // Allocate collected_item.
        m_collected_item = rz_alu_item::type_id::create("m_collected_item", this);

        // Allocate collected_item_port.
        m_collected_item_port = new("m_collected_item_port", this);
    endfunction : new

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        // Get the interface
        if(!uvm_config_db#(virtual rz_alu_if)::get(this, "", "m_rz_alu_vif", m_rz_alu_vif))
            `uvm_fatal("NOVIF", {"virtual interface must be set for: ", get_full_name(), ".m_rz_alu_vif"})

        // Get the configuration object
        if(!uvm_config_db#(rz_alu_config_obj)::get(this, "", "m_config_obj", m_config_obj))
            `uvm_fatal("NOCONFIG",{"Config object must be set for: ",get_full_name(),".m_config_obj"})
    endfunction: build_phase

    virtual task run_phase(uvm_phase phase);
        process main_thread; // main thread
        process rst_mon_thread; // reset monitor thread

        // Start monitoring
        forever begin
            fork
                // Start the monitoring thread
                begin
                    main_thread=process::self();
                    collect_items();
                end
                // Monitor the reset signal
                begin
                    rst_mon_thread = process::self();
                    @(negedge m_rz_alu_vif.reset) begin
                        // Interrupt current item at reset

                        m_collected_item.op_mode = rst_op;
                        m_collected_item_port.write(m_collected_item);

                        if(main_thread) main_thread.kill();
                        // Do reset
                        reset_monitor();
                    end
                end
            join_any

            if (rst_mon_thread) rst_mon_thread.kill();
        end
    endtask : run_phase

    virtual protected task collect_items();
        forever begin
            @(posedge m_rz_alu_vif.clock);
            if(m_rz_alu_vif.rcv_flag == 1'b1) begin
                m_collected_item = m_rz_alu_vif.read_item();
                `uvm_info(get_full_name(), $sformatf("Item collected :\n%s", m_collected_item.sprint()), UVM_HIGH)

                m_collected_item_port.write(m_collected_item);

                if (m_config_obj.m_checks_enable)
                    perform_item_checks();

                m_rz_alu_vif.rcv_flag = 1'b0;
            end
        end
    endtask : collect_items

    virtual protected function void perform_item_checks();
        string data_str;
        rz_alu_item predicted_item;

        predicted_item = get_expected(m_collected_item);

        data_str  = {"Actual \n" , m_collected_item.sprint(),
            "/Predicted \n",predicted_item.sprint()};

        assert (predicted_item.compare(m_collected_item)) begin
            `uvm_info ("SELF CHECKER", {"PASS: ", data_str}, UVM_HIGH)
        end
        else
            `uvm_error("SELF CHECKER", {"FAIL: ",data_str})
    endfunction : perform_item_checks

    virtual protected function void reset_monitor();
    endfunction : reset_monitor

    //------------------------------------------------------------------------------
    // Expected result generation
    //------------------------------------------------------------------------------

    local function rz_alu_item get_expected(rz_alu_item ALU_in);
        automatic bit [32:0] C_tmp_carry;
        automatic string act,exp;
        automatic bit signed [31:0] C_tmp;
        automatic bit overflow;
        bit [3:0] crc_in_tmp = CRC_input({ALU_in.B, ALU_in.A, 1'b1, ALU_in.OP}, 1'b0);

        rz_alu_item ALU_output;

        ERR_DATA = 1'b0;
        ERR_OP = 1'b0;
        ERR_CRC = 1'b0;

        ALU_output = new("ALU_output");

        ALU_output.A = ALU_in.A;
        ALU_output.B = ALU_in.B;
        ALU_output.OP = ALU_in.OP;
        ALU_output.CRC = ALU_in.CRC;
        ALU_output.A_nr_of_bytes = ALU_in.A_nr_of_bytes;
        ALU_output.B_nr_of_bytes = ALU_in.B_nr_of_bytes;
        ALU_output.op_mode = ALU_in.op_mode;

        ALU_output.ALU_out.is_ERROR = 1'b0;

        if((ALU_in.A_nr_of_bytes != 3'h4) || (ALU_in.B_nr_of_bytes != 3'h4)) begin : ERR_DATA_check
            ERR_DATA = 1'b1;
            ALU_output.ALU_out.is_ERROR = 1'b1;
        end
        else if (ALU_in.CRC != crc_in_tmp) begin : ERR_CRC_check
            ERR_CRC = 1'b1;
            ALU_output.ALU_out.is_ERROR = 1'b1;
        end
        else if (!(ALU_in.OP inside {3'b000, 3'b001, 3'b100, 3'b101})) begin : ERR_OP_check
            ERR_OP = 1'b1;
            ALU_output.ALU_out.is_ERROR = 1'b1;
        end

        ALU_output.ALU_out.ERR_FLAGS = {ERR_DATA, ERR_CRC, ERR_OP, ERR_DATA, ERR_CRC, ERR_OP};

        if(ALU_output.ALU_out.is_ERROR)
            ALU_output.ALU_out.PARITY = ^{1'b1, ALU_output.ALU_out.ERR_FLAGS};
        else
            ALU_output.ALU_out.PARITY = 1'b0;

        `uvm_info ("GET EXPECTED", ALU_in.convert2string(), UVM_HIGH)

        if(!ALU_output.ALU_out.is_ERROR) begin : RESULT_calc
            case(ALU_in.OP)
                and_op : C_tmp = ALU_in.B & ALU_in.A;
                or_op  : C_tmp = ALU_in.B | ALU_in.A;
                add_op : begin
                    C_tmp = ALU_in.B + ALU_in.A;
                    C_tmp_carry = ALU_in.B + ALU_in.A;
                    overflow = ~(ALU_in.B[31] ^ ALU_in.A[31]) & (ALU_in.B[31] ^ C_tmp[31]);
                end
                sub_op : begin
                    C_tmp = ALU_in.B - ALU_in.A;
                    C_tmp_carry = ALU_in.B - ALU_in.A;
                    overflow = (ALU_in.B[31] ^ ALU_in.A[31]) & (ALU_in.B[31] ^ C_tmp[31]);
                end
                default: begin
                    `uvm_error("INTERNAL ERROR", $sformatf("get_expected: unexpected case argument: %h", ALU_in.OP))
                end
            endcase

            ALU_output.ALU_out.C = C_tmp;

            ALU_output.ALU_out.FLAGS = 4'h0;

            if(C_tmp < 0)               ALU_output.ALU_out.FLAGS[0] = 1;
            if(C_tmp == 0)              ALU_output.ALU_out.FLAGS[1] = 1;
            if(overflow)                ALU_output.ALU_out.FLAGS[2] = 1;
            if(C_tmp_carry[32] == 1'b1) ALU_output.ALU_out.FLAGS[3] = 1;

            ALU_output.ALU_out.CRC = CRC_output({ALU_output.ALU_out.C, 1'b0, ALU_output.ALU_out.FLAGS}, 1'b0);
        end
        return ALU_output;
    endfunction

endclass : rz_alu_monitor

`endif // IFNDEF_GUARD_rz_alu_monitor
