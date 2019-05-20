`timescale 1ns / 1ps

module ro4 (
	input wire enable, 
	output wire out
);
		
		(* dont_touch = "yes" *) wire [3:0] ro4_con;
		assign out = ro4_con[0];
		
	`ifdef RO_SIM
		reg delay = 0;
		// integer rand_delay = $urandom() % 10; 
		// always #(0.124 * 4 + rand_delay) delay = enable ? ~delay : 0;
		always #(0.124 * 4) delay = enable ? ~delay : 0;
		assign ro4_con[0] = delay;
		assign ro4_con[1] = 0;
		assign ro4_con[2] = 0;
		assign ro4_con[3] = 0;
	`else
		(* dont_touch = "yes" *) LUT6 #(.INIT(64'hBBBBBBBBAAAAAAAA)) ro4LUT6_D (.O(ro4_con[3]),.I5(ro4_con[1]),.I4(0),.I3(0),.I2(0),.I1(enable),.I0(ro4_con[0])); // non-inverted feedback
		(* dont_touch = "yes" *) LUT6 #(.INIT(64'h0000FFFF0000FFFF)) ro4LUT6_C (.O(ro4_con[2]),.I5(0),.I4(ro4_con[3]),.I3(0),.I2(0),.I1(0),.I0(0));
		(* dont_touch = "yes" *) LUT6 #(.INIT(64'h00000000FFFFFFFF)) ro4LUT6_B (.O(ro4_con[1]),.I5(ro4_con[2]),.I4(0),.I3(0),.I2(0),.I1(0),.I0(0));
		(* dont_touch = "yes" *) LUT6 #(.INIT(64'h00FF00FF00FF00FF)) ro4LUT6_A (.O(ro4_con[0]),.I5(0),.I4(0),.I3(ro4_con[1]),.I2(0),.I1(0),.I0(0));
	`endif
	
endmodule
