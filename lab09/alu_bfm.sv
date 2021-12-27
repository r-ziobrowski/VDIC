interface alu_bfm;
	import alu_pkg::*;
	import uvm_pkg::*;
	`include "uvm_macros.svh"

	bit clk;
	bit rst_n;
	bit sin;
	wire sout;

	bit rcv_flag = 1'b0;
	ALU_input_t ALU_input;
	ALU_output_t ALU_output;

	command_monitor command_monitor_h;
	result_monitor result_monitor_h;

	initial begin : clk_gen
		clk = 1'b0;
		sin = 1'b1;
		forever begin : clk_frv
			#10;
			clk = ~clk;
		end
	end

	task reset_dut();
		`uvm_info ("ALU BFM", "reset_dut", UVM_HIGH)
		sin = 1'b1;
		rst_n = 1'b0;
		@(negedge clk);
		rst_n = 1'b1;
	endtask : reset_dut

	//------------------------------------------------------------------------------
	// Serial write
	//------------------------------------------------------------------------------
	task serial_write(bit [7:0] data_in, bit is_cmd);
		automatic bit [10:0] serial_data = {1'b0, is_cmd, data_in, 1'b1};
		foreach(serial_data[i])begin
			@(negedge clk);
			sin = serial_data[i];
		end
	endtask : serial_write

	task send_message(ALU_input_t ALU_in);
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
			@(negedge clk);
			case(i) inside
				1: is_cmd = sout;
				[2:9]: data_out[(7-(i-2))] = sout;
			endcase
		end
	endtask : serial_read

	task read_message(output ALU_output_t ALU_out);
		automatic bit [7:0] data_tmp;
		automatic bit is_cmd = 1'b0;

		ALU_out.is_ERROR = 1'b0;

		ALU_out.ERR_FLAGS = 6'h0;
		ALU_out.PARITY = 1'b0;

		ALU_out.C = 32'h0;
		ALU_out.CRC = 3'h0;
		ALU_out.FLAGS = 4'h0;

		for(int i = $rtoi($ceil($size(ALU_out.C)/8)); i > 0; i--)begin
			serial_read(data_tmp, is_cmd);
			if (is_cmd == 1'b1)begin
				ALU_out.is_ERROR = 1'b1;
				ALU_out.ERR_FLAGS = data_tmp[6 -: 6];
				ALU_out.PARITY = data_tmp[0];
				break;
			end else begin
				ALU_out.C[i*8-1 -: 8] = data_tmp;
			end
		end
		if (!ALU_out.is_ERROR) begin
			serial_read(data_tmp, is_cmd);
			ALU_out.FLAGS = data_tmp[6:3];
			ALU_out.CRC = data_tmp[2:0];
		end
	endtask : read_message

	task send_op(input ALU_input_t ALU_in, output ALU_output_t ALU_out);
		ALU_input = ALU_in;
		case(ALU_in.op_mode)
			nop_op: begin : case_nop_op
				@(negedge clk);
			end

			rst_op: begin : case_rst_op
				reset_dut();
			end

			default: begin : case_default
				send_message(ALU_in);
				read_message(ALU_output);
				ALU_out = ALU_output;
				rcv_flag = 1'b1;
			end
		endcase
		@(negedge clk);
	endtask

	initial begin
		static bit in_command = 0;

		forever begin : op_monitor
			@(posedge clk);
			if (rcv_flag) begin : sent_and_received
				if (!in_command) begin : new_command
					command_monitor_h.write_to_monitor(ALU_input);
					in_command = (ALU_input.op_mode != nop_op);
				end : new_command
			end : sent_and_received
			else begin
				in_command = 0;
			end
		end : op_monitor
	end

	initial begin : rst_monitor
		forever begin
			@(negedge rst_n)
				ALU_input.op_mode = rst_op;
			if (command_monitor_h != null) //guard against VCS time 0 negedge
			begin
				command_monitor_h.write_to_monitor(ALU_input);
			end
		end
	end : rst_monitor

	initial begin : result_monitor_thread
		forever begin
			@(posedge clk) ;
			if (rcv_flag) begin
				result_monitor_h.write_to_monitor(ALU_output);
				rcv_flag = 1'b0;
			end
		end
	end : result_monitor_thread

endinterface : alu_bfm