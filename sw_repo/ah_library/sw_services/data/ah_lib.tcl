
#---------------------------------------------
# FFS_drc - check system configuration and make sure
# all components to run ISF are available.
#---------------------------------------------

proc ah_drc {libhandle} {

	set chw [hsi::current_hw_design]
	
	set property_board [get_property BOARD $chw]
	set property_device [get_property DEVICE $chw]
	set property_family [get_property FAMILY $chw]
	set property_package [get_property PACKAGE $chw]

	set scugic_activated [get_property CONFIG.scugic $libhandle]
	
	set timer_activated [get_property CONFIG.timer $libhandle]
	set uart_activated [get_property CONFIG.uart $libhandle]
	set tcpip_activated [get_property CONFIG.tcpip $libhandle]
	set gpio_activated [get_property CONFIG.gpio $libhandle]
	
	set pcap_activated [get_property CONFIG.pcap $libhandle]
	set sd_activated [get_property CONFIG.sd $libhandle]
	set xadc_activated [get_property CONFIG.xadc $libhandle]
	set pmod_activated [get_property CONFIG.pmod $libhandle]

	if { $property_family == "zynq" } {
		if {!$scugic_activated && $timer_activated} {
			error "ERROR: SCUGIC option needed for TIMER"
		}
		
		if {!$scugic_activated && $uart_activated} {
			error "ERROR: SCUGIC option needed for UART"
		}
		
		if {!$scugic_activated && $tcpip_activated} {
			error "ERROR: SCUGIC option needed for TCPIP"
		}
		
		if {!$timer_activated && $tcpip_activated} {
			error "ERROR: TIMER option needed for TCPIP"
		}
	} else {
		error "ERROR: Board package not supported"
	}

	
	
}


proc generate {libhandle} {

}


#-------
# post_generate: called after generate called on all libraries
#-------
proc post_generate {libhandle} {

	#source -notrace "./test.tcl"

	
	
	xgen_opts_file $libhandle
	
}

#-------
# execs_generate: called after BSP's, libraries and drivers have been compiled
#	This procedure builds the libisf.a library
#-------
proc execs_generate {libhandle} {

}


