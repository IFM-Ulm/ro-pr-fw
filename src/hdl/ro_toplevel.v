module ro_toplevel (
	input wire CLK,
	input wire RESET,
	input wire DECOUPLE,
	
	output data_en,
	output [31:0] data_out,

	input [31:0] meas_cmd,
	input [31:0] meas_mode,
	input [31:0] meas_time,
	input [31:0] meas_readouts,
	input [31:0] meas_heatup,
	input [31:0] meas_cooldown,
	
	output meas_done,
	
	output transfer_en,
	input transfer_active

);

	localparam number_RO = 32;

	reg [31:0] rg_addr = 0;

	reg [31:0] rg_selectROmask = 0;
	reg [31:0] rg_heatupROmask = 0;

	wire [number_RO-1:0] counting_in;
	
	wire [3:0] select_static;
	wire [7:0] done_static;
	wire [7:0] counting_static;

    wire w_done;
    
    reg system_reset = 0;
    wire reset_counter;
    wire w_reset_long;
    wire w_reset_short;
    wire w_reset_pulse;
    
    wire START;
	wire [6:0] SELECT;
	
	wire [number_RO - 1 : 0] pr_RO_out;

	wire [32 * number_RO - 1 : 0] icounter_fixed_RO;
	wire [31:0] icounter_ref;
	
    reg [31:0] pr_counter_fixed_RO;

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

	reg rg_meas_done = 0;
	assign meas_done = rg_meas_done;
    
    wire [31:0] data_out_0;
    wire [31:0] data_out_1;
    wire [31:0] data_out_2;

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
	assign data_en = rg_data_en;
	
	reg rg_transfer_en = 0;
	assign transfer_en = rg_transfer_en;
	
	reg [3:0] rg_transfer_timer = 0;

	wire w_start_requested;
	reg rg_start_accepted = 0;

	assign w_reset_long = rg_reset_long || RESET;
	assign w_reset_short = rg_reset_short || RESET;
	assign w_reset_pulse = rg_reset_pulse || RESET;
	
	assign LED = 0;
	
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
		
	
	assign w_start_requested = meas_cmd[0];
	
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
			rg_start_accepted <= 0;
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
						rg_meas_done <= 0;
						rg_data_en <= 0;
						rg_send_counter <= 0;
						
					end
				
				CHECK_NEXT_MEAS : begin
						
						rg_data_en <= 0;
						rg_reset_init <= 0;
						rg_ro_counter <= 0;
						rg_data_counter <= 0;
						
						if(rg_readouts_counter < meas_readouts) begin
							if(rg_send_counter >= 256 && rg_transfer_en == 0) begin
								rg_send_counter <= rg_send_counter - 256;
								rg_transfer_timer <= 10;
								rg_transfer_en <= 1;
							end
							else if(rg_transfer_en == 1) begin
								if(transfer_active == 0) begin
									if(rg_transfer_timer == 0) begin
										rg_transfer_en <= 0;
									end
									else begin
										rg_transfer_timer <= rg_transfer_timer - 1;
									end
								end
							end
							else begin
								rg_readouts_counter <= rg_readouts_counter + 1;
								fsm_state <= RESET_INIT;
							end
						end
						else begin
														
							// signal end of measurement
							rg_meas_done <= 1;
							
							fsm_state <= IDLE;
						end
						
						if(meas_mode[0]) begin // parallel
							rg_selectROmask <= 32'hFFFFFFFF;
						end
						else begin	// serial
							rg_selectROmask <= 32'h00000001;
						end
				
					end
				
				RESET_INIT : begin
						
						rg_data_en <= 0;
						rg_reset_init <= 1;
						rg_cooldown_counter <= 0;
						
						if(rg_heatup_counter < meas_heatup) begin
							rg_heatupROmask <= 32'hFFFFFFFF;
						end
						else begin
							rg_heatupROmask <= 0;
						end
						
						fsm_state <= WAIT_RESET;
						
					end
					
				WAIT_RESET : begin

						
						if(rg_reset_init == 0 && rg_reset_long == 0) begin
							if(rg_first_meas == 0 && rg_cooldown_counter < meas_cooldown) begin
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
							if(rg_heatup_counter < meas_heatup) begin
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
						
						if(meas_mode[0]) begin // parallel -> send ro data ("number_RO" times), then ref data
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
									rg_selectROmask <= {rg_selectROmask[30:0], 1'b0};
									rg_ro_counter <= rg_ro_counter + 1;
									fsm_state <= RESET_INIT;
								end
								else begin
									// check for next measurement
									rg_selectROmask <= 32'h00000001;
									fsm_state <= CHECK_NEXT_MEAS;
								end
								
								rg_data_counter <= 0;
							end

						end
						
					end

		  endcase
		end
	end
	
	assign START = DECOUPLE == 1'b0  ? rg_start : 0;
  
	assign SELECT = DECOUPLE == 1'b0  ? rg_addr[6:0] : 0;
		
	assign w_counter_fixed_RO = DECOUPLE == 1'b0 ? pr_counter_fixed_RO : 0;
	assign data_out = w_counter_fixed_RO;

	assign reset_counter = DECOUPLE || w_reset_long || RESET;
	
	/* select_static :
		0 : 1us
		1 : 10us
		2 : 100us
		3 : 1ms
		4 : 10ms
		5 : 100ms
	*/	
	assign select_static = meas_time[3:0];
	
	assign w_done = DECOUPLE == 1'b0 ? done_static > 0 : 0;
	assign w_counting = DECOUPLE == 1'b0 ? counting_static > 0 : 0; // non-static, reprogramable counter
	
	assign done_static[6] = 0;
	assign counting_static[6] = 0;

	timer_fixed #(48'd000007000) // 100 MHz
	inst_timer_70us (
        .CLK(CLK),
        .reset(w_reset_pulse),
        .start(START && select_static == 4'd7),
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
        .start(START && select_static == 4'd5),
        .done(done_static[5]),
		.counting(counting_static[5]),
        .timer_count()
    );
	
	timer_fixed #(48'd000003000) // 100 MHz
	inst_timer_30us (
        .CLK(CLK),
        .reset(w_reset_pulse),
        .start(START && select_static == 4'd4),
        .done(done_static[4]),
		.counting(counting_static[4]),
        .timer_count()
    );
	
	timer_fixed #(48'd000100000) // 100 MHz
	inst_timer_1ms (
        .CLK(CLK),
        .reset(w_reset_pulse),
        .start(START && select_static == 4'd3),
        .done(done_static[3]),
		.counting(counting_static[3]),
        .timer_count()
    );
	
	timer_fixed #(48'd000010000) // 100 MHz
	inst_timer_100us (
        .CLK(CLK),
        .reset(w_reset_pulse),
        .start(START && select_static == 4'd2),
        .done(done_static[2]),
		.counting(counting_static[2]),
        .timer_count()
    );
	
	timer_fixed #(48'd000001000) // 100 MHz
	inst_timer_10us (
        .CLK(CLK),
        .reset(w_reset_pulse),
        .start(START && select_static == 4'd1),
        .done(done_static[1]),
		.counting(counting_static[1]),
        .timer_count()
    );
	
	timer_fixed #(48'd000000100) // 100 MHz
	inst_timer_1us (
        .CLK(CLK),
        .reset(w_reset_pulse),
        .start(START && select_static == 4'd0),
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
		assign counting_in[gv] = !DECOUPLE && ((w_counting & (rg_selectROmask[gv] | rg_heatupROmask[gv])) | w_reset_short); 
	end
	endgenerate

	
	PR_module PR_module_inst1 (
		.counting(counting_in),
		.RO_out(pr_RO_out)
    );
	
	RO_ref RO_ref_inst(.enable(w_counting | w_reset_short), .reset(reset_counter), .count(icounter_ref));

endmodule