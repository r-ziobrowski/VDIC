/******************************************************************************
* DVT CODE TEMPLATE: testbench top module
* Created by rziobrowski on Jan 20, 2022
* uvc_company = rz, uvc_name = alu
*******************************************************************************/

module alu_tb_top;

    // Import the UVM package
    import uvm_pkg::*;

    // Import the UVC that we have implemented
    import rz_alu_pkg::*;

    // Clock and reset signals
    reg clock;

    // The interface
    rz_alu_if vif(clock);

    mtm_Alu dut (
        .clk  (clock),    //posedge active clock
        .rst_n(!vif.reset),  //synchronous reset active low
        .sin  (vif.sin),    //serial data input
        .sout (vif.sout)    //serial data output
    );

    initial begin
        // Propagate the interface to all the components that need it
        uvm_config_db#(virtual rz_alu_if)::set(uvm_root::get(), "*", "m_rz_alu_vif", vif);
        // Start the test
        run_test();
    end

    // Generate clock
    always
        #5 clock=~clock;

    // Init
    initial begin
        vif.sin <= 1'b1;
        vif.reset <= 1'b0;
        clock <= 1'b1;
    end
endmodule
