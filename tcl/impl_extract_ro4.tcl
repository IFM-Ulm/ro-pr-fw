global call_by_script
if { $call_by_script != 1 } {
	error "this script file is not intended to be run independently"
}

proc pr_extract_delay { instance_name file_path run_name index} {
# call like: delays_ro4 "ro_top_inst/ro4_inst_test" "E:/FPGA_PUFs/RO/RO_PR/bitstreams/netdelays.csv" "child_impl_1_constr_00_0000" 1
# source like: source -notrace E:/FPGA_PUFs/RO/RO_PR/RO_PR.srcs/tcl/delays_ro4.tcl

	puts [format "setting variables"]

	set net_name "ro4_con"
	set lut_name "ro4LUT6_"

	set net_3 [format "%s/%s[3]" $instance_name $net_name]
	set net_2 [format "%s/%s[2]" $instance_name $net_name]
	set net_1 [format "%s/%s[1]" $instance_name $net_name]
	set net_0 [format "%s/%s[0]" $instance_name $net_name]

	puts [format "instance_name: %s" $instance_name]
	puts [format "lut_name: %s" $lut_name]
	puts [format "net_3: %s" $net_3]
	puts [format "net_2: %s" $net_2]
	puts [format "net_1: %s" $net_1]
	puts [format "net_0: %s" $net_0]
	
	puts [format "extracting fast_min"]
	set n3fmin [get_property FAST_MIN [get_net_delays -of_objects [get_nets $net_3] -filter "NAME =~ *$lut_name*"]]
	set n2fmin [get_property FAST_MIN [get_net_delays -of_objects [get_nets $net_2] -filter "NAME =~ *$lut_name*"]]
	set n1fmin [get_property FAST_MIN [get_net_delays -of_objects [get_nets $net_1] -filter "NAME =~ *$lut_name*"]]
	set n0fmin [get_property FAST_MIN [get_net_delays -of_objects [get_nets $net_0] -filter "NAME =~ *$lut_name*"]]
	
	puts [format "extracting fast_max"]
	set n3fmax [get_property FAST_MAX [get_net_delays -of_objects [get_nets $net_3] -filter "NAME =~ *$lut_name*"]]
	set n2fmax [get_property FAST_MAX [get_net_delays -of_objects [get_nets $net_2] -filter "NAME =~ *$lut_name*"]]
	set n1fmax [get_property FAST_MAX [get_net_delays -of_objects [get_nets $net_1] -filter "NAME =~ *$lut_name*"]]
	set n0fmax [get_property FAST_MAX [get_net_delays -of_objects [get_nets $net_0] -filter "NAME =~ *$lut_name*"]]

	puts [format "extracting slow_min"]
	set n3smin [get_property SLOW_MIN [get_net_delays -of_objects [get_nets $net_3] -filter "NAME =~ *$lut_name*"]]
	set n2smin [get_property SLOW_MIN [get_net_delays -of_objects [get_nets $net_2] -filter "NAME =~ *$lut_name*"]]
	set n1smin [get_property SLOW_MIN [get_net_delays -of_objects [get_nets $net_1] -filter "NAME =~ *$lut_name*"]]
	set n0smin [get_property SLOW_MIN [get_net_delays -of_objects [get_nets $net_0] -filter "NAME =~ *$lut_name*"]]
	
	puts [format "extracting slow_max"]
	set n3smax [get_property SLOW_MAX [get_net_delays -of_objects [get_nets $net_3] -filter "NAME =~ *$lut_name*"]]
	set n2smax [get_property SLOW_MAX [get_net_delays -of_objects [get_nets $net_2] -filter "NAME =~ *$lut_name*"]]
	set n1smax [get_property SLOW_MAX [get_net_delays -of_objects [get_nets $net_1] -filter "NAME =~ *$lut_name*"]]
	set n0smax [get_property SLOW_MAX [get_net_delays -of_objects [get_nets $net_0] -filter "NAME =~ *$lut_name*"]]

	puts [format "checking CLB type"]

	set ind_clb [get_property TILE_TYPE [get_tiles -of_objects [get_sites -of_objects [get_cell [format "%s/%sD" $instance_name $lut_name]]]]]
	
	puts [format "CLB type is %s" $ind_clb]
	
	if { $ind_clb == "CLBLL_L" } {
		# logic CLB on left side of switchbox
		set clb_type 1
	} elseif { $ind_clb == "CLBLL_R"} {
		# logic CLB on right side of switchbox
		set clb_type 2
	} elseif { $ind_clb == "CLBLM_L"} {
		# memory CLB on left side of switchbox
		set clb_type 3
	} elseif {$ind_clb == "CLBLM_R" } {
		# memory CLB on right side of switchbox
		set clb_type 4
	} else {
		# type unknown but did not fail
		set clb_type 0
	}
	
	puts [format "CLB type set to %d" $clb_type]
	
	
	puts [format "checking SLICE type"]

	set ind_slc [get_property SITE_TYPE [get_sites -of_objects [get_cell [format "%s/%sD" $instance_name $lut_name]]]]
	
	puts [format "SLC type is %s" $ind_slc]
	
	if { $ind_slc == "SLICEL" } {
		# logic SLICE
		set slc_type 1
	} elseif { $ind_slc == "SLICEM"} {
		# memory SLICE
		set slc_type 2
	} else {
		# type unknown but did not fail
		set slc_type 0
	}
	
	puts [format "SLC type set to %d" $slc_type]
	
	
	puts [format "appending to %s" $file_path]
	set netdelayId [open $file_path "a+"]
	puts $netdelayId [format "%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%d,%d,%s,%d" $n3fmin $n3fmax $n3smin $n3smax $n2fmin $n2fmax $n2smin $n2smax $n1fmin $n1fmax $n1smin $n1smax $n0fmin $n0fmax $n0smin $n0smax $clb_type $slc_type $run_name $index]
	close $netdelayId

	puts "done"
	puts ""

	
}