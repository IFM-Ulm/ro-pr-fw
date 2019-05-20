`timescale 1ns / 1ps

module tb_AH_PL2DDR();
	
	localparam DATA_WIDTH = 32;
	
	reg tb_clk = 0;
	always #2.5 tb_clk = !tb_clk; // 100 MHz
	
	reg tb_clk_data = 0;
	always #8.333 tb_clk_data = !tb_clk_data; // 20 MHz
	// wire tb_clk_data;
	// assign tb_clk_data = tb_clk;
	
	reg tb_rstn = 1;
	initial begin
		tb_rstn = 1;
		#100 tb_rstn = 0;
		#100 tb_rstn = 1;
	end


	localparam NO_SAMPLING = 3'b000, FREE_RUNNING = 3'b001, SAMPLED = 3'b010, UNDERSAMPLED = 3'b011, MANUAL = 3'b100;
	localparam CMD_NONE = 32'h00000000, CMD_RST = 32'h00000001, CMD_RST_ADDR = 32'h00000002, CMD_RST_DATA = 32'h00000004, CMD_DISABLE = 32'h00000020, CMD_ENABLE = 32'h00000021, 
				CMD_TRIGGER_TX = 32'h00000100, CMD_FORCE_TX = 32'h00000101, CMD_TRIGGER_SAMPLE = 32'h00000102, CMD_TRIGGER_FILLDATA = 32'h00000104, 
				CMD_INTR_ONSENT_DISABLE = 32'h00001010, CMD_INTR_ONSENT_ENABLE = 32'h00001011, CMD_INTR_ONDONE_DISABLE = 32'h00001020, CMD_INTR_ONDONE_ENABLE = 32'h00001021,
				CMD_INTR_ONERROR_DISABLE = 32'h00001040, CMD_INTR_ONERROR_ENABLE = 32'h00001041, CMD_INTR_ONACK_DISABLE = 32'h00001080, CMD_INTR_ONACK_ENABLE = 32'h00001081, 
				CMD_TESTMODE_DISABLE = 32'h00010000, CMD_TESTMODE_ENABLE = 32'h00010001;
	
	reg tb_enable = 0;
	
	reg tb_reset = 0;
	reg tb_reset_addr = 0;
	reg tb_reset_data = 0;
	
	wire [31:0] tb_cmd_processed;
	wire [31:0] tb_samples_collected;
	wire [31:0] tb_samples_transmitted;
	wire [31:0] tb_bytes_collected;
	wire [31:0] tb_bytes_transmitted;
	wire [31:0] tb_current_ddr_addr;
	wire tb_transfer_active;

	wire tb_enabled;
	wire [4:0] tb_pending_collect;
	wire [9:0] tb_pending_transmit;
	wire [DATA_WIDTH-1:0] tb_last_data;
	
	wire [7:0] tb_status;
	
	reg [31:0] tb_cmd_in = 0;
	reg tb_cmd_en = 0;
	initial begin
		tb_cmd_in = 0;
		tb_cmd_en = 0;
		
		#100 tb_cmd_in = CMD_RST; tb_cmd_en = 1;
		#20 tb_cmd_en = 0;

		#20 tb_cmd_in = CMD_INTR_ONACK_ENABLE; tb_cmd_en = 1;
		#20 tb_cmd_en = 0;
		
		#20 tb_cmd_in = CMD_INTR_ONERROR_ENABLE; tb_cmd_en = 1;
		#20 tb_cmd_en = 0;
		
		#20 tb_cmd_in = CMD_RST_DATA; tb_cmd_en = 1;
        #20 tb_cmd_en = 0;
        
        #20 tb_cmd_in = CMD_RST_ADDR; tb_cmd_en = 1;
        #20 tb_cmd_en = 0;
		
		#20 tb_cmd_in = CMD_INTR_ONDONE_ENABLE; tb_cmd_en = 1;
		#20 tb_cmd_en = 0;
				
		#20 tb_cmd_in = CMD_ENABLE; tb_cmd_en = 1;
		#20 tb_cmd_en = 0;
		
		#400000 tb_cmd_in = CMD_DISABLE; tb_cmd_en = 1;
		#20 tb_cmd_en = 0;
		
		#100 tb_cmd_in = CMD_RST; tb_cmd_en = 1;
		#20 tb_cmd_en = 0;
		
		#20 tb_cmd_in = CMD_INTR_ONDONE_ENABLE; tb_cmd_en = 1;
		#20 tb_cmd_en = 0;
		
		#400000 tb_cmd_in = CMD_ENABLE; tb_cmd_en = 1;
		#20 tb_cmd_en = 0;
		
	end
	
	reg [31:0] tb_number_samples = 0;
	initial begin
		tb_number_samples = 0;
		#100 tb_number_samples = 4096;
	end
		
	reg [31:0] tb_undersample_factor = 0;
	initial begin
		tb_undersample_factor = 0;
	end
	
	reg [31:0] tb_ddr_addr_low = 0;
	initial begin
		tb_ddr_addr_low = 0;
		#100 tb_ddr_addr_low = 32'h01000000;
	end
	
	reg [31:0] tb_ddr_addr_high = 0;
	initial begin
		tb_ddr_addr_high = 0;
		#100 tb_ddr_addr_high = 32'h1FFFFFFF;
	end
	
	reg [31:0] tb_sampling_mode;
	initial begin
		tb_sampling_mode = 0;
		#100 tb_sampling_mode = SAMPLED;
	end
	
	reg tb_transfer_en = 1;
	//initial begin
		//tb_transfer_en <= 0;
		//#21000 tb_transfer_en <= 1;
	//end
	
	reg [DATA_WIDTH-1 : 0] tb_data_in = 0;
	// wire tb_data_en;
	reg tb_data_en;
	initial begin
		tb_data_en = 0;
		#500 tb_data_en <= 1;
	end
	
	//assign tb_data_en = 1;
	reg [2:0] tb_data_in_counter = 0;
	reg [2:0] tb_data_in_temp = 0;
	
	always @(posedge tb_clk_data) begin
		if(tb_rstn == 0) begin
			tb_data_in <= 0;
			tb_data_in_counter <= 0;
			tb_data_in_temp <= 1;
		end
		else begin
			if(tb_data_en) begin
				if(tb_data_in_counter == 0) begin
					tb_data_in <= tb_data_in_temp;
					tb_data_in_temp <= tb_data_in_temp + 1;
					tb_data_in_counter <= 0;
				end
				else begin
					tb_data_in <= 0;
					tb_data_in_counter <= tb_data_in_counter + 1;
				end
			end
		end
	end
	
	

	// AXI4 stuff	
	wire [32-1 : 0] tb_m_axi_out_awaddr;
	wire [7 : 0] tb_m_axi_out_awlen;

	wire  tb_m_axi_out_awvalid;
	reg  tb_axi_out_awready;
	wire [32-1 : 0] tb_m_axi_out_wdata;

	wire  tb_m_axi_out_wlast;

	wire  tb_m_axi_out_wvalid;
	reg  tb_m_axi_out_wready;

	reg [1 : 0] tb_m_axi_out_bresp;

	reg  tb_m_axi_out_bvalid;
	wire tb_m_axi_out_bready;

	localparam IDLE = 4'b0000, WAIT_AWVALID = 4'b0001, WAIT_WVALID = 4'b0010, WAIT_WLAST = 4'b0011, WAIT_BREADY = 4'b0100;
	reg [3:0] state = IDLE;
	
	reg tb_compare_valid = 1;
	wire tb_compare_comparing;
	assign tb_compare_comparing = state == WAIT_WLAST;
	reg [31:0] tb_compare_ref = 0;
	wire [32-1 : 0] tb_compare_sent;
	assign tb_compare_sent = tb_m_axi_out_wdata;
	
	wire tb_intr_sent;
	wire tb_intr_done;
	wire tb_intr_ack;
	wire tb_intr_error;
	
	
	always @(posedge tb_clk) begin
		if(tb_rstn == 0) begin
			state <= IDLE;
			tb_axi_out_awready <= 0;
			tb_m_axi_out_wready <= 0;
			tb_m_axi_out_bresp <= 0;
			tb_m_axi_out_bvalid <= 0;
		end
		else begin
			case (state)
				IDLE : begin
					state <= WAIT_AWVALID;
					tb_axi_out_awready <= 0;
					tb_m_axi_out_wready <= 0;
					tb_m_axi_out_bresp <= 0;
					tb_m_axi_out_bvalid <= 0;
				end
				WAIT_AWVALID : begin
					if(tb_m_axi_out_awvalid == 1) begin
						tb_axi_out_awready <= 1;
						state <= WAIT_WVALID;
					end
					else begin
						state <= WAIT_AWVALID;
					end
				end
				WAIT_WVALID : begin
					tb_axi_out_awready <= 0;
					if(tb_m_axi_out_wvalid == 1) begin
						tb_m_axi_out_wready <= 1;
						state <= WAIT_WLAST;
					end
					else begin
						state <= WAIT_WVALID;
					end
				end
				WAIT_WLAST : begin
					
					if(tb_m_axi_out_wlast == 1) begin
						tb_m_axi_out_wready <= 0;
						tb_m_axi_out_bresp <= 0;
						tb_m_axi_out_bvalid <= 1;
						state <= WAIT_BREADY;
					end
					else begin
						state <= WAIT_WLAST;
					end
				end
				WAIT_BREADY : begin
					if(tb_m_axi_out_bready == 1) begin
						tb_m_axi_out_bresp <= 0;
						tb_m_axi_out_bvalid <= 0;
						state <= IDLE;
					end
					else begin
						tb_m_axi_out_bresp <= 0;
						tb_m_axi_out_bvalid <= 1;
						state <= WAIT_BREADY;
					end
				end
				
			endcase
		end
	end
	
	always @(posedge tb_clk) begin
		if(tb_rstn == 0) begin
			tb_compare_ref <= 0;
			tb_compare_valid <= 1;
		end
		else begin
			if(state == WAIT_WLAST) begin
				if(tb_compare_ref == 7) begin
					tb_compare_ref <= 0;
				end
				else begin
					tb_compare_ref <= tb_compare_ref + 1;
				end
				tb_compare_valid <= tb_compare_valid && (tb_m_axi_out_wdata == tb_compare_ref);
			end
		end
	end
	
	
		/*
		M_AXI_AWVALID = 1 -> M_AXI_AWREADY = 1 (1 pulse)
		M_AXI_WVALID = 1 -> M_AXI_WREADY = 1, zähle anzahl daten für WVALID = 1
		M_AXI_WLAST = 1 -> M_AXI_WREADY = 0, M_AXI_BRESP[1] = 0, M_AXI_BVALID = 1
		M_AXI_BREADY = 1 ->  M_AXI_BRESP[1] = 0, M_AXI_BVALID = 0
	*/
	
	AH_PL2DDR_v1_0 #(
		.DATA_WIDTH(DATA_WIDTH),
		.ENABLE_CMD_INPUT(1),
		.ENABLE_MODE_INPUT(1),
		.ENABLE_SAMPLES_INPUT(1),
		.ENABLE_UNDERSAMPLES_INPUT(1),
		.ENABLE_ADDRESS_INPUT(1),
		.ENABLE_INTR_SENT(1),
		.ENABLE_INTR_DONE(1),
		.ENABLE_INTR_ERROR(1),
		.DSP_FOR_CALC(1),
		
		.DEFAULT_SAMPLING_MODE(0),
		.DEFAULT_SAMPLE_NUMBER(0),
		.DEFAULT_UNDERSAMPLING_VALUE(0),

		.DEFAULT_DDR_LOW(32'h00100000),
		.DEFAULT_DDR_HIGH(32'h03FFFFFF)
		
		) dut(

		.cmd_in(tb_cmd_in),
		.cmd_en(tb_cmd_en),
		
		.number_samples(tb_number_samples),
		.undersample_factor(tb_undersample_factor),
		
		
		.ddr_addr_low(tb_ddr_addr_low),
		.ddr_addr_high(tb_ddr_addr_high),
		
		.clk_data(tb_clk_data),
		.data_in(tb_data_in),
		.data_en(tb_data_en),
		.transfer_en(tb_transfer_en),
		
		.intr_ack(tb_intr_ack),
		.intr_error(tb_intr_error),
		.intr_sent(tb_intr_sent),
		.intr_done(tb_intr_done),

		.enable(tb_enable),
		
		.reset(tb_reset),
		.reset_addr(tb_reset_addr),
		.reset_data(tb_reset_data),
		
		.sampling_mode(tb_sampling_mode),

		.samples_collected(tb_samples_collected),
		.samples_transmitted(tb_samples_transmitted),	
		.enabled(tb_enabled),
		.transfer_active(tb_transfer_active),
		
		// ToDo: add option in advanced to differentiate ack: either when received or when processed
		.cmd_processed(tb_cmd_processed),
		.bytes_collected(tb_bytes_collected),
		.bytes_transmitted(tb_bytes_transmitted),
		.current_ddr_addr(tb_current_ddr_addr),
		.pending_collect(tb_pending_collect),
		.pending_transmit(tb_pending_transmit),
		.last_data(tb_last_data),
		
		.status(tb_status),

		.m_axi_out_aclk(tb_clk),
		.m_axi_out_aresetn(tb_rstn),
		.m_axi_out_awid(),
		.m_axi_out_awaddr(tb_m_axi_out_awaddr),
		.m_axi_out_awlen(tb_m_axi_out_awlen),
		.m_axi_out_awsize(),
		.m_axi_out_awburst(),
		.m_axi_out_awlock(),
		.m_axi_out_awcache(),
		.m_axi_out_awprot(),
		.m_axi_out_awqos(),
		.m_axi_out_awuser(),
		.m_axi_out_awvalid(tb_m_axi_out_awvalid),
		.m_axi_out_awready(tb_axi_out_awready),
		.m_axi_out_wdata(tb_m_axi_out_wdata),
		.m_axi_out_wstrb(),
		.m_axi_out_wlast(tb_m_axi_out_wlast),
		.m_axi_out_wuser(),
		.m_axi_out_wvalid(tb_m_axi_out_wvalid),
		.m_axi_out_wready(tb_m_axi_out_wready),
		.m_axi_out_bid(0),
		.m_axi_out_bresp(tb_m_axi_out_bresp),
		.m_axi_out_buser(0),
		.m_axi_out_bvalid(tb_m_axi_out_bvalid),
		.m_axi_out_bready(tb_m_axi_out_bready),
		.m_axi_out_arid(),
		.m_axi_out_araddr(),
		.m_axi_out_arlen(),
		.m_axi_out_arsize(),
		.m_axi_out_arburst(),
		.m_axi_out_arlock(),
		.m_axi_out_arcache(),
		.m_axi_out_arprot(),
		.m_axi_out_arqos(),
		.m_axi_out_aruser(),
		.m_axi_out_arvalid(),
		.m_axi_out_arready(0),
		.m_axi_out_rid(0),
		.m_axi_out_rdata(0),
		.m_axi_out_rresp(0),
		.m_axi_out_rlast(0),
		.m_axi_out_ruser(0),
		.m_axi_out_rvalid(0),
		.m_axi_out_rready()
	);
	
	

endmodule
