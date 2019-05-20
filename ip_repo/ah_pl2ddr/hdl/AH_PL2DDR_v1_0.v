
	module AH_PL2DDR_v1_0 #
	(
		parameter integer DATA_WIDTH = 1,
		
		parameter reg ENABLE_CMD_INPUT = 0,
		parameter reg ENABLE_MODE_INPUT = 0,
		parameter reg ENABLE_SAMPLES_INPUT = 0,
		parameter reg ENABLE_UNDERSAMPLES_INPUT = 0,
		parameter reg ENABLE_ADDRESS_INPUT = 0,
		parameter reg ENABLE_INTR_SENT = 0,
		parameter reg ENABLE_INTR_DONE = 0,
		parameter reg ENABLE_INTR_ERROR = 0,
		parameter reg DSP_FOR_CALC = 0,
		parameter reg ENABLE_TRANSFER_CONTROL = 0,
		
		parameter integer DEFAULT_SAMPLING_MODE = 0,
		parameter integer DEFAULT_SAMPLE_NUMBER = 0,
		parameter integer DEFAULT_UNDERSAMPLING_VALUE = 0,

		parameter integer DEFAULT_DDR_LOW = 32'h00100000,
		parameter integer DEFAULT_DDR_HIGH = 32'h03FFFFFF,
		
		// Parameters of Axi Master Bus Interface M_AXI_OUT
		parameter integer C_M_AXI_OUT_ID_WIDTH		= 1,
		parameter integer C_M_AXI_OUT_ADDR_WIDTH	= 32,
		parameter integer C_M_AXI_OUT_DATA_WIDTH	= 32,
		parameter integer C_M_AXI_OUT_AWUSER_WIDTH	= 0,
		parameter integer C_M_AXI_OUT_ARUSER_WIDTH	= 0,
		parameter integer C_M_AXI_OUT_WUSER_WIDTH	= 0,
		parameter integer C_M_AXI_OUT_RUSER_WIDTH	= 0,
		parameter integer C_M_AXI_OUT_BUSER_WIDTH	= 0
		
	)(
		
		// ToDo: re-import ports in GUI to apply correct order and to integrate ports cmd_processed and cmd_ack
		
		input wire clk_data,
		input wire [DATA_WIDTH-1 : 0] data_in,
		input wire data_en,
		input wire transfer_en,
		
		input wire [31:0] cmd_in,
		input wire cmd_en,
		
		input wire enable,
		
		input wire reset,
		input wire reset_addr,
		input wire reset_data,
		
		input wire [31:0] sampling_mode,
		input wire [31:0] number_samples,
		input wire [31:0] undersample_factor,		
		
		input wire [31:0] ddr_addr_low,
		input wire [31:0] ddr_addr_high,
		
		output wire [31:0] samples_collected,
		output wire [31:0] samples_transmitted,	
		output wire enabled,
		output wire transfer_active,
		
		// ToDo: add option in advanced to differentiate ack: either when received or when processed
		output wire [31:0] cmd_processed,
		output wire [31:0] bytes_collected,
		output wire [31:0] bytes_transmitted,
		output wire [31:0] current_ddr_addr,
		output wire [4:0] pending_collect,
		output wire [9:0] pending_transmit,
		output wire [DATA_WIDTH-1:0] last_data,
		output wire [3:0] signal_control,
		
		output wire [3:0] cmdfsm_state,
		output wire [31:0] w_debugging,
		
		output wire [7:0] status,
		
		output wire intr_sent,
		output wire intr_done,
		output wire intr_ack,
		output wire intr_error,
		
		// Ports of Axi Master Bus Interface M_AXI_OUT
		input wire  m_axi_out_aclk,
		input wire  m_axi_out_aresetn,
		output wire [C_M_AXI_OUT_ID_WIDTH-1 : 0] m_axi_out_awid,
		output wire [C_M_AXI_OUT_ADDR_WIDTH-1 : 0] m_axi_out_awaddr,
		output wire [7 : 0] m_axi_out_awlen,
		output wire [2 : 0] m_axi_out_awsize,
		output wire [1 : 0] m_axi_out_awburst,
		output wire  m_axi_out_awlock,
		output wire [3 : 0] m_axi_out_awcache,
		output wire [2 : 0] m_axi_out_awprot,
		output wire [3 : 0] m_axi_out_awqos,
		output wire [C_M_AXI_OUT_AWUSER_WIDTH-1 : 0] m_axi_out_awuser,
		output wire  m_axi_out_awvalid,
		input wire  m_axi_out_awready,
		output wire [C_M_AXI_OUT_DATA_WIDTH-1 : 0] m_axi_out_wdata,
		output wire [C_M_AXI_OUT_DATA_WIDTH/8-1 : 0] m_axi_out_wstrb,
		output wire  m_axi_out_wlast,
		output wire [C_M_AXI_OUT_WUSER_WIDTH-1 : 0] m_axi_out_wuser,
		output wire  m_axi_out_wvalid,
		input wire  m_axi_out_wready,
		input wire [C_M_AXI_OUT_ID_WIDTH-1 : 0] m_axi_out_bid,
		input wire [1 : 0] m_axi_out_bresp,
		input wire [C_M_AXI_OUT_BUSER_WIDTH-1 : 0] m_axi_out_buser,
		input wire  m_axi_out_bvalid,
		output wire  m_axi_out_bready,
		output wire [C_M_AXI_OUT_ID_WIDTH-1 : 0] m_axi_out_arid,
		output wire [C_M_AXI_OUT_ADDR_WIDTH-1 : 0] m_axi_out_araddr,
		output wire [7 : 0] m_axi_out_arlen,
		output wire [2 : 0] m_axi_out_arsize,
		output wire [1 : 0] m_axi_out_arburst,
		output wire  m_axi_out_arlock,
		output wire [3 : 0] m_axi_out_arcache,
		output wire [2 : 0] m_axi_out_arprot,
		output wire [3 : 0] m_axi_out_arqos,
		output wire [C_M_AXI_OUT_ARUSER_WIDTH-1 : 0] m_axi_out_aruser,
		output wire  m_axi_out_arvalid,
		input wire  m_axi_out_arready,
		input wire [C_M_AXI_OUT_ID_WIDTH-1 : 0] m_axi_out_rid,
		input wire [C_M_AXI_OUT_DATA_WIDTH-1 : 0] m_axi_out_rdata,
		input wire [1 : 0] m_axi_out_rresp,
		input wire  m_axi_out_rlast,
		input wire [C_M_AXI_OUT_RUSER_WIDTH-1 : 0] m_axi_out_ruser,
		input wire  m_axi_out_rvalid,
		output wire  m_axi_out_rready
	);
	
	wire [31:0] w_axi_slave_ddr_addr;
	wire [8:0] w_axi_slave_burst_len;
	wire [10:0] w_axi_slave_burst_number;
	wire w_axit_slave_tx_init;
	wire w_axi_slave_tx_done;
	
	wire w_data_next;
	wire [31:0] w_data_out;
	wire [DATA_WIDTH-1:0] w_data_in;
	wire w_data_enable;
	wire w_data_overwrite;
	wire [DATA_WIDTH-1:0] w_data_overwrite_value;
	wire [31:0] w_undersampling_value;
	
	wire [31:0] w_data_index;
	wire [5:0] w_data_pending;
	
	wire w_reset;
	assign w_reset = !m_axi_out_aresetn || reset;
	
	wire w_rst_axi;
	assign w_rst_axi = m_axi_out_aresetn && !reset;
	
	wire w_rst_data;
	wire w_reset_data;
	assign w_reset_data = w_reset || w_rst_data;
	
	wire w_enable_active;
	wire w_enable_ovw;
	wire w_testmode;
	
	wire [9:0] w_bram_addr_read;
	wire [9:0] w_bram_addr_write;
	wire [9:0] w_data_available;
	
	wire w_m_axi_error;
	wire w_data_error;
	
	wire w_transfer_en;
	assign w_transfer_en = ENABLE_TRANSFER_CONTROL > 0 ? transfer_en : 1;

	wire [31:0] w_cmd_in = ENABLE_CMD_INPUT > 0 ? cmd_in : 0;
	wire w_cmd_en = ENABLE_CMD_INPUT > 0 ? cmd_en : 0;
	wire [31:0] w_number_samples = ENABLE_SAMPLES_INPUT > 0 ? number_samples : DEFAULT_SAMPLE_NUMBER;
	wire [31:0] w_undersample_factor = (ENABLE_UNDERSAMPLES_INPUT > 0) ? undersample_factor : DEFAULT_UNDERSAMPLING_VALUE;
	wire [31:0] w_ddr_low = ENABLE_ADDRESS_INPUT > 0 ? ddr_addr_low : DEFAULT_DDR_LOW;
	wire [31:0] w_ddr_high = ENABLE_ADDRESS_INPUT > 0 ? ddr_addr_high : DEFAULT_DDR_LOW;
	wire [31:0] w_sampling_mode = ENABLE_MODE_INPUT > 0 ? sampling_mode : DEFAULT_SAMPLING_MODE;
	wire w_enable = ENABLE_CMD_INPUT > 0 ? 0 : enable;
	
	
	// ToDo: connect these wires 
	assign samples_transmitted = 0;
	assign bytes_collected = 0;
	assign bytes_transmitted = 0;
	
	assign samples_collected = w_data_index;
		
	assign pending_collect = w_data_pending;
	assign pending_transmit = w_data_available;
	
	assign enabled = w_data_enable;
	assign current_ddr_addr = w_axi_slave_ddr_addr;
	assign last_data = w_data_in;
	
	
	assign signal_control = {w_data_overwrite,w_enable_ovw,w_enable_active,data_en};

	// Instantiation of Axi Bus Interface M_AXI_OUT
	AH_PL2DDR_v1_0_M_AXI_OUT # (
		.C_M_AXI_ID_WIDTH(C_M_AXI_OUT_ID_WIDTH),
		.C_M_AXI_ADDR_WIDTH(C_M_AXI_OUT_ADDR_WIDTH),
		.C_M_AXI_DATA_WIDTH(C_M_AXI_OUT_DATA_WIDTH),
		.C_M_AXI_AWUSER_WIDTH(C_M_AXI_OUT_AWUSER_WIDTH),
		.C_M_AXI_ARUSER_WIDTH(C_M_AXI_OUT_ARUSER_WIDTH),
		.C_M_AXI_WUSER_WIDTH(C_M_AXI_OUT_WUSER_WIDTH),
		.C_M_AXI_RUSER_WIDTH(C_M_AXI_OUT_RUSER_WIDTH),
		.C_M_AXI_BUSER_WIDTH(C_M_AXI_OUT_BUSER_WIDTH)
	) inst_AH_PL2DDR_v1_0_M_AXI_OUT (
	
		.C_M_TARGET_SLAVE_BASE_ADDR(w_axi_slave_ddr_addr),
		.C_M_AXI_BURST_LEN(w_axi_slave_burst_len),
		.C_NO_BURSTS_REQ(w_axi_slave_burst_number),
		.data_in(w_data_out),
		.data_next(w_data_next),		
		
		.INIT_AXI_TXN(w_axit_slave_tx_init),
		.TXN_DONE(w_axi_slave_tx_done),
		.ERROR(w_m_axi_error),
		.M_AXI_ACLK(m_axi_out_aclk),
		.M_AXI_ARESETN(w_rst_axi),
		.M_AXI_AWID(m_axi_out_awid),
		.M_AXI_AWADDR(m_axi_out_awaddr),
		.M_AXI_AWLEN(m_axi_out_awlen),
		.M_AXI_AWSIZE(m_axi_out_awsize),
		.M_AXI_AWBURST(m_axi_out_awburst),
		.M_AXI_AWLOCK(m_axi_out_awlock),
		.M_AXI_AWCACHE(m_axi_out_awcache),
		.M_AXI_AWPROT(m_axi_out_awprot),
		.M_AXI_AWQOS(m_axi_out_awqos),
		.M_AXI_AWUSER(m_axi_out_awuser),
		.M_AXI_AWVALID(m_axi_out_awvalid),
		.M_AXI_AWREADY(m_axi_out_awready),
		.M_AXI_WDATA(m_axi_out_wdata),
		.M_AXI_WSTRB(m_axi_out_wstrb),
		.M_AXI_WLAST(m_axi_out_wlast),
		.M_AXI_WUSER(m_axi_out_wuser),
		.M_AXI_WVALID(m_axi_out_wvalid),
		.M_AXI_WREADY(m_axi_out_wready),
		.M_AXI_BID(m_axi_out_bid),
		.M_AXI_BRESP(m_axi_out_bresp),
		.M_AXI_BUSER(m_axi_out_buser),
		.M_AXI_BVALID(m_axi_out_bvalid),
		.M_AXI_BREADY(m_axi_out_bready),
		.M_AXI_ARID(m_axi_out_arid),
		.M_AXI_ARADDR(m_axi_out_araddr),
		.M_AXI_ARLEN(m_axi_out_arlen),
		.M_AXI_ARSIZE(m_axi_out_arsize),
		.M_AXI_ARBURST(m_axi_out_arburst),
		.M_AXI_ARLOCK(m_axi_out_arlock),
		.M_AXI_ARCACHE(m_axi_out_arcache),
		.M_AXI_ARPROT(m_axi_out_arprot),
		.M_AXI_ARQOS(m_axi_out_arqos),
		.M_AXI_ARUSER(m_axi_out_aruser),
		.M_AXI_ARVALID(m_axi_out_arvalid),
		.M_AXI_ARREADY(m_axi_out_arready),
		.M_AXI_RID(m_axi_out_rid),
		.M_AXI_RDATA(m_axi_out_rdata),
		.M_AXI_RRESP(m_axi_out_rresp),
		.M_AXI_RLAST(m_axi_out_rlast),
		.M_AXI_RUSER(m_axi_out_ruser),
		.M_AXI_RVALID(m_axi_out_rvalid),
		.M_AXI_RREADY(m_axi_out_rready)
	);

	
	
	ah_pl2ddr_data_control #(
		.DATA_WIDTH(DATA_WIDTH)
	) inst_data_control (
	
		.clk_data(clk_data),
		.clk_system(m_axi_out_aclk),
		.rst(w_reset_data),
	
		.data_in(w_data_in), // in
		.data_en(w_data_enable),
		.data_undersampling(w_undersampling_value),
		.testmode(w_testmode),
		.fill_data(w_fill_data),
	
		.data_next(w_data_next),
		.data_out(w_data_out),
		
		.addr_read(w_bram_addr_read),
		.addr_write(w_bram_addr_write),
	
		.data_index(w_data_index),
		.data_pending(w_data_pending),
		.data_available(w_data_available),
		
		.error(w_data_error)
		
	);

	
	
	ah_pl2ddr_signal_control #(
		.DATA_WIDTH(DATA_WIDTH)
	) inst_signal_control (
	
		.enable_in(data_en),
		.enable_active(w_enable_active),	
		.enable_ovw(w_enable_ovw),
		
		.enable_out(w_data_enable),
	
		.data_in(data_in), // in
		.data_overwrite(w_data_overwrite),
		.data_overwrite_value(w_data_overwrite_value),

		.data(w_data_in) // out
	);
	
	
	
	ah_pl2ddr_cmd_fsm #(
		.DATA_WIDTH(DATA_WIDTH),
		.DSP_FOR_CALC(DSP_FOR_CALC)
	) inst_cmd_fsm (

		.clk(m_axi_out_aclk),
		.rst(w_reset),
		
		.in_cmd_data(w_cmd_in),
		.in_cmd_en(w_cmd_en),
		.in_sampling_mode(w_sampling_mode),
		.in_number_samples(w_number_samples),
		.in_undersampling(w_undersample_factor),
		.in_ddr_addr_low(w_ddr_low),
		.in_ddr_addr_high(w_ddr_high),
		
		.in_data_index(w_data_index),
		.in_data_pending(w_data_pending),
		
		.in_enable(w_enable),
		
		.in_transfer_en(w_transfer_en),
		.out_transfer_active(transfer_active),
		
		.out_rst_data(w_rst_data),
		.out_enable_active(w_enable_active),
		.out_enable_ovw(w_enable_ovw),
		.out_testmode(w_testmode),
		.out_fill_data(w_fill_data),
		
		.out_axi_slave_ddr_addr(w_axi_slave_ddr_addr),
		.out_axi_slave_burst_len(w_axi_slave_burst_len),
		.out_axi_slave_burst_number(w_axi_slave_burst_number),
		
		.out_data_overwrite(w_data_overwrite),
		.out_data_overwrite_value(w_data_overwrite_value),
		.out_undersampling_value(w_undersampling_value),
		
		.in_axi_error(w_m_axi_error),
		.out_axit_slave_tx_init(w_axit_slave_tx_init),
		.in_axi_slave_tx_done(w_axi_slave_tx_done),
		
		.data_available(w_data_available),
		.in_bram_addr_read(w_bram_addr_read),
		.in_bram_addr_write(w_bram_addr_write),
		
		.in_data_error(w_data_error),
		
		.out_cmd_processed(cmd_processed),
		
		.out_status(status),
		.out_cmdfsm_state(cmdfsm_state),
		.out_debugging(w_debugging),
		
		.intr_sent(intr_sent),
		.intr_done(intr_done),
		.intr_error(intr_error),
		.intr_ack(intr_ack)
	
	);
	

endmodule
