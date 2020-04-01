
proc check_board_supported {} {
	
	set property_board [get_property BOARD_PART [current_project]]
	
	if {$property_board == "digilentinc.com:zybo:part0:1.0" || $property_board == "digilentinc.com:zybo:part0:2.0"} {
		puts "supported board found: zybo"
	} elseif {$property_board == "em.avnet.com:zed:part0:1.4" || $property_board == "digilentinc.com:zedboard:part0:1.0"} {
		puts "supported board found: zedboard"
	} elseif {$property_board == "www.digilentinc.com:pynq-z1:part0:1.0"} {
		puts "supported board found: pynq"
	} elseif {$property_board == "digilentinc.com:zybo-z7-20:part0:1.0"} {
		puts "supported board found: zybo-z7-20"
	} elseif {$property_board == "em.avnet.com:microzed_7020:part0:1.1"} {
		puts "supported board found: microzed"
	} else {
		error "board not supported: $property_board"
	}
}

proc ps_apply_board_settings {} {
	
	# common settings
	set_property -dict [list CONFIG.PCW_USE_S_AXI_HP0 {1} CONFIG.PCW_USE_FABRIC_INTERRUPT {1} CONFIG.PCW_S_AXI_HP0_DATA_WIDTH {32} CONFIG.PCW_USE_M_AXI_GP0 {1} CONFIG.PCW_IRQ_F2P_INTR {1}  CONFIG.PCW_USB0_PERIPHERAL_ENABLE {0}] [get_bd_cells processing_system7_0]
	
	# individual settings	
	set property_board [get_property BOARD_PART [current_project]]
	
	if {$property_board == "digilentinc.com:zybo:part0:1.0"} {
		# zybo
		set_property -dict [list CONFIG.PCW_ENET0_PERIPHERAL_ENABLE {1} CONFIG.PCW_TTC0_PERIPHERAL_ENABLE {0}] [get_bd_cells processing_system7_0]
	} elseif {$property_board == "em.avnet.com:zed:part0:1.4" || $property_board == "digilentinc.com:zedboard:part0:1.0"} {
		# zedboard
		set_property -dict [list CONFIG.PCW_TTC0_PERIPHERAL_ENABLE {0}] [get_bd_cells processing_system7_0]
	} elseif {$property_board == "www.digilentinc.com:pynq-z1:part0:1.0"} {
		# pynq
		set_property -dict [list CONFIG.PCW_QSPI_GRP_SINGLE_SS_ENABLE {1}] [get_bd_cells processing_system7_0]
	} elseif {$property_board == "digilentinc.com:zybo-z7-20:part0:1.0"} {
		# zybo-z7-20
		# set_property -dict [list ] [get_bd_cells processing_system7_0]
	} elseif {$property_board == "em.avnet.com:microzed_7020:part0:1.1"} {
		# microzed
		set_property -dict [list CONFIG.PCW_QSPI_GRP_SINGLE_SS_ENABLE {1} CONFIG.PCW_WDT_PERIPHERAL_ENABLE {0} CONFIG.PCW_TTC0_PERIPHERAL_ENABLE {0} ] [get_bd_cells processing_system7_0]
	} else {
		error "can't create ZYNQ PS - board not supported"
	}
	
}