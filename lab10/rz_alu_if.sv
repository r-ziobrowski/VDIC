/******************************************************************************
* DVT CODE TEMPLATE: interface
* Created by rziobrowski on Jan 20, 2022
* uvc_company = rz, uvc_name = alu
*******************************************************************************/

//------------------------------------------------------------------------------
//
// INTERFACE: rz_alu_if
//
//------------------------------------------------------------------------------

// Just in case you need them
`include "uvm_macros.svh"

interface rz_alu_if(clock);

    // Just in case you need it
    import uvm_pkg::*;
    import rz_alu_pkg::*;

    // Clock and reset signals
    input clock;

    // Flags to enable/disable assertions and coverage
    bit checks_enable=1;
    bit coverage_enable=1;

    bit reset;
    bit sin = 1'b1;
    wire sout;

    ALU_input_t ALU_input;
    ALU_output_t ALU_output;
    bit rcv_flag = 1'b0;

//------------------------------------------------------------------------------
// Serial write
//------------------------------------------------------------------------------
    task serial_write(bit [7:0] data_in, bit is_cmd);
        automatic bit [10:0] serial_data = {1'b0, is_cmd, data_in, 1'b1};
        foreach(serial_data[i])begin
            @(negedge clock);
            sin = serial_data[i];
        end
    endtask : serial_write

    task send_message(rz_alu_item ALU_in);
        for(int i = ALU_in.B_nr_of_bytes; i > 0; i--)begin
            serial_write(ALU_in.B[i*8-1 -: 8], 1'b0);
        end
        for(int i = ALU_in.A_nr_of_bytes; i > 0; i--)begin
            serial_write(ALU_in.A[i*8-1 -: 8], 1'b0);
        end
        serial_write({1'b0, ALU_in.OP, ALU_in.CRC}, 1'b1);
    endtask : send_message

    //------------------------------------------------------------------------------
    // Serial read
    //------------------------------------------------------------------------------
    task serial_read(output bit [7:0] data_out, bit is_cmd);
        @(negedge sout);
        for(int i = 0; i < 11; i++)begin
            @(negedge clock);
            case(i) inside
                1: is_cmd = sout;
                [2:9]: data_out[(7-(i-2))] = sout;
            endcase
        end
    endtask : serial_read

    function rz_alu_item read_item();
        rz_alu_item item;
        item = new("item");

        item.A = ALU_input.A;
        item.B = ALU_input.B;
        item.OP = ALU_input.OP;
        item.CRC = ALU_input.CRC;
        item.A_nr_of_bytes = ALU_input.A_nr_of_bytes;
        item.B_nr_of_bytes = ALU_input.B_nr_of_bytes;
        item.op_mode = ALU_input.op_mode;
        item.ALU_out = ALU_output;

        return item;
    endfunction

    task read_message();
        automatic bit [7:0] data_tmp;
        automatic bit is_cmd = 1'b0;

        ALU_output.is_ERROR = 1'b0;

        ALU_output.ERR_FLAGS = 6'h0;
        ALU_output.PARITY = 1'b0;

        ALU_output.C = 32'h0;
        ALU_output.CRC = 3'h0;
        ALU_output.FLAGS = 4'h0;

        for(int i = $rtoi($ceil($size(ALU_output.C)/8)); i > 0; i--)begin
            serial_read(data_tmp, is_cmd);
            if (is_cmd == 1'b1)begin
                ALU_output.is_ERROR = 1'b1;
                ALU_output.ERR_FLAGS = data_tmp[6 -: 6];
                ALU_output.PARITY = data_tmp[0];
                break;
            end else begin
                ALU_output.C[i*8-1 -: 8] = data_tmp;//8'hFF;
            end
        end
        if (!ALU_output.is_ERROR) begin
            serial_read(data_tmp, is_cmd);
            ALU_output.FLAGS = data_tmp[6:3];
            ALU_output.CRC = data_tmp[2:0];
        end
    endtask : read_message

    task reset_dut();
        sin = 1'b1;
        reset = 1'b1;
        @(negedge clock);
        reset = 1'b0;
    endtask : reset_dut

    task send_op(input rz_alu_item ALU_in);
        ALU_input.A = ALU_in.A;
        ALU_input.B = ALU_in.B;
        ALU_input.OP = ALU_in.OP;
        ALU_input.CRC = ALU_in.CRC;
        ALU_input.A_nr_of_bytes = ALU_in.A_nr_of_bytes;
        ALU_input.B_nr_of_bytes = ALU_in.B_nr_of_bytes;
        ALU_input.op_mode = ALU_in.op_mode;

        case(ALU_in.op_mode)
            nop_op: begin : case_nop_op
                @(negedge clock);
            end

            rst_op: begin : case_rst_op
                reset_dut();
            end

            default: begin : case_default
                send_message(ALU_in);
                read_message();
                rcv_flag = 1'b1;
            end
        endcase
        @(negedge clock);
    endtask

endinterface : rz_alu_if
