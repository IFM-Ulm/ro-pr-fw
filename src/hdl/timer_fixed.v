/*
	Time counting instance
	after reset:
		- done low, started low
	on start edge:
		- done low, started high
	after counter reached:
		- done high, started high
	
	to count again, reset has to be asserted again

*/

module timer_fixed #(
        parameter tc_maxVal = 48'hFFFFFFFFFFFF
    )(
        input wire CLK,
        input wire reset,
        input wire start,
        output wire done,
		output wire counting,
        output wire [47:0] timer_count	
    );
    
	wire _started;
	wire _done;
	
	FDRE #(.INIT(1'b0)) FDRE_hold_start (.Q(_started), .C(CLK), .CE(start), .R(reset), .D(1'b1)); // latch start pulse
	FDRE #(.INIT(1'b0)) FDRE_hold_done (.Q(done), .C(CLK), .CE(_done), .R(reset), .D(1'b1)); // latch done pulse
	
	
	COUNTER_TC_MACRO #(
		.COUNT_BY(48'h00000000001),// Count by value
		.DEVICE("7SERIES"), // Target Device: "VIRTEX5", "VIRTEX6", "7SERIES"
		.DIRECTION("UP"), // Counter direction, "UP" or "DOWN"
		.RESET_UPON_TC("FALSE"), // Reset counter upon terminal count, "TRUE" or "FALSE"
		.TC_VALUE(tc_maxVal-2),// Terminal count value
		.WIDTH_DATA(48) // Counter output bus width, 1-48
	) COUNTER_TC_MACRO_inst (
		.Q(timer_count), // Counter output bus, width determined by WIDTH_DATA parameter
		.TC(_done), // 1-bit terminal count output, high = terminal count is reached
		.CLK(CLK), // 1-bit positive edge clock input
		.CE(_started), // 1-bit active high clock enable input
		.RST(reset) // 1-bit active high synchronous reset
	);
	
	LUT2 #(.INIT(4'h2)) LUT2_counting (.O(counting), .I0(_started), .I1(done)); // XOR of started and done
	
	
endmodule

