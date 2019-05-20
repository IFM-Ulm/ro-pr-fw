# debugging by HSI:
# launch shell from sdk (or normal shell with some additions, TODO: which?)
# run "hsi"
# navigate to hw_platform folder (e.g. E:\FPGA_PUFs\partial_test_pr\partial_test_pr.sdk\toplevel_hw_platform_0 -> run "cd toplevel_hw_platform_0")
# open hardware description file *.hdf (e.g. system.hdf: run "open_hw_design system.hdf")
# 
# start debugging 

proc generate {drv_handle} {
	xdefine_include_file $drv_handle "xparameters.h" "AH_CPU2PL" "NUM_INSTANCES" "DEVICE_ID" "C_S_AXI_WRITE_BASEADDR" "C_S_AXI_WRITE_HIGHADDR" "C_S_AXI_READ_BASEADDR" "C_S_AXI_READ_HIGHADDR" "C_S_AXI_INTR_BASEADDR" "C_S_AXI_INTR_HIGHADDR" "USED_INPUTS" "USED_OUTPUTS" "IRQ_ENABLED" "SERIALIZE_INPUT_ENABLED" "SERIALIZE_OUTPUT_ENABLED" "CLOCKING_ADVANCED"
	xdefine_config_file $drv_handle "ah_cpu2pl_g.c" "AH_CPU2PL" "DEVICE_ID" "C_S_AXI_WRITE_BASEADDR" "C_S_AXI_WRITE_HIGHADDR" "C_S_AXI_READ_BASEADDR" "C_S_AXI_READ_HIGHADDR" "C_S_AXI_INTR_BASEADDR" "C_S_AXI_INTR_HIGHADDR" "USED_INPUTS" "USED_OUTPUTS" "IRQ_ENABLED" "SERIALIZE_INPUT_ENABLED" "SERIALIZE_OUTPUT_ENABLED" "CLOCKING_ADVANCED"
	xdefine_canonical_xpars $drv_handle "xparameters.h" "AH_CPU2PL" "NUM_INSTANCES" "DEVICE_ID" "C_S_AXI_WRITE_BASEADDR" "C_S_AXI_WRITE_HIGHADDR" "C_S_AXI_READ_BASEADDR" "C_S_AXI_READ_HIGHADDR" "C_S_AXI_INTR_BASEADDR" "C_S_AXI_INTR_HIGHADDR" "USED_INPUTS" "USED_OUTPUTS" "IRQ_ENABLED" "SERIALIZE_INPUT_ENABLED" "SERIALIZE_OUTPUT_ENABLED" "CLOCKING_ADVANCED"
    checkConnections $drv_handle "xparameters.h"
}

