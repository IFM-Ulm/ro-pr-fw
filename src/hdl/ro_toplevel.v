`include "portarray_pack_unpack.vh"

module ro_toplevel #(
		parameter number_inputs = 7,
		parameter number_outputs = 3
	)(
	input wire CLK,
	input wire RESET,
	input wire DECOUPLE,
	
	input wire [number_inputs-1:0] intr_in,
	input wire [number_inputs*32-1:0] data_in,
	
	output wire [number_outputs-1:0] intr_out,
	output wire [number_outputs*32-1:0] data_out,
	
	input wire [3:0] SW,
	input wire [3:0] BTN,
	output wire [3:0] LED

);

	localparam number_RO = 32;
	localparam last_RO = 64'h0000000080000000;

	wire [31:0] w_inputs [0:number_inputs-1];
	`UNPACK_PORTARRAY(32, number_inputs, w_inputs, data_in)

	reg [31:0] rg_cmd = 0;
	reg [31:0] rg_heatup = 0;
	reg [31:0] rg_cooldown = 0;
	reg [31:0] rg_addr = 0;
	reg [31:0] rg_time = 0;
	reg [31:0] rg_number_readouts = 0;
	reg [31:0] rg_mode = 0;
	reg [63:0] rg_selectROmask = 0;
	reg [63:0] rg_heatupROmask = 0;

	wire [number_RO-1:0] counting_in;
	
	wire [3:0] select_static;
	wire [7:0] done_static;
	wire done_static_0to3;
	wire done_static_4to7;
	wire done_static_all;
	wire [7:0] counting_static;
	wire counting_static_0to3;
	wire counting_static_4to7;
	wire counting_static_all;
	
	wire w_started;
    wire w_done;
    
    reg system_reset = 0;
    wire reset_counter;
    wire w_reset_long;
    wire w_reset_short;
    wire w_reset_pulse;
    
    wire START;
	wire [6:0] SELECT;
	
	wire [number_RO - 1 : 0] pr_RO_out;
	wire pr_ref_out;
	wire [32 * number_RO - 1 : 0] icounter_fixed_RO;
	wire [31:0] icounter_ref;
	
    reg [31:0] pr_counter_fixed_RO;

	reg [31:0] rg_LED = 0;
			
	reg decouple_deactivate = 0;
	reg [4:0] decouple_counter = 0;
	
    localparam reset_IDLE = 1'b0, reset_COUNT = 1'b1;
    reg reset_state = reset_IDLE;
	
	reg rg_reset_long = 0;
	reg rg_reset_short = 0;
	reg rg_reset_pulse = 0;
	reg rg_reset_init = 0;
	
	reg [4:0] rg_reset_counter = 0;
	reg [31:0] rg_heatup_counter = 0;
	reg [31:0] rg_cooldown_counter = 0;
		
    wire [31:0] w_counter_fixed_RO;

	reg [number_outputs - 1 : 0] gen_intr_out = 0;
    
    wire [31:0] data_out_0;
    wire [31:0] data_out_1;
    wire [31:0] data_out_2;

	wire w_done_all;
    wire w_counting_all;
    wire w_counting;
	
	
	localparam IDLE = 4'd0, CHECK_NEXT_MEAS = 4'd1,  RESET_INIT = 4'd2, WAIT_RESET = 4'd3, WAIT_MEAS = 4'd4, SEND_READOUTS = 4'd5;
	reg [3 : 0] fsm_state = IDLE;
	
	reg [31:0] rg_readouts_counter = 0;
	reg [31:0] rg_send_counter = 0;
	reg [6:0] rg_ro_counter = 0;
	reg rg_data_counter = 0;
	reg rg_start = 0;
	reg rg_first_meas = 1;
	reg rg_data_en = 0;
	
	reg rg_transfer_en = 0;
	reg [3:0] rg_transfer_timer = 0;
	wire [31:0] w_data_in_6;
	
	wire w_transfer_active;
		
	wire w_start_requested;
	reg rg_start_accepted = 0;
	
	assign w_data_in_6 = w_inputs[6];
	assign w_transfer_active = w_data_in_6[0];
	
	assign w_reset_long = rg_reset_long || RESET;
	assign w_reset_short = rg_reset_short || RESET;
	assign w_reset_pulse = rg_reset_pulse || RESET;
	
	assign LED = 0;
	
	// logic to store input values when data transfer is indicated by interrupts
	always @(posedge CLK) begin
		if(RESET) begin
			rg_cmd <= 0;
			rg_mode <= 0;
			rg_time <= 0;
			rg_number_readouts <= 0;
			rg_heatup <= 0;
			rg_cooldown <= 0;
		end
		else begin
		
			if(intr_in[0]) begin
				rg_cmd <= w_inputs[0];
			end
			
			if(intr_in[1]) begin
				rg_mode <= w_inputs[1];
			end
			
			if(intr_in[2]) begin
				rg_time <= w_inputs[2];
			end

			if(intr_in[3]) begin
				rg_number_readouts <= w_inputs[3];
			end
			
			if(intr_in[4]) begin
				rg_heatup <= w_inputs[4];
			end
			
			if(intr_in[5]) begin
				rg_cooldown <= w_inputs[5];
			end

		end
	end
	
	always @(posedge CLK) begin
		if(RESET) begin // activate reset by peripherial reset
			rg_reset_counter <= 0;
			rg_reset_long <= 0;
			rg_reset_short <= 0;
			rg_reset_pulse <= 0;
			reset_state <= reset_IDLE;
		end
		else begin
			case (reset_state)

				reset_IDLE : begin
						
						rg_reset_counter <= 0;
						
						if(rg_reset_init == 1) begin
							
							rg_reset_long <= 1;
							rg_reset_short <= 1;
							rg_reset_pulse <= 1;

							reset_state <= reset_COUNT;
						end
						else begin
						
							rg_reset_long <= 0;
							rg_reset_short <= 0;
							rg_reset_pulse <= 0;
						
							reset_state <= reset_IDLE;
						end
						
					end
					
				reset_COUNT : begin
				
						if(rg_reset_counter > 5) begin
						
							rg_reset_long <= 0;
							rg_reset_counter <= 0;
							
							reset_state <= reset_IDLE;
						end
						else begin
							
							if(rg_reset_counter > 2) begin
								rg_reset_short <= 0;
							end

							rg_reset_pulse <= 0;
							
							rg_reset_counter <= rg_reset_counter + 1;
							
							reset_state <= reset_COUNT;
						end				
					
					end

				default : begin
				
					reset_state <= reset_IDLE;
					
					end
				
			endcase
		end
	end
	
	
	
	assign w_start_requested = rg_cmd[0];
	
	always @(posedge CLK) begin
		if(RESET) begin
			fsm_state <= IDLE;
			rg_readouts_counter <= 0;
			rg_send_counter <= 0;
			rg_data_counter <= 0;
			rg_ro_counter <= 0;
			rg_reset_init <= 0;
			rg_transfer_en <= 0;
			rg_transfer_timer <= 0;
			rg_data_en <= 0;
			rg_heatup_counter <= 0;
			rg_heatupROmask <= 0;
			rg_cooldown_counter <= 0;
			rg_first_meas <= 1;
		end
		else begin
			case (fsm_state)
			
				IDLE : begin

						// prevent measurement to restart, wait for cmd=START to be reset
						if(rg_start_accepted) begin
							if(w_start_requested == 0) begin
								rg_start_accepted <= 0;
							end
						end
						else begin
							if(w_start_requested) begin
								rg_start_accepted <= 1;
								fsm_state <= CHECK_NEXT_MEAS;
							end
						end
						
						// always allow transfer in IDLE
						rg_heatup_counter <= 0;
						rg_cooldown_counter <= 0;
						rg_first_meas <= 1;
						rg_transfer_en <= 1;
						rg_readouts_counter <= 0;
						rg_start <= 0;
						gen_intr_out[1] <= 0;
						rg_data_en <= 0;
						
					end
				
				CHECK_NEXT_MEAS : begin
						
						rg_data_en <= 0;
						rg_reset_init <= 0;
						rg_ro_counter <= 0;
						rg_data_counter <= 0;
						
						if(rg_readouts_counter < rg_number_readouts) begin
							if(rg_send_counter >= 512 && rg_transfer_en == 0) begin
								rg_send_counter <= rg_send_counter - 256;
								rg_transfer_timer <= 3;
								rg_transfer_en <= 1;
							end
							else if(rg_transfer_en == 1) begin
								if(rg_transfer_timer == 0) begin
									if(w_transfer_active == 0) begin
										rg_transfer_en <= 0;
									end
								end
								else begin
									rg_transfer_timer <= rg_transfer_timer - 1;
								end
							end
							else begin
								rg_readouts_counter <= rg_readouts_counter + 1;
								fsm_state <= RESET_INIT;
							end
						end
						else begin
														
							// signal end of measurement
							gen_intr_out[1] <= 1;
							
							fsm_state <= IDLE;
						end
						
						if(rg_mode[0]) begin // parallel
							rg_selectROmask <= 64'h00000000FFFFFFFF;
						end
						else begin	// serial
							rg_selectROmask <= 64'h0000000000000001;
						end
				
					end
				
				RESET_INIT : begin
						
						rg_data_en <= 0;
						rg_reset_init <= 1;
						rg_cooldown_counter <= 0;
						
						if(rg_heatup_counter < rg_heatup) begin
							rg_heatupROmask <= 64'h00000000FFFFFFFF;
						end
						else begin
							rg_heatupROmask <= 0;
						end
						
						fsm_state <= WAIT_RESET;
						
					end
					
				WAIT_RESET : begin

						
						if(rg_reset_init == 0 && rg_reset_long == 0) begin
							if(rg_first_meas == 0 && rg_cooldown_counter < rg_cooldown) begin
								rg_cooldown_counter <= rg_cooldown_counter + 1;
							end
							else begin
								rg_start <= 1;
								fsm_state <= WAIT_MEAS;
							end
						end
						
						rg_reset_init <= 0;
						
					end
					
				 WAIT_MEAS : begin
						
						rg_start <= 0;

						if(w_done) begin
							if(rg_heatup_counter < rg_heatup) begin
								rg_heatup_counter <= rg_heatup_counter + 1;
								fsm_state <= RESET_INIT;
							end
							else begin
								rg_first_meas <= 0;
								fsm_state <= SEND_READOUTS;
							end
						end
						
						
					end
				
				SEND_READOUTS : begin
						
						if(rg_mode[0]) begin // parallel -> send ro data ("number_RO" times), then ref data
							if(rg_ro_counter < number_RO) begin
							
								// send ro data
								rg_addr[6:0] <= rg_ro_counter;
								rg_data_en <= 1;
								rg_send_counter <= rg_send_counter + 1;								
								
								rg_ro_counter <= rg_ro_counter + 1;
							end
							else begin
							
								// send ref data
								rg_addr[6:0] <= 6'h3F;
								rg_data_en <= 1;								
								rg_send_counter <= rg_send_counter + 1;	
								
								// check for next measurement
								fsm_state <= CHECK_NEXT_MEAS;
							end
						end
						else begin	// serial -> send one ro data and its affiliated ref data, then start next ro or next measurement
							if(rg_data_counter == 0) begin
							
								// send ro data
								rg_addr[6:0] <= rg_ro_counter;
								rg_data_en <= 1;
								rg_send_counter <= rg_send_counter + 1;	
								
								rg_data_counter <= 1;							
							end
							else begin
							
								// send ref data
								rg_addr[6:0] <= 6'h3F;
								rg_data_en <= 1;
								rg_send_counter <= rg_send_counter + 1;
								
								if(rg_ro_counter < (number_RO-1)) begin
									// start next ro
									rg_selectROmask <= {rg_selectROmask[62:0], 1'b0};
									rg_ro_counter <= rg_ro_counter + 1;
									fsm_state <= RESET_INIT;
								end
								else begin
									// check for next measurement
									rg_selectROmask <= 64'h0000000000000001;
									fsm_state <= CHECK_NEXT_MEAS;
								end
								
								rg_data_counter <= 0;
							end

						end
						
					end

		  endcase
		end
	end
	
	assign START = decouple_deactivate == 0 ? rg_start : 0;
  
	assign SELECT = decouple_deactivate == 0 ? rg_addr[6:0] : 0;
			
	assign w_counter_fixed_RO = decouple_deactivate == 0 ? pr_counter_fixed_RO : 0;

    FDRE #(.INIT(1'b0)) FDRE_hold_start (.Q(w_started), .C(CLK), .CE(START), .R(w_reset_pulse), .D(1'b1));

	assign data_out_0 = {10'b0, rg_addr, rg_transfer_timer, w_transfer_active, rg_transfer_en, w_done, rg_start, rg_reset_init, rg_start_accepted, w_start_requested, fsm_state}; // debug port
	//assign data_out_0 = {32'b0}; // debug port
	assign data_out_1 = w_counter_fixed_RO;
	assign data_out_2 = {30'b0, rg_transfer_en, rg_data_en};
	assign data_out = {data_out_2, data_out_1, data_out_0};
	
	assign intr_out = gen_intr_out;

	assign reset_counter = decouple_deactivate || w_reset_long || RESET;
	
	always @(posedge CLK) begin
		if(RESET) begin
			decouple_deactivate <= 0;
			decouple_counter <= 0;
		end
		else begin
			if(DECOUPLE) begin
				decouple_deactivate <= 1;
				decouple_counter <= 24;
			end
			else begin
				if(decouple_counter > 0) begin
					decouple_counter <= decouple_counter - 1;
				end
				else begin
					decouple_deactivate <= 0;
				end
			end
		end
	end
	
	/* select_static :
		0 : 1us
		1 : 10us
		2 : 100us
		3 : 1ms
		4 : 10ms
		5 : 100ms
	*/	
	assign select_static = rg_time[3:0];
	
	assign w_done = decouple_deactivate == 0 ? done_static_all : 0;
	assign w_counting = decouple_deactivate == 0 ? counting_static_all : 0; // non-static, reprogramable counter
	
	assign done_static[6] = 0;
	assign counting_static[6] = 0;
	
	(* dont_touch = "yes" *) LUT6 #(.INIT(64'hFEDCBA9876543210)) LUT6_done_static_0t3 (.O(done_static_0to3),.I5(done_static[3]),.I4(done_static[2]),.I3(done_static[1]),.I2(done_static[0]),.I1(select_static[1]),.I0(select_static[0]));
	(* dont_touch = "yes" *) LUT6 #(.INIT(64'hFEDCBA9876543210)) LUT6_done_static_4to7 (.O(done_static_4to7),.I5(done_static[7]),.I4(done_static[6]),.I3(done_static[5]),.I2(done_static[4]),.I1(select_static[1]),.I0(select_static[0]));
	(* dont_touch = "yes" *) LUT6 #(.INIT(64'hFFFFAAAA55550000)) LUT6_done_static_all (.O(done_static_all),.I5(done_static_4to7),.I4(done_static_0to3),.I3(0),.I2(0),.I1(select_static[3]),.I0(select_static[2]));
		
	(* dont_touch = "yes" *) LUT6 #(.INIT(64'hFEDCBA9876543210)) LUT6_counting_static_0to3 (.O(counting_static_0to3),.I5(counting_static[3]),.I4(counting_static[2]),.I3(counting_static[1]),.I2(counting_static[0]),.I1(select_static[1]),.I0(select_static[0]));
	(* dont_touch = "yes" *) LUT6 #(.INIT(64'hFEDCBA9876543210)) LUT6_counting_static_4to7 (.O(counting_static_4to7),.I5(counting_static[7]),.I4(counting_static[6]),.I3(counting_static[5]),.I2(counting_static[4]),.I1(select_static[1]),.I0(select_static[0]));
	(* dont_touch = "yes" *) LUT6 #(.INIT(64'hFFFFAAAA55550000)) LUT6_counting_static_all (.O(counting_static_all),.I5(counting_static_4to7),.I4(counting_static_0to3),.I3(0),.I2(0),.I1(select_static[3]),.I0(select_static[2]));
	
	
	timer_fixed #(48'd000007000) // 100 MHz
	inst_timer_70us (
        .CLK(CLK),
        .reset(w_reset_pulse),
        .start(START),
        .done(done_static[7]),
		.counting(counting_static[7]),
        .timer_count()
    );
	
	
	/*
	timer_fixed #(48'd100000000) // 100 MHz
	inst_timer_1s (
        .CLK(CLK),
        .reset(w_reset_pulse),
        .start(START),
        .done(done_static[6]),
		.counting(counting_static[6]),
        .timer_count()
    );
	*/
	
	timer_fixed #(48'd000005000) // 100 MHz
	inst_timer_50us (
        .CLK(CLK),
        .reset(w_reset_pulse),
        .start(START),
        .done(done_static[5]),
		.counting(counting_static[5]),
        .timer_count()
    );
	
	timer_fixed #(48'd000003000) // 100 MHz
	inst_timer_30us (
        .CLK(CLK),
        .reset(w_reset_pulse),
        .start(START),
        .done(done_static[4]),
		.counting(counting_static[4]),
        .timer_count()
    );
	
	timer_fixed #(48'd000100000) // 100 MHz
	inst_timer_1ms (
        .CLK(CLK),
        .reset(w_reset_pulse),
        .start(START),
        .done(done_static[3]),
		.counting(counting_static[3]),
        .timer_count()
    );
	
	timer_fixed #(48'd000010000) // 100 MHz
	inst_timer_100us (
        .CLK(CLK),
        .reset(w_reset_pulse),
        .start(START),
        .done(done_static[2]),
		.counting(counting_static[2]),
        .timer_count()
    );
	
	timer_fixed #(48'd000001000) // 100 MHz
	inst_timer_10us (
        .CLK(CLK),
        .reset(w_reset_pulse),
        .start(START),
        .done(done_static[1]),
		.counting(counting_static[1]),
        .timer_count()
    );
	
	timer_fixed #(48'd000000100) // 100 MHz
	inst_timer_1us (
        .CLK(CLK),
        .reset(w_reset_pulse),
        .start(START),
        .done(done_static[0]),
		.counting(counting_static[0]),
        .timer_count()
    );
		
	genvar gv;
    generate
	for (gv = 0; gv < number_RO; gv = gv + 1) begin : counter_Gen
		(* dont_touch = "yes" *) counter_fixed inst_counter_fixed_pr(.CLK(pr_RO_out[gv]), .reset(reset_counter), .count(icounter_fixed_RO[(gv+1)*32-1:gv*32]));
	end
	endgenerate


	always @(icounter_fixed_RO or SELECT or icounter_ref) begin
		case(SELECT)
			 0 : begin pr_counter_fixed_RO = icounter_fixed_RO[31+ 0*32 :  0*32]; end
			 1 : begin pr_counter_fixed_RO = icounter_fixed_RO[31+ 1*32 :  1*32]; end
			 2 : begin pr_counter_fixed_RO = icounter_fixed_RO[31+ 2*32 :  2*32]; end
			 3 : begin pr_counter_fixed_RO = icounter_fixed_RO[31+ 3*32 :  3*32]; end
			 4 : begin pr_counter_fixed_RO = icounter_fixed_RO[31+ 4*32 :  4*32]; end
			 5 : begin pr_counter_fixed_RO = icounter_fixed_RO[31+ 5*32 :  5*32]; end
			 6 : begin pr_counter_fixed_RO = icounter_fixed_RO[31+ 6*32 :  6*32]; end
			 7 : begin pr_counter_fixed_RO = icounter_fixed_RO[31+ 7*32 :  7*32]; end
			 8 : begin pr_counter_fixed_RO = icounter_fixed_RO[31+ 8*32 :  8*32]; end
			 9 : begin pr_counter_fixed_RO = icounter_fixed_RO[31+ 9*32 :  9*32]; end
			10 : begin pr_counter_fixed_RO = icounter_fixed_RO[31+10*32 : 10*32]; end
			11 : begin pr_counter_fixed_RO = icounter_fixed_RO[31+11*32 : 11*32]; end
			12 : begin pr_counter_fixed_RO = icounter_fixed_RO[31+12*32 : 12*32]; end
			13 : begin pr_counter_fixed_RO = icounter_fixed_RO[31+13*32 : 13*32]; end
			14 : begin pr_counter_fixed_RO = icounter_fixed_RO[31+14*32 : 14*32]; end
			15 : begin pr_counter_fixed_RO = icounter_fixed_RO[31+15*32 : 15*32]; end
			16 : begin pr_counter_fixed_RO = icounter_fixed_RO[31+16*32 : 16*32]; end
			17 : begin pr_counter_fixed_RO = icounter_fixed_RO[31+17*32 : 17*32]; end
			18 : begin pr_counter_fixed_RO = icounter_fixed_RO[31+18*32 : 18*32]; end
			19 : begin pr_counter_fixed_RO = icounter_fixed_RO[31+19*32 : 19*32]; end
			20 : begin pr_counter_fixed_RO = icounter_fixed_RO[31+20*32 : 20*32]; end
			21 : begin pr_counter_fixed_RO = icounter_fixed_RO[31+21*32 : 21*32]; end
			22 : begin pr_counter_fixed_RO = icounter_fixed_RO[31+22*32 : 22*32]; end
			23 : begin pr_counter_fixed_RO = icounter_fixed_RO[31+23*32 : 23*32]; end
			24 : begin pr_counter_fixed_RO = icounter_fixed_RO[31+24*32 : 24*32]; end
			25 : begin pr_counter_fixed_RO = icounter_fixed_RO[31+25*32 : 25*32]; end
			26 : begin pr_counter_fixed_RO = icounter_fixed_RO[31+26*32 : 26*32]; end
			27 : begin pr_counter_fixed_RO = icounter_fixed_RO[31+27*32 : 27*32]; end
			28 : begin pr_counter_fixed_RO = icounter_fixed_RO[31+28*32 : 28*32]; end
			29 : begin pr_counter_fixed_RO = icounter_fixed_RO[31+29*32 : 29*32]; end
			30 : begin pr_counter_fixed_RO = icounter_fixed_RO[31+30*32 : 30*32]; end
			31 : begin pr_counter_fixed_RO = icounter_fixed_RO[31+31*32 : 31*32]; end
			default : begin pr_counter_fixed_RO = icounter_ref; end
		endcase
	end

    generate	
	for (gv = 0; gv < number_RO; gv = gv + 1) begin : GEN_counting
		assign counting_in[gv] = (w_counting & (rg_selectROmask[gv] | rg_heatupROmask[gv])) | w_reset_short; 
	end
	endgenerate

	
	PR_module PR_module_inst1 (
		.counting(counting_in),
		.RO_out(pr_RO_out)
    );
	
	RO_ref RO_ref_inst(.enable(w_counting | w_reset_short), .reset(reset_counter), .count(icounter_ref));

endmodule