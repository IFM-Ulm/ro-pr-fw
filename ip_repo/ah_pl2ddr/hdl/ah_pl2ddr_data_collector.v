
module ah_pl2ddr_data_collector #(
		parameter DATA_WIDTH = 1
	)(
	
	input wire clk,
	input wire rst,	
	input wire [DATA_WIDTH-1:0] data_in,
	input wire data_en,
	input wire [31:0] undersampling,
	input wire fill_data,
	
	output wire [31:0] data_out,
	output wire data_valid,
	output wire [31:0] data_index, // number of samples collected, not index
	output wire [5:0] data_pending
);

	reg [31:0] rg_data = 0;
	assign data_out = rg_data;
	
	reg rg_valid = 0;
	assign data_valid = rg_valid;
	
	reg [5:0] rg_counter = DATA_WIDTH == 32 ? 32 : 0;
	
	reg [31:0] rg_data_index = 0;
	assign data_index = rg_data_index;
	
	reg [31:0] rg_undersampling_counter = 0;
	
	wire [5:0] w_data_pending;
	assign w_data_pending = 6'd32 - rg_counter;
	assign data_pending = w_data_pending;
	
	wire enable_collecting;
	assign enable_collecting = !fill_data && data_en || fill_data && data_en && w_data_pending > 0;
	
	always @(posedge clk) begin
		if(rst == 1) begin
			rg_data <= 0;
			rg_valid <= 0;
			rg_counter <= DATA_WIDTH == 32 ? 32 : 0;
			rg_data_index <= 0;
			rg_undersampling_counter <= 0;
		end
		else begin
			if(enable_collecting) begin
			
				if(rg_undersampling_counter == undersampling) begin
				
					rg_undersampling_counter <= 0;
					rg_data_index <= rg_data_index + 1;
					
					rg_data[31:31-(DATA_WIDTH-1)] <= data_in;
					
					if(DATA_WIDTH == 32) begin
						rg_valid <= 1;
						rg_counter <= 32;
					end
					else if(rg_counter == 32) begin
						rg_data[31-(DATA_WIDTH < 32 ? DATA_WIDTH : 0):0] <= 0;
						rg_counter <= DATA_WIDTH;
						rg_valid <= 0;
					end
					else begin
						rg_counter <= rg_counter + DATA_WIDTH;
						rg_data[31-(DATA_WIDTH < 32 ? DATA_WIDTH : 0):0] <= rg_data[31:(DATA_WIDTH < 32 ? DATA_WIDTH : 0)];
						if((rg_counter + DATA_WIDTH) == 32) begin
							rg_valid <= 1;
						end
						else begin
							rg_valid <= 0;
						end
					end
					
				end
				else begin
					rg_valid <= 0;
					rg_undersampling_counter <= rg_undersampling_counter + 1;
				end
				
			end
			else begin
				rg_valid <= 0;
			end
		end
	end
	
	

endmodule
