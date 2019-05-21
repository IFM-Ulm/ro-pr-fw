`include "portarray_pack_unpack.vh"

module toplevel (
	input  wire CLK125M,
	//input  wire [3:0] SW,
	//input  wire [3:0] BTN,
	//output  wire [3:0] LED,	
	
	inout wire [14:0] DDR_addr,
	inout wire [2:0] DDR_ba,
	inout wire DDR_cas_n,
	inout wire DDR_ck_n,
	inout wire DDR_ck_p,
	inout wire DDR_cke,
	inout wire DDR_cs_n,
	inout wire [3:0] DDR_dm,
	inout wire [31:0] DDR_dq,
	inout wire [3:0] DDR_dqs_n,
	inout wire [3:0] DDR_dqs_p,
	inout wire DDR_odt,
	inout wire DDR_ras_n,
	inout wire DDR_reset_n,
	inout wire DDR_we_n,
	inout wire FIXED_IO_ddr_vrn,
	inout wire FIXED_IO_ddr_vrp,
	inout wire [53:0] FIXED_IO_mio,
	inout wire FIXED_IO_ps_clk,
	inout wire FIXED_IO_ps_porb,
	inout wire FIXED_IO_ps_srstb
	//inout wire FIXED_IO_ps_srstb,
	//input wire [3:0] btns_4bits_tri_i,
    //inout wire [3:0] leds_4bits_tri_io,
    //input wire [3:0] sws_4bits_tri_i
	
);
	
	localparam lp_number_inputs = 7;
	localparam lp_number_outputs = 3;
	
	// outputs from system
	wire sys_clk0; 
	wire sys_clk1;
	wire [lp_number_inputs-1:0] sys_intr_ack;
	wire [lp_number_inputs-1:0] sys_intr_output;
	wire [lp_number_inputs*32-1:0] sys_outputs_serial;
	wire [0:0] sys_reset;
	wire [0:0] sys_resetn;
	wire sys_decouple;
	
	// inputs to system
	wire [lp_number_outputs*32-1:0] sys_inputs_serial;	
	wire [lp_number_outputs-1:0] sys_intr_input;

	ro_toplevel #(.number_inputs(lp_number_inputs), .number_outputs(lp_number_outputs)) ro_top_inst (
		.CLK(sys_clk0),
		.RESET(sys_reset),
		.DECOUPLE(sys_decouple),
		.intr_in(sys_intr_output),
		.data_in(sys_outputs_serial),
		.intr_out(sys_intr_input),
		.data_out(sys_inputs_serial),
		.SW(0),
		.BTN(0),
		.LED()
	);
	
	// block design instantiation
	system_wrapper system_wrapper_inst(
		.DDR_addr(DDR_addr),
		.DDR_ba(DDR_ba),
		.DDR_cas_n(DDR_cas_n),
		.DDR_ck_n(DDR_ck_n),
		.DDR_ck_p(DDR_ck_p),
		.DDR_cke(DDR_cke),
		.DDR_cs_n(DDR_cs_n),
		.DDR_dm(DDR_dm),
		.DDR_dq(DDR_dq),
		.DDR_dqs_n(DDR_dqs_n),
		.DDR_dqs_p(DDR_dqs_p),
		.DDR_odt(DDR_odt),
		.DDR_ras_n(DDR_ras_n),
		.DDR_reset_n(DDR_reset_n),
		.DDR_we_n(DDR_we_n),
		.FIXED_IO_ddr_vrn(FIXED_IO_ddr_vrn),
		.FIXED_IO_ddr_vrp(FIXED_IO_ddr_vrp),
		.FIXED_IO_mio(FIXED_IO_mio),
		.FIXED_IO_ps_clk(FIXED_IO_ps_clk),
		.FIXED_IO_ps_porb(FIXED_IO_ps_porb),
		.FIXED_IO_ps_srstb(FIXED_IO_ps_srstb),
		//.btns_4bits_tri_i(btns_4bits_tri_i),
        //.leds_4bits_tri_io(leds_4bits_tri_io),
        //.sws_4bits_tri_i(sws_4bits_tri_i),
		.sys_clk0(sys_clk0),
		.sys_clk1(sys_clk1),
		.sys_inputs_serial(sys_inputs_serial),
		.sys_intr_ack(sys_intr_ack),
		.sys_intr_input(sys_intr_input),
		.sys_intr_output(sys_intr_output),
		.sys_outputs_serial(sys_outputs_serial),
		.sys_reset(sys_reset),
		.sys_resetn(sys_resetn),
		.sys_decouple(sys_decouple)
	);
	

endmodule