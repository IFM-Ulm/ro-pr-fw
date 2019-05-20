module PR_module (
		input wire [31:0] counting,
		output wire [31:0] RO_out
);
	
	localparam number_RO = 32;
	
	// wire [number_RO-1:0] iRO_buf_out;
	// wire [number_RO-1:0] iRO_buf_in;

	//assign RO_out = iRO_buf_out;

	genvar r;
    generate
	
	for (r = 0; r < number_RO; r = r + 1) begin : RoGen

		//(* dont_touch = "yes" *) ringOsscilator #(.DELAY(0), .SIZE(5), .INITIAL_PARAM(24'o13542354)) puf1(.enable(counting[r]), .out(iRO_buf_in[r]));
		// (* dont_touch = "yes" *) ro4 puf2(.enable(counting[r]), .out(iRO_buf_in[r]));
		(* dont_touch = "yes" *) ro4 puf2(.enable(counting[r]), .out(RO_out[r]));

		//(* dont_touch = "yes" *) LUT6 #(.INIT(64'h2)) RO_buf (.O(iRO_buf_out[r]),.I5(0),.I4(0),.I3(0),.I2(0),.I1(0),.I0(iRO_buf_in[r]));

	end
	
	
	endgenerate
	
endmodule
