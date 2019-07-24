module ah_pl2ddr_data_control #(
		parameter DATA_WIDTH = 1
	)(
	
	input wire clk_data,
	input wire clk_system,
	input wire rst,
	
	input wire [DATA_WIDTH-1:0] data_in,
	input wire data_en,
	input wire [31:0] data_undersampling,
	input wire testmode,
	input wire fill_data,
	
	input wire data_next,
	output wire [31:0] data_out,
	
	output wire [9:0] addr_read,
	output wire [9:0] addr_write,
	
	output wire [31:0] data_index,
	output wire [5:0] data_pending,
	output wire [9:0] data_available,
	output wire [31:0] data_read,
	
	output wire error

);
	
	wire [31:0] w_data_collected;
	wire [31:0] w_data_bram;
	wire w_write_valid;
	wire [31:0] w_data_index;
	

	reg [9:0] rg_addr_in = 0;
	reg [9:0] rg_addr_out = 0;
	
	reg [31:0] rg_data_read = 0;
	reg [31:0] rg_data_written = 0;
	
	reg [31:0] rg_data_available = 0;
	wire [31:0] w_data_available;
	assign data_available = rg_data_available[9:0];
	
	assign data_index = w_data_index;
	assign w_data_bram = testmode ? w_data_index : w_data_collected;
	assign data_read = rg_data_read;
	
	assign addr_read = rg_addr_out;
	assign addr_write = rg_addr_in;

	wire w_reset_data;
	
	always @(posedge clk_data) begin
		if (rst == 1 || w_reset_data) begin
			rg_addr_in <= 0;
		end
		else begin
			if(w_write_valid == 1) begin
				if(rg_addr_in < 1023) begin
					rg_addr_in <= rg_addr_in + 1;
				end
				else begin
					rg_addr_in <= 0;
				end
			end
		end
	end

	reg rg_buffered = 0;
	reg rg_buffer_used = 0;
	reg [31:0] rg_data_buffer = 0;
	wire [31:0] w_data_out;
	
	assign data_out = rg_buffered && !rg_buffer_used ? rg_data_buffer : w_data_out;
		
	wire [9:0] next_address;
	// assign next_address = rg_addr_out;
	assign next_address = rg_buffered == 1 ? rg_addr_out + 1 : rg_addr_out;
	
	reg rg_error = 0;
	assign error = rg_error;
	
	

	always @(posedge clk_system) begin
		if (rst == 1) begin
			rg_addr_out <= 0;
		end
		else begin
			if(rg_buffered == 0 && data_next == 0 && w_data_available > 1) begin
				// rg_addr_out <= rg_addr_out < 1023 ? rg_addr_out + 1 : 0;
			end
			else begin
				if(data_next == 1) begin				
					rg_addr_out <= rg_addr_out < 1023 ? rg_addr_out + 1 : 0;
				end
			end
		end
	end
	
	always @(posedge clk_system) begin
		if (rst == 1) begin
			rg_buffered <= 0;
			rg_data_buffer <= 0;
			rg_buffer_used <= 0;
		end
		else begin
			if(rg_buffered == 0 && data_next == 0 && w_data_available > 1) begin
				rg_data_buffer <= w_data_out;
				rg_buffer_used <= 0;
				rg_buffered <= 1;
			end
			else begin
				if(data_next == 1) begin
					rg_data_buffer <= w_data_out;
					rg_buffer_used <= 1;
					//rg_buffered <= 0;
				end
				else begin
					if(w_data_available == 0) begin
						rg_data_buffer <= 0;
						rg_buffered <= 0;
						//rg_buffer_used <= 0;
					end
					else begin
						if(rg_buffer_used && rg_data_available > 1) begin
							rg_data_buffer <= w_data_out;
							rg_buffer_used <= 0;
							rg_buffered <= 1;
						end
					end
				end
			end
		end
	end
	
	reg rg_next = 0;
	always @(posedge clk_system) begin
		if (rst == 1 || w_reset_data == 1) begin
			rg_next <= 0;
		end
		else begin
			rg_next <= data_next;
		end
	end
	
	always @(posedge clk_system) begin
		if (rst == 1 || w_reset_data == 1) begin
			rg_data_read <= 0;
		end
		else begin
			// if(data_next == 1 || rg_next) begin
			if(data_next == 1) begin
				rg_data_read <= rg_data_read + 1;
			end
		end
	end
	
	always @(posedge clk_data) begin
		if (rst == 1 || w_reset_data == 1) begin
			rg_data_written <= 0;
		end
		else begin
			if(w_write_valid == 1) begin
				rg_data_written <= rg_data_written + 1;
			end
		end
	end
	
	always @(posedge clk_system) begin
		if (rst == 1) begin
			rg_error <= 0;
		end
		else begin
			if(rg_data_written < rg_data_read) begin
				rg_error <= 1;
			end
		end
	end
	
	always @(posedge clk_system) begin
		if (rst == 1) begin
			rg_data_available <= 0;
		end
		else begin
			rg_data_available <= w_data_available;
		end
	end
	
	
	
	assign w_data_available = rg_data_written - rg_data_read;
	

	ah_pl2ddr_tdp_bram bram_inst (
		.clk_in(clk_data),
		.clk_out(clk_system),
		.rst(rst),
		
		.addr_in(rg_addr_in),
		.data_in(w_data_bram),
		.enable_in(w_write_valid),
		
		.addr_out(next_address),
		.data_out(w_data_out)
	);

    ah_pl2ddr_data_collector #(.DATA_WIDTH(DATA_WIDTH)) datacollector_inst(
		.clk(clk_data),
		.rst(w_reset_data || rst),
		
		.data_in(data_in),
		.data_en(data_en),
		.undersampling(data_undersampling),
		.fill_data(fill_data),
	
		.data_out(w_data_collected),
		.data_valid(w_write_valid),
		
		.data_index(w_data_index),
		.data_pending(data_pending)
	);
	
	// generation of reset pulse for data collector with at least one clock_data cycle active
	
	wire w_rst_del;	
	wire w_latch_in;
	wire w_latch_out;
	
	assign w_latch_in = w_rst_del || rst;
	
	FDRE #(
		.INIT(1'b0)
	) FDRE_inst_delay_rst (
		.Q(w_rst_del), // 1-bit Data output
		.C(clk_system), // 1-bit Clock input
		.CE(1), // 1-bit Clock enable input
		.R(0), // 1-bit Synchronous reset input
		.D(rst) // 1-bit Data input
	);
	
	LDCE #(
		.INIT(1'b0) // Initial value of latch (1'b0 or 1'b1)
	) LDCE_inst_rst_data (
		.Q(w_latch_out), // Data output
		.CLR(w_reset_data), // Asynchronous clear/reset input
		.D(w_latch_in), // Data input
		.G(rst), // Gate input
		.GE(1) // Gate enable input
	);

	FDRE #(
		.INIT(1'b0) // Initial value of register (1'b0 or 1'b1)
	) FDRE_inst_clr_1 (
		.Q(w_reset_data), // 1-bit Data output
		.C(clk_data), // 1-bit Clock input
		.CE(1), // 1-bit Clock enable input
		.R(0), // 1-bit Synchronous reset input
		.D(w_latch_out) // 1-bit Data input
	);

		
	
endmodule