proc xgen_opts_file {libhandle} {
	
	#set file_handle [xopen_include_file "xparameters.h"]
	set file_handle [hsi::utils::open_include_file "xparameters.h"]
	
	puts $file_handle ""
	puts $file_handle "/* AH_LIB Settings */"
	
	set chw [hsi::current_hw_design]
	
	set property_board [get_property BOARD $chw]
	set property_device [get_property DEVICE $chw]
	set property_family [get_property FAMILY $chw]
	set property_package [get_property PACKAGE $chw]
	
	# get_os
	# standalone
	
	if {$property_board == "digilentinc.com:zybo:part0:1.0"} {
		# ZYBO
		puts $file_handle "#define AH_BOARD_ZYBO"
		set led_id1 "leds_4bits_tri_"
		set led_id2 "leds_4bits"
		set sws_id1 "sws_4bits_tri_"
		set sws_id2 "sws_4bits"
		set btn_id1 "btns_4bits_tri_"
		set btn_id2 "btns_4bits"
	} elseif {$property_board == "em.avnet.com:zed:part0:1.4"} {
		# ZedBoard
		puts $file_handle "#define AH_BOARD_ZEDBOARD"
		set led_id1 "leds_8bits_tri_"
		set led_id2 "leds_8bits"
		set sws_id1 "sws_8bits_tri_"
		set sws_id2 "sws_8bits"
		set btn_id1 "btns_5bits_tri_"
		set btn_id2 "btns_5bits"
	} elseif {$property_board == "www.digilentinc.com:pynq-z1:part0:1.0"} {
		# PYNQ
		puts $file_handle "#define AH_BOARD_PYNQ"
		set led_id1 "leds_4bits_tri_"
		set led_id2 "leds_4bits"
		set sws_id1 "sws_2bits_tri_"
		set sws_id2 "sws_2bits"
		set btn_id1 "btns_4bits_tri_"
		set btn_id2 "btns_4bits"
	}  elseif {$property_board == "digilentinc.com:zybo-z7-20:part0:1.0"} {
		# ZYBO Z7-20
		puts $file_handle "#define AH_BOARD_ZYBO"
		set led_id1 "leds_4bits_tri_"
		set led_id2 "leds_4bits"
		set sws_id1 "sws_4bits_tri_"
		set sws_id2 "sws_4bits"
		set btn_id1 "btns_4bits_tri_"
		set btn_id2 "btns_4bits"
	} else {
		puts $file_handle [format "/* unknown board: %s */" $property_board]
		set led_id1 "leds_unknown"
		set led_id2 "leds_unknown"
		set sws_id1 "sws_unknown"
		set sws_id2 "sws_unknown"
		set btn_id1 "btns_unknown"
		set btn_id2 "btns_unknown"
	}
	
	if { $property_family == "zynq" } {
		
		set scugic_activated [get_property CONFIG.scugic $libhandle]
		if {$scugic_activated == true} {
			puts $file_handle "#define AH_SCUGIC_ACTIVATED"
		}
		
		set timer_activated [get_property CONFIG.timer $libhandle]
		if {$timer_activated == true} {
			puts $file_handle "#define AH_TIMER_ACTIVATED"
		}
		
		set tcpip_activated [get_property CONFIG.tcpip $libhandle]
		if {$tcpip_activated == true} {
		
			puts $file_handle "#define AH_TCPIP_ACTIVATED"
			
			set tcpip_memory_manual_activated [get_property CONFIG.tcpip_memory_manual $libhandle]
			if {$tcpip_memory_manual_activated == true} {
				puts $file_handle "#define AH_TCPIP_MANUAL_MEMORY"
			}
			
			set tcpip_mac_i2c_activated [get_property CONFIG.tcpip_mac_i2c $libhandle]
			if {$tcpip_mac_i2c_activated == true} {
				puts $file_handle "#define AH_TCPIP_MAC_I2C"
			}
		}
		
		
		
		set uart_activated [get_property CONFIG.uart $libhandle]
		if {$uart_activated == true} {
			puts $file_handle "#define AH_UART_ACTIVATED"
			
			if {$property_board == "digilentinc.com:zybo:part0:1.0"} {
				# zybo
				puts $file_handle "#define AH_UART_DEVICE_ID XPAR_PS7_UART_1_DEVICE_ID"
				puts $file_handle "#define AH_UART_INTR XPAR_XUARTPS_1_INTR"
			} elseif {$property_board == "em.avnet.com:zed:part0:1.4"} {
				# zedboard
				puts $file_handle "#define AH_UART_DEVICE_ID XPAR_PS7_UART_1_DEVICE_ID"
				puts $file_handle "#define AH_UART_INTR XPAR_XUARTPS_1_INTR"
			} elseif {$property_board == "www.digilentinc.com:pynq-z1:part0:1.0"} {
				# pynq
				puts $file_handle "#define AH_UART_DEVICE_ID XPAR_PS7_UART_0_DEVICE_ID"
				puts $file_handle "#define AH_UART_INTR XPAR_XUARTPS_0_INTR"
			} elseif {$property_board == "digilentinc.com:zybo-z7-20:part0:1.0"} {
				# zybo
				puts $file_handle "#define AH_UART_DEVICE_ID XPAR_PS7_UART_1_DEVICE_ID"
				puts $file_handle "#define AH_UART_INTR XPAR_XUARTPS_1_INTR"
			} else {
				error "can't create UART defines - board not supported"
			}
			
			
		}
		
		set gpio_activated [get_property CONFIG.gpio $libhandle]
		if {$gpio_activated == true} {
			puts $file_handle "#define AH_GPIO_ACTIVATED"
			
			# hsi::get_ports
			# DDR_cas_n DDR_cke DDR_ck_n DDR_ck_p DDR_cs_n DDR_reset_n DDR_odt DDR_ras_n DDR_we_n DDR_ba DDR_addr DDR_dm DDR_dq DDR_dqs_n DDR_dqs_p FIXED_IO_mio FIXED_IO_ddr_vrn FIXED_IO_ddr_vrp FIXED_IO_ps_srstb FIXED_IO_ps_clk FIXED_IO_ps_porb btns_4bits_tri_i leds_4bits_tri_i leds_4bits_tri_o leds_4bits_tri_t sws_4bits_tri_i
			
			if { [llength [get_ports -filter NAME=~*$led_id1*]] > 0 } {
				set gpio_led_net [get_intf_nets -of_objects [get_intf_ports -filter NAME=~$led_id2] -filter NAME=~axi_gpio_*_GPIO]
				if {[llength $gpio_led_net] > 0} {
					set gpio_led_id [string range $gpio_led_net 9 9]
					puts $file_handle [format "#define AH_GPIO_IP_LED %s" $gpio_led_id]
					puts $file_handle [format "#define AH_GPIO_DEVICE_IP_LED XPAR_GPIO_%s_DEVICE_ID" $gpio_led_id]
				}
			}
			
			if { [llength [get_ports -filter NAME=~*$btn_id1*]] > 0 } {
				set gpio_btn_net [get_intf_nets -of_objects [get_intf_ports -filter NAME=~$btn_id2] -filter NAME=~axi_gpio_*_GPIO]
				if {[llength $gpio_btn_net] > 0} {
					set gpio_btn_id [string range $gpio_btn_net 9 9]
					puts $file_handle [format "#define AH_GPIO_IP_BTN %s" $gpio_btn_id]
					puts $file_handle [format "#define AH_GPIO_DEVICE_IP_BTN XPAR_GPIO_%s_DEVICE_ID" $gpio_btn_id]
					
					puts $file_handle [format "#ifdef XPAR_FABRIC_AXI_GPIO_%s_IP2INTC_IRPT_INTR" $gpio_btn_id]
					puts $file_handle [format "#define AH_GPIO_INTR_IP_BTN XPAR_FABRIC_AXI_GPIO_%s_IP2INTC_IRPT_INTR" $gpio_btn_id]
					puts $file_handle "#endif"
				}
			}
			
			if { [llength [get_ports -filter NAME=~*$sws_id1*]] > 0 } {
				set gpio_sws_net [get_intf_nets -of_objects [get_intf_ports -filter NAME=~$sws_id2] -filter NAME=~axi_gpio_*_GPIO]
				if {[llength $gpio_sws_net] > 0} {
					set gpio_sws_id [string range $gpio_sws_net 9 9]
					puts $file_handle [format "#define AH_GPIO_IP_SWS %s" $gpio_sws_id]
					puts $file_handle [format "#define AH_GPIO_DEVICE_IP_SWS XPAR_GPIO_%s_DEVICE_ID" $gpio_sws_id]
					
					puts $file_handle [format "#ifdef XPAR_FABRIC_AXI_GPIO_%s_IP2INTC_IRPT_INTR" $gpio_sws_id]
					puts $file_handle [format "#define AH_GPIO_INTR_IP_SWS XPAR_FABRIC_AXI_GPIO_%s_IP2INTC_IRPT_INTR" $gpio_sws_id]
					puts $file_handle "#endif"
				}
			}
		}
		
		set pcap_activated [get_property CONFIG.pcap $libhandle]
		if {$pcap_activated == true} {
			puts $file_handle "#define AH_PCAP_ACTIVATED"
		}
		
		set sd_activated [get_property CONFIG.sd $libhandle]
		if {$sd_activated == true} {
			puts $file_handle "#define AH_SD_ACTIVATED"
		}
		
		set xadc_activated [get_property CONFIG.xadc $libhandle]
		if {$xadc_activated == true} {
		
			# hsi::get_drivers
			#ps7_afi_0 ps7_afi_1 ps7_afi_2 ps7_afi_3 ps7_coresight_comp_0 ps7_ddr_0 ps7_ddrc_0 ps7_dev_cfg_0 ps7_dma_ns ps7_dma_s ps7_ethernet_0 ps7_globaltimer_0 ps7_gpio_0 ps7_gpv_0 ps7_intc_dist_0 ps7_iop_bus_config_0 ps7_l2cachec_0 ps7_ocmc_0 ps7_pl310_0 ps7_pmu_0 ps7_qspi_0 ps7_qspi_linear_0 ps7_ram_0 ps7_ram_1 ps7_scuc_0 ps7_scugic_0 ps7_scutimer_0 ps7_scuwdt_0 ps7_sd_0 ps7_slcr_0 ps7_uart_1 ps7_usb_0 ps7_xadc_0 AH_CPU2PL_0 axi_gpio_0 axi_gpio_1 axi_gpio_2 xadc_wiz_0

		
			puts $file_handle "#define AH_XADC_ACTIVATED"
		}
		
		set pmod_activated [get_property CONFIG.pmod $libhandle]
		if {$pmod_activated == true} {
			puts $file_handle "#define AH_PMOD_ACTIVATED"
			
			# ToDo: trace back the connection e.g. jb_tri_o to the connected IP, check if it is a axi_pgio_*, get the number and put that in xparameters.h and also check for the correct bitdwith of 8?
			# checking of correct connection to package pin not possible?
			
			set exists_jb [llength [get_ports -filter NAME=~*jb_tri_*]]
			if { $exists_jb > 0 } {
				puts $file_handle "#define AH_PMOD_EXISTS_JB"
			}
			
			if { [llength [get_ports -filter NAME=~*jb_tri_*]] > 0 } {
				set gpio_jb_net [get_intf_nets -of_objects [get_intf_ports -filter NAME=~jb] -filter NAME=~axi_gpio_*_GPIO]
				if {[llength $gpio_jb_net] > 0} {
					set gpio_jb_id [string range $gpio_jb_net 9 9]
					puts $file_handle [format "#define AH_GPIO_IP_JB %s" $gpio_jb_id]
					puts $file_handle [format "#define AH_GPIO_DEVICE_IP_JB XPAR_GPIO_%s_DEVICE_ID" $gpio_jb_id]
				}
			}
			
			if { [llength [get_ports -filter NAME=~*jc_tri_*]] > 0 } {
				set gpio_jc_net [get_intf_nets -of_objects [get_intf_ports -filter NAME=~jc] -filter NAME=~axi_gpio_*_GPIO]
				if {[llength $gpio_jc_net] > 0} {
					set gpio_jc_id [string range $gpio_jc_net 9 9]
					puts $file_handle [format "#define AH_GPIO_IP_JC %s" $gpio_jc_id]
					puts $file_handle [format "#define AH_GPIO_DEVICE_IP_JC XPAR_GPIO_%s_DEVICE_ID" $gpio_jc_id]
				}
			}
			
			if { [llength [get_ports -filter NAME=~*jd_tri_*]] > 0 } {
				set gpio_jd_net [get_intf_nets -of_objects [get_intf_ports -filter NAME=~jd] -filter NAME=~axi_gpio_*_GPIO]
				if {[llength $gpio_jd_net] > 0} {
					set gpio_jd_id [string range $gpio_jd_net 9 9]
					puts $file_handle [format "#define AH_GPIO_IP_JD %s" $gpio_jd_id]
					puts $file_handle [format "#define AH_GPIO_DEVICE_IP_JD XPAR_GPIO_%s_DEVICE_ID" $gpio_jd_id]
				}
			}
			
			if { [llength [get_ports -filter NAME=~*je_tri_*]] > 0 } {
				set gpio_je_net [get_intf_nets -of_objects [get_intf_ports -filter NAME=~je] -filter NAME=~axi_gpio_*_GPIO]
				if {[llength $gpio_je_net] > 0} {
					set gpio_je_id [string range $gpio_je_net 9 9]
					puts $file_handle [format "#define AH_GPIO_IP_JE %s" $gpio_je_id]
					puts $file_handle [format "#define AH_GPIO_DEVICE_IP_JE XPAR_GPIO_%s_DEVICE_ID" $gpio_je_id]
				}
			}
			
		}
		
		puts $file_handle ""
		
		close $file_handle

		# Copy the include files to the include directory
		set srcdir [file join src include]
		set dstdir [file join .. .. include]

		# Create dstdir if it does not exist
		if { ! [file exists $dstdir] } {
			file mkdir $dstdir
		}

		# Get list of files in the srcdir
		set sources [glob -join $srcdir *.h]

		# Copy each of the files in the list to dstdir
		foreach source $sources {
			file copy -force $source $dstdir
		}
	
	}
}

