
module ah_pl2ddr_signal_control #(
		parameter DATA_WIDTH = 1
	)(

	
	input wire enable_in,
	input wire enable_active,
	input wire enable_ovw,
	
	input wire [DATA_WIDTH-1:0] data_in,
	input wire data_overwrite,
	input wire [DATA_WIDTH-1:0] data_overwrite_value,

	output wire enable_out,
	output wire [DATA_WIDTH-1:0] data
);
	
	assign enable_out = enable_active ? enable_in || enable_ovw : enable_ovw;		

	assign data = data_overwrite ? data_overwrite_value : data_in;
		
endmodule
