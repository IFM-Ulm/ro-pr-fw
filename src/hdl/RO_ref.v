
module RO_ref (
	input wire enable,
	input wire reset,
	output wire [31:0] count
);
	
	wire pr_ref_out;
	
	//(* dont_touch = "yes" *) ringOsscilator #(.DELAY(0), .SIZE(5), .INITIAL_PARAM(24'o13542354)) puf_ref (.enable(enable), .out(pr_ref_out));
	(* dont_touch = "yes" *) ro4 puf_ref(.enable(enable), .out(pr_ref_out));
	
	(* dont_touch = "yes" *) counter_fixed inst_counter_ref(.CLK(pr_ref_out), .reset(reset), .count(count));
	
	
endmodule
