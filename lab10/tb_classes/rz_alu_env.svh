/******************************************************************************
* DVT CODE TEMPLATE: env
* Created by rziobrowski on Jan 20, 2022
* uvc_company = rz, uvc_name = alu
*******************************************************************************/

`ifndef IFNDEF_GUARD_rz_alu_env
`define IFNDEF_GUARD_rz_alu_env

//------------------------------------------------------------------------------
//
// CLASS: rz_alu_env
//
//------------------------------------------------------------------------------

class rz_alu_env extends uvm_env;

    // Components of the environment
    rz_alu_agent m_rz_alu_agent;

    `uvm_component_utils(rz_alu_env)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction : new

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        begin
            // Create the configuration object if it has not been set
            rz_alu_config_obj config_obj;
            if(!uvm_config_db#(rz_alu_config_obj)::get(this, "", "m_config_obj", config_obj)) begin
                config_obj = rz_alu_config_obj::type_id::create("m_config_obj", this);
                uvm_config_db#(rz_alu_config_obj)::set(this, {"m_rz_alu_agent","*"}, "m_config_obj", config_obj);
            end

            // Create the agent
            m_rz_alu_agent = rz_alu_agent::type_id::create("m_rz_alu_agent", this);
        end

    endfunction : build_phase

endclass : rz_alu_env

`endif // IFNDEF_GUARD_rz_alu_env