proc checkConnections {drv_handle file_name} {

	set file_config [open "src/ah_cpu2pl_g.c" "a"]
	
	# debug: set allIPs [get_cells *]
	set allIPs [::hsi::utils::get_common_driver_ips $drv_handle]
	set allIPsLength [llength $allIPs]
	
	
	# create config array for connected inputs
	puts $file_config "u32 AH_CPU2PL_connected_inputs\[$allIPsLength\]\[32\] = "
	puts $file_config "\{"
	for {set countIP 0} {$countIP < $allIPsLength} {incr countIP} {

		set curIP [lindex $allIPs $countIP]
		set curInputs [get_pins -of_object $curIP -filter NAME=~input_*]
		
		puts -nonewline $file_config "\t\{ "

		for {set countInput 0} {$countInput < [llength $curInputs]} {incr countInput} {

			set isConnected [get_property IS_CONNECTED [lindex $curInputs $countInput]]
			
			if {[expr $countInput + 1] < 32}  {
				if {$isConnected == 1} { puts -nonewline $file_config "TRUE, " } else { puts -nonewline $file_config "FALSE, " } 
			} else {
				if {$isConnected == 1} { puts -nonewline $file_config "TRUE" } else { puts -nonewline $file_config "FALSE" } 
			}
		}
		
		for {set countInput [llength $curInputs]} {$countInput < 32} {incr countInput} {
		
			if {[expr $countInput + 1] < 32}  {
				 puts -nonewline $file_config "FALSE, "
			} else {
				puts -nonewline $file_config "FALSE"
			}
		}
		
		
		if {[expr $countIP + 1] < [llength $allIPs]} {
			puts $file_config " \},"
		} else {
			puts $file_config " \}"
		}		
	}
	puts $file_config "\};\n"
	
	
	# create config array for connected serial output
	puts $file_config [writeConfig "AH_CPU2PL_connected_input_serial" $allIPsLength $allIPs "inputs_serial"]
	puts $file_config ""
	

	# create config array for connected outputs
	puts $file_config "u32 AH_CPU2PL_connected_outputs\[$allIPsLength\]\[32\] = "
	puts $file_config "\{"
	for {set countIP 0} {$countIP < $allIPsLength} {incr countIP} {

		set curIP [lindex $allIPs $countIP]
		set curOutputs [get_pins -of_object $curIP -filter NAME=~output_*]
		
		puts -nonewline $file_config "\t\{ "

		for {set countOutput 0} {$countOutput < [llength $curOutputs]} {incr countOutput} {

			set isConnected [get_property IS_CONNECTED [lindex $curOutputs $countOutput]]
			
			if {[expr $countOutput + 1] < 32}  {
				if {$isConnected == 1} { puts -nonewline $file_config "TRUE, " } else { puts -nonewline $file_config "FALSE, " } 
			} else {
				if {$isConnected == 1} { puts -nonewline $file_config "TRUE" } else { puts -nonewline $file_config "FALSE" } 
			}
		}
		
		for {set countOutput [llength $curOutputs]} {$countOutput < 32} {incr countOutput} {
		
			if {[expr $countOutput + 1] < 32}  {
				 puts -nonewline $file_config "FALSE, "
			} else {
				puts -nonewline $file_config "FALSE"
			}
		}		
		
		if {[expr $countIP + 1] < [llength $allIPs]} {
			puts $file_config " \},"
		} else {
			puts $file_config " \}"
		}		
	}
	puts $file_config "\};\n"
	
	# create config array for connected serial output
	puts $file_config [writeConfig "AH_CPU2PL_connected_clock_pl" $allIPsLength $allIPs "clock_pl"]
	puts $file_config ""
	
	# create config array for connected serial output
	puts $file_config [writeConfig "AH_CPU2PL_connected_output_serial" $allIPsLength $allIPs "outputs_serial"]
	puts $file_config ""
	
	
	# create config array for connected irqs
	puts $file_config [writeConfig "AH_CPU2PL_connected_irq" $allIPsLength $allIPs "irq"]
	puts $file_config ""
	
	
	# get output pin connetced to IRQ_F2P
	set irq_pin [get_pin -of_objects [get_nets -of_objects [get_pin -of_objects [get_cells ps7_scugic_0] -filter NAME=~IRQ_F2P]] -filter {NAME!~IRQ_F2P* && DIRECTION == O}]
	set irq_ip [get_cells -of_objects $irq_pin]
	
	if {[string trim $irq_ip] != ""} {
	
		# create config array for connected irqs
		puts -nonewline $file_config "u32 AH_CPU2PL_IRQid\[$allIPsLength\] = \{"
	
		set irq_ip_name [get_property IP_NAME $irq_ip]
	
		if {[string match -nocase $irq_ip_name "AH_CPU2PL"]} {
			for {set countIP 0} {$countIP < $allIPsLength} {incr countIP} {

				# rework: go through all AXI4 ips and check which one is connected -> get_net approach
				
				set curIP [lindex $allIPs $countIP]
				set curPin [get_pins -of_object $curIP -filter NAME==irq]
				
				if {$curPin != {}} {
					set irqID [get_property IRQID $curPin]
					# set isConnected [get_property IS_CONNECTED $curPin]
					set isConnected [expr {$irqID ne ""}]
							
					if {[expr $countIP + 1] < $allIPsLength} {
						if {$isConnected == 1} { puts -nonewline $file_config "$irqID, " } else { puts -nonewline $file_config "0, " } 
					} else {
						if {$isConnected == 1} { puts $file_config "$irqID\};\n" } else { puts $file_config "0\};\n" } 
					}
				} else {
					if {[expr $countIP + 1] < $allIPsLength} {
						puts -nonewline $file_config "0, "
					} else {
						puts $file_config "0\};\n"
					}
				}
			}
		}
		
		if {[string match -nocase $irq_ip_name "xlconcat"]} {
			
			# get nets connected as inputs to concat ip
			set irq_nets [get_net -of_objects [get_pin -of_objects $irq_ip -filter NAME=~In*]]
			
			for {set countIP 0} {$countIP < $allIPsLength} {incr countIP} {
				
				set curIP [lindex $allIPs $countIP]
				set curPin [get_pins -of_object $curIP -filter NAME==irq]
				
				set break_loop 0
				
				if { $curPin eq "" } {
					set break_loop -1
				} else {
				
					# get name of net connect to pin "irq" of AXI4CPU2PL component
					# set irq_net_name [get_property NAME [get_nets -of_objects $curPin]]
					set irq_net [get_nets -of_objects $curPin]
					if { $irq_net eq "" } {
						set break_loop -1
					} else {				
						set irq_net_name [get_property NAME $irq_net]
					}				
				}
							
				if { $break_loop > -1 } {
					# compare net names, store index of concat input
					set break_loop -1
					for {set index 0} {$index < [llength $irq_nets]} {incr index} {
						
						set net_name [get_property NAME [lindex $irq_nets $index]]
						
						if {[string match -nocase $irq_net_name $net_name]} {
							# connected ip found
							set break_loop $index
							break
						}
					}
				}
				
				# calculate IRQID 
				if { $break_loop > -1 } {
					if {[expr $countIP + 1] < $allIPsLength} {
						puts -nonewline $file_config [format "%d, " [expr { $break_loop + 61 }]]
					} else {
						puts $file_config [format "%d\};\n" [expr { $break_loop + 61 }]]
					}
				} else {
					if {[expr $countIP + 1] < $allIPsLength} {
						puts -nonewline $file_config "0, "
					} else {
						puts $file_config "0\};\n"
					}
				}
				
			}
		}
	} else {
		# create config array for connected irqs
		puts -nonewline $file_config "u32 AH_CPU2PL_IRQid\[$allIPsLength\] = \{0\};\n"
	}
	
	
	# create config array for connected interrupts_in
	puts $file_config [writeConfig "AH_CPU2PL_connected_intr_input" $allIPsLength $allIPs "intr_input"]
	puts $file_config ""
	
	
	# create config array for connected interrupts_out
	puts $file_config [writeConfig "AH_CPU2PL_connected_intr_output" $allIPsLength $allIPs "intr_output"]
	puts $file_config ""
	
	
	# create config array for connected interrupts_out
	puts $file_config [writeConfig "AH_CPU2PL_connected_intr_ack" $allIPsLength $allIPs "intr_ack"]
	puts $file_config ""
	
	
	# create config array for connected axiwrite_wdata
	puts $file_config [writeConfig "AH_CPU2PL_connected_axiwrite_wdata" $allIPsLength $allIPs "s_axi_write_wdata"]
	puts $file_config ""
	
		
	# create config array for connected axiwrite_aclk
	puts $file_config [writeConfig "AH_CPU2PL_connected_axiwrite_aclk" $allIPsLength $allIPs "s_axi_write_aclk"]
	puts $file_config ""
	
		
	# create config array for connected axiwrite_aresetn
	puts $file_config [writeConfig "AH_CPU2PL_connected_axiwrite_aresetn" $allIPsLength $allIPs "s_axi_write_aresetn"]
	puts $file_config ""
	
	
	# create config array for connected axiread_rdata
	puts $file_config [writeConfig "AH_CPU2PL_connected_axiread_rdata" $allIPsLength $allIPs "s_axi_read_rdata"]
	puts $file_config ""
	
		
	# create config array for connected axiread_aclk
	puts $file_config [writeConfig "AH_CPU2PL_connected_axiread_aclk" $allIPsLength $allIPs "s_axi_read_aclk"]
	puts $file_config ""

	
	# create config array for connected axiread_aresetn
	puts $file_config [writeConfig "AH_CPU2PL_connected_axiread_aresetn" $allIPsLength $allIPs "s_axi_read_aresetn"]
	puts $file_config ""
	
	
	# create config array for connected axiintr_wdata
	puts $file_config [writeConfig "AH_CPU2PL_connected_axiintr_wdata" $allIPsLength $allIPs "s_axi_intr_wdata"]
	puts $file_config ""
	
	
	# create config array for connected axiintr_rdata
	puts $file_config [writeConfig "AH_CPU2PL_connected_axiintr_rdata" $allIPsLength $allIPs "s_axi_intr_rdata"]
	puts $file_config ""
	
		
	# create config array for connected axiintr_aclk
	puts $file_config [writeConfig "AH_CPU2PL_connected_axiintr_aclk" $allIPsLength $allIPs "s_axi_intr_aclk"]
	puts $file_config ""
		
	# create config array for connected axiintr_aresetn
	puts $file_config [writeConfig "AH_CPU2PL_connected_axiintr_aresetn" $allIPsLength $allIPs "s_axi_intr_aresetn"]
	
	
	close $file_config

}


proc writeConfig {varName ipLength listIPs filterName} {

	set retVal "u32 $varName\[$ipLength\] = \{"

	for {set countIP 0} {$countIP < $ipLength} {incr countIP} {

		set curIP [lindex $listIPs $countIP]
		set curPin [get_pins -of_object $curIP -filter NAME==$filterName]

		if {$curPin != {}} {
			set isConnected [get_property IS_CONNECTED $curPin]
					
			if {[expr $countIP + 1] < $ipLength} {
				if {$isConnected == 1} { set retVal [concat $retVal "TRUE, "] } else { set retVal [concat $retVal "FALSE, "] } 
			} else {
				if {$isConnected == 1} { set retVal [concat $retVal "TRUE \};\n"] } else { set retVal [concat $retVal "FALSE \};\n"] } 
			}
		} else {
			if {[expr $countIP + 1] < $ipLength} {
				set retVal [concat $retVal "FALSE, "]
			} else {
				set retVal [concat $retVal "FALSE \};\n"]
			}
		}
	}
	
	return $retVal

}
