module ah_pl2ddr_calc #(
		parameter DSP_FOR_CALC = 0
	)(
		input wire clk,
		input wire rst,
		
		input wire [9:0] data_available,
		input wire [31:0] in_ddr_addr_low,
		input wire [31:0] in_ddr_addr_high,
		input wire [31:0] rg_ddr_offset,
		input wire [8:0] w_burst_len,
		
		output wire [10:0] w_burst_num_calc,
		output wire [8:0] w_burst_len_calc,
		output wire [31:0] w_next_addr,
		output wire [31:0] next_offset
);
	
	wire [31:0] w_add_low_off;
	wire [31:0] w_add_off_burstlen;
	wire [10:0] rg_burst_num_calc;
	wire [31:0] w_add_off_comp;
	reg [8:0] rg_burst_len_calc = 0;
	wire [31:0] w_sub_high_low;
	reg [10:0] comp;

	wire [31:0] w_burst_len_expand;
	assign w_burst_len_expand = {21'b0,w_burst_len,2'b00};
	
	wire [31:0] w_comp_expand;
	assign w_comp_expand = {21'd0,comp};
	
	assign rg_burst_num_calc = data_available >= 1 && w_sub_high_low >= w_add_off_comp ? 1 : 0;
	assign w_next_addr = w_add_low_off;	
	assign next_offset = w_add_off_burstlen;
	
	assign w_burst_num_calc = w_sub_high_low >= w_add_off_comp ? rg_burst_num_calc : 0;
	assign w_burst_len_calc = rg_burst_len_calc;

	
	always @(data_available) begin
		if(data_available >= 256) begin
			comp <= 11'd1024;
		end
		else if(data_available >= 128) begin
			comp <= 11'd512;
		end
		else if(data_available >= 64) begin
			comp <= 11'd256;
		end
		else if(data_available >= 32) begin
			comp <= 11'd128;
		end
		else if(data_available >= 16) begin
			comp <= 11'd64;
		end
		else if(data_available >= 8) begin
			comp <= 11'd32;
		end
		else if(data_available >= 4) begin
			comp <= 11'd16;
		end
		else if(data_available >= 2) begin
			comp <= 11'd8;
		end
		else if(data_available >= 1) begin
			comp <= 11'd4;
		end
		else begin
			comp <= 11'd0;
		end
	end

	always @(data_available, in_ddr_addr_low, rg_ddr_offset, in_ddr_addr_high) begin
		if(data_available >= 256) begin
			rg_burst_len_calc <= 256;
		end
		else if(data_available >= 128) begin
			rg_burst_len_calc <= 128;
		end
		else if(data_available >= 64) begin
			rg_burst_len_calc <= 64;
		end
		else if(data_available >= 32) begin
			rg_burst_len_calc <= 32;
		end
		else if(data_available >= 16) begin
			rg_burst_len_calc <= 16;
		end
		else if(data_available >= 8) begin
			rg_burst_len_calc <= 8;
		end
		else if(data_available >= 4) begin
			rg_burst_len_calc <= 4;
		end
		else if(data_available >= 2) begin
			rg_burst_len_calc <= 2;
		end
		else if(data_available >= 1) begin
			rg_burst_len_calc <= 1;
		end
		else begin
			rg_burst_len_calc <= 0;
		end
	end


	generate 
	
		if(DSP_FOR_CALC > 0) begin : calc_dsp
			ADDSUB_MACRO #(
				.DEVICE("7SERIES"), // Target Device: "7SERIES"
				.LATENCY(0), // Desired clock cycle latency, 0-2
				.WIDTH(32) // Input / output bus width, 1-48
			) add_macro_addr_offset (
				.CARRYOUT(), // 1-bit carry-out output signal
				.RESULT(w_add_low_off), // Add/sub result output, width defined by WIDTH parameter
				.A(in_ddr_addr_low), // Input A bus, width defined by WIDTH parameter
				.ADD_SUB(1), // 1-bit add/sub input, high selects add, low selects subtract
				.B(rg_ddr_offset), // Input B bus, width defined by WIDTH parameter
				.CARRYIN(0), // 1-bit carry-in input
				.CE(1), // 1-bit clock enable input
				.CLK(clk), // 1-bit clock input
				.RST(rst) // 1-bit active high synchronous reset
			);
			
			ADDSUB_MACRO #(
				.DEVICE("7SERIES"), // Target Device: "7SERIES"
				.LATENCY(0), // Desired clock cycle latency, 0-2
				.WIDTH(32) // Input / output bus width, 1-48
			) add_macro_offset_burst (
				.CARRYOUT(), // 1-bit carry-out output signal
				.RESULT(w_add_off_burstlen), // Add/sub result output, width defined by WIDTH parameter
				.A(rg_ddr_offset), // Input A bus, width defined by WIDTH parameter
				.ADD_SUB(1), // 1-bit add/sub input, high selects add, low selects subtract
				.B(w_burst_len_expand), // Input B bus, width defined by WIDTH parameter
				.CARRYIN(0), // 1-bit carry-in input
				.CE(1), // 1-bit clock enable input
				.CLK(clk), // 1-bit clock input
				.RST(rst) // 1-bit active high synchronous reset
			);
			
			ADDSUB_MACRO #(
				.DEVICE("7SERIES"), // Target Device: "7SERIES"
				.LATENCY(0), // Desired clock cycle latency, 0-2
				.WIDTH(32) // Input / output bus width, 1-48
			) sub_macro_high_res (
				.CARRYOUT(), // 1-bit carry-out output signal
				.RESULT(w_sub_high_low), // Add/sub result output, width defined by WIDTH parameter
				.A(in_ddr_addr_high), // Input A bus, width defined by WIDTH parameter
				.ADD_SUB(0), // 1-bit add/sub input, high selects add, low selects subtract
				.B(in_ddr_addr_low), // Input B bus, width defined by WIDTH parameter
				.CARRYIN(0), // 1-bit carry-in input
				.CE(1), // 1-bit clock enable input
				.CLK(clk), // 1-bit clock input
				.RST(rst) // 1-bit active high synchronous reset
			);
			
			ADDSUB_MACRO #(
				.DEVICE("7SERIES"), // Target Device: "7SERIES"
				.LATENCY(0), // Desired clock cycle latency, 0-2
				.WIDTH(32) // Input / output bus width, 1-48
			) add_macro_off_comp (
				.CARRYOUT(), // 1-bit carry-out output signal
				.RESULT(w_add_off_comp), // Add/sub result output, width defined by WIDTH parameter
				.A(rg_ddr_offset), // Input A bus, width defined by WIDTH parameter
				.ADD_SUB(1), // 1-bit add/sub input, high selects add, low selects subtract
				.B(w_comp_expand), // Input B bus, width defined by WIDTH parameter
				.CARRYIN(0), // 1-bit carry-in input
				.CE(1), // 1-bit clock enable input
				.CLK(clk), // 1-bit clock input
				.RST(rst) // 1-bit active high synchronous reset
			);
		end
		else begin : calc_adders
		
			assign w_add_low_off = in_ddr_addr_low + rg_ddr_offset;
			assign w_add_off_burstlen = rg_ddr_offset + w_burst_len_expand;
			assign w_sub_high_low = in_ddr_addr_high - in_ddr_addr_low;
			assign w_add_off_comp = rg_ddr_offset + w_comp_expand;
			
		end
	endgenerate
	
endmodule