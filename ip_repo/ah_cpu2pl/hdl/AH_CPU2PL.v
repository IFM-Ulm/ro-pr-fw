`include "portarray_pack_unpack.vh"
`include "repeat_assign_output.vh"
`include "repeat_assign_input.vh"

module AH_CPU2PL #(

		parameter integer USED_INPUTS	= 0,
		parameter integer USED_OUTPUTS	= 0,
		parameter integer IRQ_ENABLED = 0,
		parameter integer IRQ_ADVANCED = 0,
		parameter integer CLOCKING_ADVANCED = 0,
		parameter integer INTR_OUTPUT_ENABLED = 0,
		parameter integer SERIALIZE_OUTPUT_ENABLED = 0,
		parameter integer SERIALIZE_INPUT_ENABLED = 0,

		// Parameters of Axi Slave Bus Interface S_AXI_WRITE
		parameter integer C_S_AXI_WRITE_DATA_WIDTH	= 32,
		parameter integer C_S_AXI_WRITE_ADDR_WIDTH	= 7,

		// Parameters of Axi Slave Bus Interface S_AXI_READ
		parameter integer C_S_AXI_READ_DATA_WIDTH	= 32,
		parameter integer C_S_AXI_READ_ADDR_WIDTH	= 7,

		// Parameters of Axi Slave Bus Interface S_AXI_INTR
		parameter integer C_S_AXI_INTR_DATA_WIDTH	= 32,
		parameter integer C_S_AXI_INTR_ADDR_WIDTH	= 5,
		parameter integer C_NUM_OF_INTR	= 1,
		parameter  C_INTR_SENSITIVITY	= 32'hFFFFFFFF,
		parameter  C_INTR_ACTIVE_STATE	= 32'hFFFFFFFF,
		parameter integer C_IRQ_SENSITIVITY	= 1,
		parameter integer C_IRQ_ACTIVE_STATE	= 1
)(
		// Ports of Axi Slave Bus Interface S_AXI_WRITE
		input wire  s_axi_write_aclk,
		input wire  s_axi_write_aresetn,
		input wire [C_S_AXI_WRITE_ADDR_WIDTH-1 : 0] s_axi_write_awaddr,
		input wire [2 : 0] s_axi_write_awprot,
		input wire  s_axi_write_awvalid,
		output wire  s_axi_write_awready,
		input wire [C_S_AXI_WRITE_DATA_WIDTH-1 : 0] s_axi_write_wdata,
		input wire [(C_S_AXI_WRITE_DATA_WIDTH/8)-1 : 0] s_axi_write_wstrb,
		input wire  s_axi_write_wvalid,
		output wire  s_axi_write_wready,
		output wire [1 : 0] s_axi_write_bresp,
		output wire  s_axi_write_bvalid,
		input wire  s_axi_write_bready,
		input wire [C_S_AXI_WRITE_ADDR_WIDTH-1 : 0] s_axi_write_araddr,
		input wire [2 : 0] s_axi_write_arprot,
		input wire  s_axi_write_arvalid,
		output wire  s_axi_write_arready,
		output wire [C_S_AXI_WRITE_DATA_WIDTH-1 : 0] s_axi_write_rdata,
		output wire [1 : 0] s_axi_write_rresp,
		output wire  s_axi_write_rvalid,
		input wire  s_axi_write_rready,

		// Ports of Axi Slave Bus Interface S_AXI_READ
		input wire  s_axi_read_aclk,
		input wire  s_axi_read_aresetn,
		input wire [C_S_AXI_READ_ADDR_WIDTH-1 : 0] s_axi_read_awaddr,
		input wire [2 : 0] s_axi_read_awprot,
		input wire  s_axi_read_awvalid,
		output wire  s_axi_read_awready,
		input wire [C_S_AXI_READ_DATA_WIDTH-1 : 0] s_axi_read_wdata,
		input wire [(C_S_AXI_READ_DATA_WIDTH/8)-1 : 0] s_axi_read_wstrb,
		input wire  s_axi_read_wvalid,
		output wire  s_axi_read_wready,
		output wire [1 : 0] s_axi_read_bresp,
		output wire  s_axi_read_bvalid,
		input wire  s_axi_read_bready,
		input wire [C_S_AXI_READ_ADDR_WIDTH-1 : 0] s_axi_read_araddr,
		input wire [2 : 0] s_axi_read_arprot,
		input wire  s_axi_read_arvalid,
		output wire  s_axi_read_arready,
		output wire [C_S_AXI_READ_DATA_WIDTH-1 : 0] s_axi_read_rdata,
		output wire [1 : 0] s_axi_read_rresp,
		output wire  s_axi_read_rvalid,
		input wire  s_axi_read_rready,

		// Ports of Axi Slave Bus Interface S_AXI_INTR
		input wire  s_axi_intr_aclk,
		input wire  s_axi_intr_aresetn,
		input wire [C_S_AXI_INTR_ADDR_WIDTH-1 : 0] s_axi_intr_awaddr,
		input wire [2 : 0] s_axi_intr_awprot,
		input wire  s_axi_intr_awvalid,
		output wire  s_axi_intr_awready,
		input wire [C_S_AXI_INTR_DATA_WIDTH-1 : 0] s_axi_intr_wdata,
		input wire [(C_S_AXI_INTR_DATA_WIDTH/8)-1 : 0] s_axi_intr_wstrb,
		input wire  s_axi_intr_wvalid,
		output wire  s_axi_intr_wready,
		output wire [1 : 0] s_axi_intr_bresp,
		output wire  s_axi_intr_bvalid,
		input wire  s_axi_intr_bready,
		input wire [C_S_AXI_INTR_ADDR_WIDTH-1 : 0] s_axi_intr_araddr,
		input wire [2 : 0] s_axi_intr_arprot,
		input wire  s_axi_intr_arvalid,
		output wire  s_axi_intr_arready,
		output wire [C_S_AXI_INTR_DATA_WIDTH-1 : 0] s_axi_intr_rdata,
		output wire [1 : 0] s_axi_intr_rresp,
		output wire  s_axi_intr_rvalid,
		input wire  s_axi_intr_rready,
		output wire  irq,
		
		
		// User ports
		input wire clock_pl,
		input wire [C_S_AXI_READ_DATA_WIDTH-1:0] input_0,
		input wire [C_S_AXI_READ_DATA_WIDTH-1:0] input_1,
		input wire [C_S_AXI_READ_DATA_WIDTH-1:0] input_2,
		input wire [C_S_AXI_READ_DATA_WIDTH-1:0] input_3,
		input wire [C_S_AXI_READ_DATA_WIDTH-1:0] input_4,
		input wire [C_S_AXI_READ_DATA_WIDTH-1:0] input_5,
		input wire [C_S_AXI_READ_DATA_WIDTH-1:0] input_6,
		input wire [C_S_AXI_READ_DATA_WIDTH-1:0] input_7,
		input wire [C_S_AXI_READ_DATA_WIDTH-1:0] input_8,
		input wire [C_S_AXI_READ_DATA_WIDTH-1:0] input_9,
		input wire [C_S_AXI_READ_DATA_WIDTH-1:0] input_10,
		input wire [C_S_AXI_READ_DATA_WIDTH-1:0] input_11,
		input wire [C_S_AXI_READ_DATA_WIDTH-1:0] input_12,
		input wire [C_S_AXI_READ_DATA_WIDTH-1:0] input_13,
		input wire [C_S_AXI_READ_DATA_WIDTH-1:0] input_14,
		input wire [C_S_AXI_READ_DATA_WIDTH-1:0] input_15,
		input wire [C_S_AXI_READ_DATA_WIDTH-1:0] input_16,
		input wire [C_S_AXI_READ_DATA_WIDTH-1:0] input_17,
		input wire [C_S_AXI_READ_DATA_WIDTH-1:0] input_18,
		input wire [C_S_AXI_READ_DATA_WIDTH-1:0] input_19,
		input wire [C_S_AXI_READ_DATA_WIDTH-1:0] input_20,
		input wire [C_S_AXI_READ_DATA_WIDTH-1:0] input_21,
		input wire [C_S_AXI_READ_DATA_WIDTH-1:0] input_22,
		input wire [C_S_AXI_READ_DATA_WIDTH-1:0] input_23,
		input wire [C_S_AXI_READ_DATA_WIDTH-1:0] input_24,
		input wire [C_S_AXI_READ_DATA_WIDTH-1:0] input_25,
		input wire [C_S_AXI_READ_DATA_WIDTH-1:0] input_26,
		input wire [C_S_AXI_READ_DATA_WIDTH-1:0] input_27,
		input wire [C_S_AXI_READ_DATA_WIDTH-1:0] input_28,
		input wire [C_S_AXI_READ_DATA_WIDTH-1:0] input_29,
		input wire [C_S_AXI_READ_DATA_WIDTH-1:0] input_30,
		input wire [C_S_AXI_READ_DATA_WIDTH-1:0] input_31,
		input wire [USED_INPUTS*(C_S_AXI_READ_DATA_WIDTH)-1:0] inputs_serial,
		
		
		output wire [C_S_AXI_WRITE_DATA_WIDTH-1:0] output_0,
		output wire [C_S_AXI_WRITE_DATA_WIDTH-1:0] output_1,
		output wire [C_S_AXI_WRITE_DATA_WIDTH-1:0] output_2,
		output wire [C_S_AXI_WRITE_DATA_WIDTH-1:0] output_3,
		output wire [C_S_AXI_WRITE_DATA_WIDTH-1:0] output_4,
		output wire [C_S_AXI_WRITE_DATA_WIDTH-1:0] output_5,
		output wire [C_S_AXI_WRITE_DATA_WIDTH-1:0] output_6,
		output wire [C_S_AXI_WRITE_DATA_WIDTH-1:0] output_7,
		output wire [C_S_AXI_WRITE_DATA_WIDTH-1:0] output_8,
		output wire [C_S_AXI_WRITE_DATA_WIDTH-1:0] output_9,
		output wire [C_S_AXI_WRITE_DATA_WIDTH-1:0] output_10,
		output wire [C_S_AXI_WRITE_DATA_WIDTH-1:0] output_11,
		output wire [C_S_AXI_WRITE_DATA_WIDTH-1:0] output_12,
		output wire [C_S_AXI_WRITE_DATA_WIDTH-1:0] output_13,
		output wire [C_S_AXI_WRITE_DATA_WIDTH-1:0] output_14,
		output wire [C_S_AXI_WRITE_DATA_WIDTH-1:0] output_15,
		output wire [C_S_AXI_WRITE_DATA_WIDTH-1:0] output_16,
		output wire [C_S_AXI_WRITE_DATA_WIDTH-1:0] output_17,
		output wire [C_S_AXI_WRITE_DATA_WIDTH-1:0] output_18,
		output wire [C_S_AXI_WRITE_DATA_WIDTH-1:0] output_19,
		output wire [C_S_AXI_WRITE_DATA_WIDTH-1:0] output_20,
		output wire [C_S_AXI_WRITE_DATA_WIDTH-1:0] output_21,
		output wire [C_S_AXI_WRITE_DATA_WIDTH-1:0] output_22,
		output wire [C_S_AXI_WRITE_DATA_WIDTH-1:0] output_23,
		output wire [C_S_AXI_WRITE_DATA_WIDTH-1:0] output_24,
		output wire [C_S_AXI_WRITE_DATA_WIDTH-1:0] output_25,
		output wire [C_S_AXI_WRITE_DATA_WIDTH-1:0] output_26,
		output wire [C_S_AXI_WRITE_DATA_WIDTH-1:0] output_27,
		output wire [C_S_AXI_WRITE_DATA_WIDTH-1:0] output_28,
		output wire [C_S_AXI_WRITE_DATA_WIDTH-1:0] output_29,
		output wire [C_S_AXI_WRITE_DATA_WIDTH-1:0] output_30,
		output wire [C_S_AXI_WRITE_DATA_WIDTH-1:0] output_31,
		output wire [USED_OUTPUTS*(C_S_AXI_WRITE_DATA_WIDTH)-1:0] outputs_serial,
		
		output wire [USED_OUTPUTS-1:0] intr_output,
		input wire [USED_INPUTS-1:0] intr_input,
		output wire [USED_INPUTS-1:0] intr_ack,
		output wire [USED_INPUTS-1:0] read_ack
		
);
	
localparam  int_INTR_SENSITIVITY	= IRQ_ADVANCED > 0 ? C_INTR_SENSITIVITY : 32'h0;
localparam  int_INTR_ACTIVE_STATE	= IRQ_ADVANCED > 0 ? C_INTR_ACTIVE_STATE : 32'hFFFFFFFF;

wire [C_S_AXI_WRITE_DATA_WIDTH-1:0] w_output [0:`MAX_PORTS_OUTPUT-1];	
wire [C_S_AXI_WRITE_DATA_WIDTH * USED_OUTPUTS - 1 : 0] w_output_write;	
`UNPACK_PORTARRAY(C_S_AXI_WRITE_DATA_WIDTH, USED_OUTPUTS, w_output, w_output_write)

genvar gv;
generate
	if(SERIALIZE_OUTPUT_ENABLED > 0) begin
		for(gv = 0; gv < USED_OUTPUTS; gv = gv + 1) begin: generate_concatenated_outputs
			assign outputs_serial[(gv * C_S_AXI_WRITE_DATA_WIDTH)+(C_S_AXI_WRITE_DATA_WIDTH-1) : (gv * C_S_AXI_WRITE_DATA_WIDTH)] = w_output[gv];
		end
	end
	else begin
		// iterative assign: assign output_00 = w_output[0]; assign output_01 = w_output[1]; ...
		`OUTPUT_REPEAT_ASSIGN(`MAX_PORTS_OUTPUT)
	end
endgenerate


wire [C_S_AXI_READ_DATA_WIDTH-1:0] w_input  [0:`MAX_PORTS_INPUT-1];
wire [C_S_AXI_READ_DATA_WIDTH * USED_INPUTS - 1 : 0] w_input_read;	
`UNPACK_PORTARRAY(C_S_AXI_READ_DATA_WIDTH, USED_INPUTS, w_input, w_input_read)

generate
	if(SERIALIZE_INPUT_ENABLED > 0) begin
		for(gv = 0; gv < USED_INPUTS; gv = gv + 1) begin: generate_concatenated_inputs
			assign w_input[gv] = inputs_serial[(gv * C_S_AXI_WRITE_DATA_WIDTH)+(C_S_AXI_WRITE_DATA_WIDTH-1) : (gv * C_S_AXI_WRITE_DATA_WIDTH)];
		end
	end
	else begin
		// iterative assign: assign output_00 = w_output[0]; assign output_01 = w_output[1]; ...
		`INPUT_REPEAT_ASSIGN(`MAX_PORTS_INPUT)
	end
endgenerate
	
	

wire [USED_INPUTS-1:0] w_intr_input;
genvar gP;
generate
	if(CLOCKING_ADVANCED > 0) begin
		for(gP = 0; gP < USED_INPUTS; gP = gP + 1) begin : gp_intr_input
			genPulse_parameterized #(.pulseWidth(1)) genPulse_intr_input (
				.clk_ref(clock_pl),
				.clk_gen(s_axi_intr_aclk),
				.reset(!s_axi_intr_aresetn),
				.sigIn(intr_input[gP]),
				.sigOut(w_intr_input[gP]),
				.busy()
			);
		end
	end
	else begin
		assign w_intr_input = intr_input;
	end
endgenerate

wire [USED_OUTPUTS-1:0] w_intr_output;
wire [USED_OUTPUTS-1:0] w_genPulse_intr_output_busy;
wire w_writeready_intr_busy;
generate
	if(CLOCKING_ADVANCED > 0) begin
		for(gP = 0; gP < USED_OUTPUTS; gP = gP + 1) begin : gp_intr_output
			genPulse_parameterized #(.pulseWidth(1)) genPulse_intr_output (
				.clk_ref(s_axi_intr_aclk),
				.clk_gen(clock_pl),
				.reset(!s_axi_intr_aresetn),
				.sigIn(w_intr_output[gP]),
				.sigOut(intr_output[gP]),
				.busy(w_genPulse_intr_output_busy[gP])
			);
		end
	end
	else begin
		assign intr_output = w_intr_output;
		assign w_genPulse_intr_output_busy = 0;
	end
endgenerate

assign w_writeready_intr_busy = INTR_OUTPUT_ENABLED > 0 ? w_genPulse_intr_output_busy > 0 : 0;

wire [USED_OUTPUTS-1:0] w_intr_ack;
wire [USED_INPUTS-1:0] w_read_ack;
generate
	if(CLOCKING_ADVANCED > 0) begin
		for(gP = 0; gP < USED_OUTPUTS; gP = gP + 1) begin : gp_intr_ack
			genPulse_parameterized #(.pulseWidth(1)) genPulse_intr_ack (
				.clk_ref(s_axi_intr_aclk),
				.clk_gen(clock_pl),
				.reset(!s_axi_intr_aresetn),
				.sigIn(w_intr_ack[gP]),
				.sigOut(intr_ack[gP]),
				.busy()
			);
		end
	end
	else begin
		assign intr_ack = w_intr_ack;
		assign read_ack = w_read_ack;
	end
endgenerate
		

// Instantiation of Axi Bus Interface S_AXI_WRITE
AH_CPU2PL_S_AXI_WRITE # ( 
	.C_S_AXI_DATA_WIDTH(C_S_AXI_WRITE_DATA_WIDTH),
	.C_S_AXI_ADDR_WIDTH(C_S_AXI_WRITE_ADDR_WIDTH),
	.USED_OUTPUTS(USED_OUTPUTS)
) AH_CPU2PL_S_AXI_WRITE_inst (
	.S_AXI_ACLK(s_axi_write_aclk),
	.S_AXI_ARESETN(s_axi_write_aresetn),
	.S_AXI_AWADDR(s_axi_write_awaddr),
	.S_AXI_AWPROT(s_axi_write_awprot),
	.S_AXI_AWVALID(s_axi_write_awvalid),
	.S_AXI_AWREADY(s_axi_write_awready),
	.S_AXI_WDATA(s_axi_write_wdata),
	.S_AXI_WSTRB(s_axi_write_wstrb),
	.S_AXI_WVALID(s_axi_write_wvalid),
	.S_AXI_WREADY(s_axi_write_wready),
	.S_AXI_BRESP(s_axi_write_bresp),
	.S_AXI_BVALID(s_axi_write_bvalid),
	.S_AXI_BREADY(s_axi_write_bready),
	.S_AXI_ARADDR(s_axi_write_araddr),
	.S_AXI_ARPROT(s_axi_write_arprot),
	.S_AXI_ARVALID(s_axi_write_arvalid),
	.S_AXI_ARREADY(s_axi_write_arready),
	.S_AXI_RDATA(s_axi_write_rdata),
	.S_AXI_RRESP(s_axi_write_rresp),
	.S_AXI_RVALID(s_axi_write_rvalid),
	.S_AXI_RREADY(s_axi_write_rready),
	.output_write(w_output_write),
	.intr_output(w_intr_output),
	.intr_busy(w_writeready_intr_busy)
);

// Instantiation of Axi Bus Interface S_AXI_READ
AH_CPU2PL_S_AXI_READ # ( 
	.C_S_AXI_DATA_WIDTH(C_S_AXI_READ_DATA_WIDTH),
	.C_S_AXI_ADDR_WIDTH(C_S_AXI_READ_ADDR_WIDTH),
	.USED_INPUTS(USED_INPUTS)
) AH_CPU2PL_S_AXI_READ_inst (
	.S_AXI_ACLK(s_axi_read_aclk),
	.S_AXI_ARESETN(s_axi_read_aresetn),
	.S_AXI_AWADDR(s_axi_read_awaddr),
	.S_AXI_AWPROT(s_axi_read_awprot),
	.S_AXI_AWVALID(s_axi_read_awvalid),
	.S_AXI_AWREADY(s_axi_read_awready),
	.S_AXI_WDATA(s_axi_read_wdata),
	.S_AXI_WSTRB(s_axi_read_wstrb),
	.S_AXI_WVALID(s_axi_read_wvalid),
	.S_AXI_WREADY(s_axi_read_wready),
	.S_AXI_BRESP(s_axi_read_bresp),
	.S_AXI_BVALID(s_axi_read_bvalid),
	.S_AXI_BREADY(s_axi_read_bready),
	.S_AXI_ARADDR(s_axi_read_araddr),
	.S_AXI_ARPROT(s_axi_read_arprot),
	.S_AXI_ARVALID(s_axi_read_arvalid),
	.S_AXI_ARREADY(s_axi_read_arready),
	.S_AXI_RDATA(s_axi_read_rdata),
	.S_AXI_RRESP(s_axi_read_rresp),
	.S_AXI_RVALID(s_axi_read_rvalid),
	.S_AXI_RREADY(s_axi_read_rready),
	.input_read(w_input_read),
	.read_ack(w_read_ack)
);

// Instantiation of Axi Bus Interface S_AXI_INTR
AH_CPU2PL_S_AXI_INTR # ( 
	.C_S_AXI_DATA_WIDTH(C_S_AXI_INTR_DATA_WIDTH),
	.C_S_AXI_ADDR_WIDTH(C_S_AXI_INTR_ADDR_WIDTH),
	//.C_NUM_OF_INTR(C_NUM_OF_INTR),
	.C_NUM_OF_INTR(USED_INPUTS),
	//.C_INTR_SENSITIVITY(C_INTR_SENSITIVITY),
	.C_INTR_SENSITIVITY(int_INTR_SENSITIVITY),
	//.C_INTR_ACTIVE_STATE(C_INTR_ACTIVE_STATE),
	.C_INTR_ACTIVE_STATE(int_INTR_ACTIVE_STATE),
	.C_IRQ_SENSITIVITY(C_IRQ_SENSITIVITY),
	.C_IRQ_ACTIVE_STATE(C_IRQ_ACTIVE_STATE)
) AH_CPU2PL_S_AXI_INTR_inst (
	.S_AXI_ACLK(s_axi_intr_aclk),
	.S_AXI_ARESETN(s_axi_intr_aresetn),
	.S_AXI_AWADDR(s_axi_intr_awaddr),
	.S_AXI_AWPROT(s_axi_intr_awprot),
	.S_AXI_AWVALID(s_axi_intr_awvalid),
	.S_AXI_AWREADY(s_axi_intr_awready),
	.S_AXI_WDATA(s_axi_intr_wdata),
	.S_AXI_WSTRB(s_axi_intr_wstrb),
	.S_AXI_WVALID(s_axi_intr_wvalid),
	.S_AXI_WREADY(s_axi_intr_wready),
	.S_AXI_BRESP(s_axi_intr_bresp),
	.S_AXI_BVALID(s_axi_intr_bvalid),
	.S_AXI_BREADY(s_axi_intr_bready),
	.S_AXI_ARADDR(s_axi_intr_araddr),
	.S_AXI_ARPROT(s_axi_intr_arprot),
	.S_AXI_ARVALID(s_axi_intr_arvalid),
	.S_AXI_ARREADY(s_axi_intr_arready),
	.S_AXI_RDATA(s_axi_intr_rdata),
	.S_AXI_RRESP(s_axi_intr_rresp),
	.S_AXI_RVALID(s_axi_intr_rvalid),
	.S_AXI_RREADY(s_axi_intr_rready),
	.intr_input(w_intr_input),
	.intr_ack(w_intr_ack),
	.irq(irq)
);

endmodule
