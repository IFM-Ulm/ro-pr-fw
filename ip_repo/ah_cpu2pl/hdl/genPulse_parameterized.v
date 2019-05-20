
module genPulse_parameterized #(
	parameter pulseWidth = 1	
) (
	input wire clk_ref,
	input wire clk_gen,
	input wire reset,
	input wire sigIn,
	output wire sigOut,
	output wire busy
);
	
	wire [1:0] w_shift;
	wire latched_sigIn;
	wire shaped_sigIn;
	
	reg [1:0] state = 0;
	reg [pulseWidth-1 : 0] genPulse = 0;
	
	// pulse shape the input signal in reference to its clock	
	FDRE #(.INIT(1'b0)) pulse_shape_FDRE_0 (.Q(w_shift[0]), .C(clk_ref), .CE(1'b1), .R(reset), .D(sigIn));
	FDRE #(.INIT(1'b0)) pulse_shape_FDRE_1 (.Q(w_shift[1]), .C(clk_ref), .CE(1'b1), .R(reset), .D(w_shift[0]));
	LUT2 #(.INIT(4'b0010)) pulse_shape_LUT2 (.O(shaped_sigIn), .I0(w_shift[0]), .I1(w_shift[1]));
	
	// latch the pulse shape such that its value is held at least long enough to be recognized by the following FSM 
	//LDCE #(.INIT(1'b0)) pulse_shape_LDCE (.Q(latched_sigIn), .CLR(state[1] | state[0]), .D(1'b1), .G(shaped_sigIn), .GE(1'b1));
	LDCE #(.INIT(1'b0)) pulse_shape_LDCE (.Q(latched_sigIn), .CLR(state[1]), .D(1'b1), .G(shaped_sigIn), .GE(1'b1));
	
	assign sigOut = genPulse > 0;
	
	always @(posedge clk_gen) begin
		if(reset) begin
			state <= 0;
			genPulse <= 0;
		end
		else begin
			case(state)
				0 : begin
						if(latched_sigIn) begin
							state <= 1;
							genPulse[0] <= 1;
						end
					end
				1 : begin
						if(!genPulse[pulseWidth-1]) begin
							genPulse <= genPulse << 1;
						end
						else begin
							//state <= 2;
							state <= 0;				
							genPulse <= 0;
						end
					end
				/*2 : begin
						if(!shaped_sigIn) begin
							state <= 0;
						end
					end*/
				default : begin
						state <= 0;
						genPulse <= 0;
					end
			endcase
		end
	end
	
	assign busy = shaped_sigIn | latched_sigIn | state > 0;
	

endmodule