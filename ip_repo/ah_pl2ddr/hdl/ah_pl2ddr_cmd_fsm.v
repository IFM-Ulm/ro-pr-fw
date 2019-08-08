
module ah_pl2ddr_cmd_fsm #(
		parameter DATA_WIDTH = 1,
		parameter DSP_FOR_CALC = 0,
		parameter RESET_WAIT = 0
	)(
	
	input wire clk,
	input wire rst,
	
	input wire [31:0] in_cmd_data,
	input wire in_cmd_en,

	input wire [31:0] in_sampling_mode,

	// ToDo : sample en as it might be only a pulse and is not checked all the time, also implement en-ack
	input wire [31:0] in_number_samples,
	input wire [31:0] in_undersampling,

	input wire [31:0] in_ddr_addr_low,
	input wire [31:0] in_ddr_addr_high,
	
	input wire [31:0] in_data_index,
	input wire [5:0] in_data_pending,
	
	input wire in_enable,
	
	input wire in_transfer_en,
	output wire out_transfer_active,
	
	output out_rst_data,
	output wire out_enable_active,
	output wire out_enable_ovw,
	output wire out_testmode,
	output wire out_fill_data,
	
	output wire [31:0]  out_axi_slave_ddr_addr,
	output wire [8:0] out_axi_slave_burst_len,
	output wire [10:0] out_axi_slave_burst_number,
	
	output wire out_data_overwrite,
	output wire [DATA_WIDTH-1:0] out_data_overwrite_value,
	output wire [31:0] out_undersampling_value,
	
	input wire in_axi_error,
	output wire out_axit_slave_tx_init,
	input wire in_axi_slave_tx_done,
	
	input wire in_data_error,
	
	input wire [9:0] data_available,
	input wire [9:0] in_bram_addr_read,
	input wire [9:0] in_bram_addr_write,
	
	output wire [31:0] out_cmd_processed,
	
	
	output wire [7:0] out_status,
	output wire [3:0] out_cmdfsm_state,
	output wire [31:0] out_debugging,
	
	output wire intr_sent,
	output wire intr_done,
	output wire intr_error,
	output wire intr_ack
	
);
	
	localparam IDLE = 4'd0, EXECUTE_CMD = 4'd1, SAMPLE_DATA = 4'd2, FILL_DATA = 4'd3, INIT_TX = 4'd4, START_TX = 4'd5, WAIT_TX = 4'd6, 
				INTR_SENT = 4'd7, INTR_DONE = 4'd8, INTR_ACK = 4'd9, INTR_ERROR = 4'd10, ERROR = 4'd11, WAIT = 4'd12;
	localparam NO_SAMPLING = 3'b000, FREE_RUNNING = 3'b001, SAMPLED = 3'b010, UNDERSAMPLED = 3'b011, MANUAL = 3'b100, RUNNING = 3'b101;
	localparam CMD_NONE = 32'h00000000, CMD_RST = 32'h00000001, CMD_RST_ADDR = 32'h00000002, CMD_RST_DATA = 32'h00000004, CMD_DISABLE = 32'h00000020, CMD_ENABLE = 32'h00000021, 
				CMD_TRIGGER_TX = 32'h00000100, CMD_FORCE_TX = 32'h00000101, CMD_TRIGGER_SAMPLE = 32'h00000102, CMD_TRIGGER_FILLDATA = 32'h00000104, 
				CMD_INTR_ONSENT_DISABLE = 32'h00001010, CMD_INTR_ONSENT_ENABLE = 32'h00001011, CMD_INTR_ONDONE_DISABLE = 32'h00001020, CMD_INTR_ONDONE_ENABLE = 32'h00001021,
				CMD_INTR_ONERROR_DISABLE = 32'h00001040, CMD_INTR_ONERROR_ENABLE = 32'h00001041, CMD_INTR_ONACK_DISABLE = 32'h00001080, CMD_INTR_ONACK_ENABLE = 32'h00001081, 
				CMD_TESTMODE_DISABLE = 32'h00010000, CMD_TESTMODE_ENABLE = 32'h00010001;
	localparam ERROR_NONE = 8'h00, ERROR_OUT_OF_MEMORY = 8'h01, ERROR_AXI_FAILED = 8'h02, ERROR_DATA_FAILED = 8'h03;
				
	reg [3 : 0] state = IDLE;
	
	reg rg_enable_active = 0;
	reg rg_enable_ovw = 0;	
	reg rg_fill_data = 0;
	
	reg rg_enable_active_mux;
	reg rg_enable_ovw_mux;
	reg [31:0] rg_undersampling_mux;
	
	reg rg_transfer_active = 0;
	assign out_transfer_active = rg_transfer_active;
	
	always @(in_sampling_mode, rg_enable_active, in_enable, rg_enable_ovw, in_undersampling, in_data_index, in_number_samples) begin
		case(in_sampling_mode)
			NO_SAMPLING : begin
				rg_enable_active_mux <= 0;
				rg_enable_ovw_mux <= 0;
				rg_undersampling_mux <= 0;
			end
			RUNNING : begin
				rg_enable_active_mux <= rg_enable_active || in_enable;
				rg_enable_ovw_mux <= 0;
				rg_undersampling_mux <= 0;
			end
			FREE_RUNNING : begin
				rg_enable_active_mux <= 0;
				rg_enable_ovw_mux <= rg_enable_active || in_enable;
				rg_undersampling_mux <= 0;
			end
			SAMPLED : begin
				rg_enable_active_mux <= in_data_index < in_number_samples ? rg_enable_active || in_enable : 0;
				rg_enable_ovw_mux <= in_data_index < in_number_samples ? 0 : rg_enable_ovw;
				rg_undersampling_mux <= 0;
			end
			UNDERSAMPLED : begin
				rg_enable_active_mux <= in_data_index < in_number_samples ? rg_enable_active || in_enable : 0;
				rg_enable_ovw_mux <= in_data_index < in_number_samples ? 0 : rg_enable_ovw;
				rg_undersampling_mux <= in_undersampling;
			end
			MANUAL : begin
				rg_enable_active_mux <= 0;
				rg_enable_ovw_mux <= rg_enable_ovw;
				rg_undersampling_mux <= 0;
			end
			default : begin
				rg_enable_active_mux <= 0;
				rg_enable_ovw_mux <= 0;
				rg_undersampling_mux <= 0;
			end
		endcase
	end
		
	assign out_enable_active = rg_enable_active_mux;
	assign out_enable_ovw = rg_enable_ovw_mux;
	assign out_undersampling_value = rg_undersampling_mux;
	assign out_fill_data = rg_fill_data;
	
	reg rg_rst_data = 0;
	assign out_rst_data = rg_rst_data;
	
	reg rg_init_tx = 0;
	assign out_axit_slave_tx_init = rg_init_tx;
	
	reg [31:0] rg_ddr_offset = 0;
	wire [31:0] w_next_offset;
	
	reg [10:0] rg_burst_num = 0;
	assign out_axi_slave_burst_number = rg_burst_num;
	
	wire [10:0] rg_burst_num_calc;
	wire [8:0] rg_burst_len_calc;
	
	reg [8:0] rg_burst_len = 0;
	assign out_axi_slave_burst_len = rg_burst_len;
	
	reg rg_force_send = 0;
	
	reg rg_data_overwrite = 0;
	assign out_data_overwrite = rg_data_overwrite;
	
	reg [DATA_WIDTH-1:0] rg_data_value = 0;
	assign out_data_overwrite_value = rg_data_value;
	
	
	reg rg_interrupt_on_done = 0;
	reg rg_interrupt_on_sent = 0;
	reg rg_interrupt_on_ack = 0;
	reg rg_interrupt_on_error = 0;
	
	reg rg_intr_done = 0;
	assign intr_done = rg_intr_done;
	
	reg rg_intr_sent = 0;
	assign intr_sent = rg_intr_sent;
	
	reg rg_done = 0;
	
	reg [4:0] rg_wait_counter = 0;
	
	wire w_done_on_sampled = in_number_samples > 0 && in_data_index >= in_number_samples && (in_sampling_mode == SAMPLED || in_sampling_mode == UNDERSAMPLED);
	
	reg rg_testmode = 0;
	assign out_testmode = rg_testmode;
	
	reg rg_cmd_rcvd = 0;
	reg [31:0] rg_cmd = 0;
	reg rg_cmd_ack = 0;

	reg rg_intr_ack = 0;
	assign intr_ack = rg_intr_ack;
	assign out_cmd_processed = rg_cmd;
	
	reg [7:0] rg_status = 0;
	reg rg_error = 0;
	reg rg_intr_error = 0;
	
	assign out_status = rg_status;
	assign intr_error = rg_intr_error;	
	
	assign out_cmdfsm_state = state;
	assign out_debugging = {4'd0,in_data_index[7:0],in_number_samples[7:0],in_sampling_mode[3:0],
								1'b0,in_enable,rg_enable_ovw_mux,rg_enable_active_mux,
								rg_enable_ovw,rg_enable_active,rg_done,w_done_on_sampled};
	
	
	always @(posedge clk) begin
		if(rst == 1) begin
			rg_cmd_rcvd <= 0;
			rg_cmd <= 0;
		end
		else begin
			if(rg_cmd_rcvd) begin
				if(rg_cmd_ack) begin
					rg_cmd_rcvd <= 0;
				end
			end
			else begin
				if(in_cmd_en) begin
					rg_cmd_rcvd <= 1;
					rg_cmd <= in_cmd_data;
				end
			end
		end	
	end

	ah_pl2ddr_calc #(
		.DSP_FOR_CALC(DSP_FOR_CALC)
	) calc_inst(
		.clk(clk),
		.rst(rst),
		
		.data_available(data_available),
		.in_ddr_addr_low(in_ddr_addr_low),
		.in_ddr_addr_high(in_ddr_addr_high),
		.rg_ddr_offset(rg_ddr_offset),
		.w_burst_len(rg_burst_len),
		
		.w_burst_num_calc(rg_burst_num_calc),
		.w_burst_len_calc(rg_burst_len_calc),
		.w_next_addr(out_axi_slave_ddr_addr),
		.next_offset(w_next_offset)
	);
	
	always @(posedge clk) begin
		if(rst == 1) begin
			state <= IDLE;
			rg_enable_active <= 0;
			rg_rst_data <= 0;
			rg_init_tx <= 0;
			rg_burst_num <= 0;
			rg_burst_len <= 0;
			rg_force_send <= 0;
			rg_data_overwrite <= 0;
			rg_data_value <= 0;
			rg_enable_ovw <= 0;
			rg_fill_data <= 0;
			rg_interrupt_on_sent <= 0;
			rg_interrupt_on_done <= 0;
			rg_intr_ack <= 0;
			rg_intr_error <= 0;
			rg_ddr_offset <= 0;
			rg_done <= 0;
			rg_testmode <= 0;
			rg_error <= 0;
			rg_status <= 0;
			rg_transfer_active <= 0;
		end
		else begin
			case (state)
			
				IDLE : begin
					
					rg_rst_data <= 0;
					rg_intr_sent <= 0;
					rg_intr_done <= 0;
					rg_intr_ack <= 0;
					rg_intr_error <= 0;
					
					rg_enable_ovw <= 0;
					rg_transfer_active <= 0;
					
					if(rg_cmd_rcvd == 1) begin
						if(rg_cmd_ack == 0) begin
							state <= INTR_ACK;
						end
						else begin
							state <= IDLE;
						end						
					end
					else if(rg_error || in_data_error || in_axi_error) begin
						state <= ERROR;
					end
					else if(data_available >= 256 && in_transfer_en) begin
						rg_transfer_active <= 1;
						state <= INIT_TX;
					end
					else if(rg_done == 0 && w_done_on_sampled && in_transfer_en) begin
						
						rg_enable_active <= 0;
						rg_transfer_active <= 1;
						
						if(in_data_pending > 0) begin
							state <= FILL_DATA;
						end
						else if(data_available > 0) begin
							rg_force_send <= 1;
							state <= INIT_TX;
						end
						else begin
							rg_done <= 1;
							state <= INTR_DONE;
						end
					end					
					
				end
				
				WAIT : begin
					if(rg_wait_counter > 0) begin
						rg_wait_counter <= rg_wait_counter - 1;
						state <= WAIT;
					end
					else begin
						state <= IDLE;
					end
				end
				
				INTR_ACK : begin
					
					rg_cmd_ack <= 1;
					if(rg_interrupt_on_ack) begin
						rg_intr_ack <= 1;
					end
					state <= EXECUTE_CMD;
					
				end
				
				EXECUTE_CMD : begin
					
					rg_cmd_ack <= 0;
					rg_intr_ack <= 0;
									
					case(rg_cmd)
					
						CMD_NONE : begin
							state <= IDLE;
						end
						
						CMD_RST : begin
							rg_rst_data <= 1;
							rg_interrupt_on_done <= 0;
							rg_interrupt_on_sent <= 0;
							rg_burst_num <= 0;
							rg_burst_len <= 0;
							rg_force_send <= 0;
							rg_enable_active <= 0;
							rg_testmode <= 0;
							rg_data_overwrite <= 0;
							rg_data_value <= 0;
							rg_enable_ovw <= 0;
							rg_init_tx <= 0;
							rg_intr_sent <= 0;
							rg_intr_done <= 0;
							rg_ddr_offset <= 0;
							rg_done <= 0;
							rg_fill_data <= 0;
							rg_error <= 0;
							rg_transfer_active <= 0;
														
							rg_wait_counter <= RESET_WAIT;
							state <= WAIT;
						end
						
						CMD_RST_ADDR : begin
							rg_ddr_offset <= 0;
							
							rg_wait_counter <= RESET_WAIT;
							state <= WAIT;							
						end
						
						CMD_RST_DATA : begin
							rg_rst_data <= 1;
							rg_done <= 0;
							
							rg_wait_counter <= RESET_WAIT;
							state <= WAIT;
						end
												
						CMD_DISABLE : begin
							rg_enable_active <= 0;
							state <= IDLE;
						end
						
						CMD_ENABLE : begin
							rg_enable_active <= 1;
							state <= IDLE;
						end

						CMD_TRIGGER_TX : begin
							state <= INIT_TX;
						end
						
						CMD_FORCE_TX : begin
							rg_force_send <= 1;
							state <= INIT_TX;
						end
						
						CMD_TRIGGER_SAMPLE : begin
							state <= SAMPLE_DATA;
						end
						
						CMD_TRIGGER_FILLDATA : begin
							state <= FILL_DATA;
						end
						
						CMD_INTR_ONSENT_DISABLE : begin
							rg_interrupt_on_sent <= 0;
							state <= IDLE;
						end
						
						CMD_INTR_ONSENT_ENABLE : begin
							rg_interrupt_on_sent <= 1;
							state <= IDLE;
						end
						
						CMD_INTR_ONDONE_DISABLE : begin
							rg_interrupt_on_done <= 0;
							state <= IDLE;
						end
						
						CMD_INTR_ONDONE_ENABLE : begin
							rg_interrupt_on_done <= 1;
							state <= IDLE;
						end
						
						CMD_INTR_ONERROR_DISABLE : begin
							rg_interrupt_on_error <= 0;
							state <= IDLE;
						end
						
						CMD_INTR_ONERROR_ENABLE : begin
							rg_interrupt_on_error <= 1;
							state <= IDLE;
						end
						
						CMD_INTR_ONACK_DISABLE : begin
							rg_interrupt_on_ack <= 0;
							state <= IDLE;
						end
						
						CMD_INTR_ONACK_ENABLE : begin
							rg_interrupt_on_ack <= 1;
							state <= IDLE;
						end
						
						CMD_TESTMODE_DISABLE : begin
							rg_testmode <= 0;
							state <= IDLE;
						end
						
						CMD_TESTMODE_ENABLE : begin
							rg_testmode <= 1;
							state <= IDLE;
						end
						
						default : begin
							state <= IDLE;
						end
					endcase
					
				end
				
				SAMPLE_DATA : begin
				
					rg_enable_active <= 0;
					rg_data_overwrite <= 0;
					rg_enable_ovw <= 1;
					state <= IDLE;
					
				end
				
				FILL_DATA : begin
				
					if(in_data_pending > 0) begin
						rg_enable_active <= 0;
						rg_data_overwrite <= 1;
						rg_data_value <= 0;
						rg_enable_ovw <= 1;
						rg_fill_data <= 1;
						state <= FILL_DATA;
					end
					else begin
						rg_enable_active <= 0;
						rg_data_overwrite <= 0;
						rg_data_value <= 0;
						rg_enable_ovw <= 0;
						rg_fill_data <= 0;
						state <= IDLE;
					end
					
				end
				
				INIT_TX : begin
					
					if(data_available > 0 && rg_burst_num_calc > 0) begin
						rg_burst_num <= rg_burst_num_calc;
						rg_burst_len <= rg_burst_len_calc;
						state <= START_TX;
					end
					else if(data_available > 0 && rg_burst_num_calc == 0) begin
						state <= ERROR;
					end
					else begin // data_available == 0
						rg_force_send <= 0;
						if(w_done_on_sampled == 0) begin
							state <= INTR_SENT;
						end
						else begin
							state <= IDLE;
						end
						
					end
					
				end	
				
				START_TX : begin
				
					rg_init_tx <= 1;
					state <= WAIT_TX;
					
				end
				
				WAIT_TX : begin
				
					rg_init_tx <= 0;
					
					if(in_axi_slave_tx_done == 1) begin
						
						rg_ddr_offset <= w_next_offset;
					
						if(rg_force_send == 1) begin
							state <= INIT_TX;
						end
						else begin
							if(w_done_on_sampled == 1) begin
								state <= IDLE;
							end
							else begin
								state <= INTR_SENT;
							end
						end

					end
					else begin
						state <= WAIT_TX;
					end
					
				end
				
				INTR_SENT : begin
				
					if(rg_interrupt_on_sent) begin
						rg_intr_sent <= 1;
					end
					
					rg_transfer_active <= 0;
					
					state <= IDLE;
					
				end
				
				INTR_DONE : begin
				
					if(rg_interrupt_on_done) begin
						rg_intr_done <= 1;
					end
					
					rg_transfer_active <= 0;
					
					state <= IDLE;
					
				end
				
				INTR_ERROR : begin
					
					if(rg_interrupt_on_error) begin
						rg_intr_error <= 1;
					end
					state <= ERROR;
					
				end
				
				ERROR : begin
				
					rg_intr_error <= 0;

					rg_status = ERROR_NONE;
					
					if(data_available > 0 && rg_burst_num_calc == 0) begin
						rg_status = rg_status | ERROR_OUT_OF_MEMORY;
					end
					
					if(in_axi_error) begin
						rg_status = rg_status | ERROR_AXI_FAILED;
					end
					
					if(in_data_error) begin
						rg_status = rg_status | ERROR_DATA_FAILED;
					end
					
					if(rg_status == ERROR_NONE) begin
						rg_error <= 0;
						state <= IDLE;
					end
					else begin
						if(rg_error == 0) begin
							rg_error <= 1;
							state <= INTR_ERROR;
						end
					end
					
				end

				default : begin
					state <= IDLE;
				end
				
			endcase
		end
	end

	
endmodule