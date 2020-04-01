global call_by_script
if { $call_by_script != 1 } {
	error "this script file is not intended to be run independently"
}

proc pr_route_puf {instance_name x_slc y_slc } {

	set net_name "ro4_con"
	set lut_name "ro4LUT6_"

	place_cell [format "%s/%sD SLICE_X%dY%d/D6LUT" $instance_name $lut_name $x_slc $y_slc]
	place_cell [format "%s/%sC SLICE_X%dY%d/C6LUT" $instance_name $lut_name $x_slc $y_slc]
	place_cell [format "%s/%sB SLICE_X%dY%d/B6LUT" $instance_name $lut_name $x_slc $y_slc]
	place_cell [format "%s/%sA SLICE_X%dY%d/A6LUT" $instance_name $lut_name $x_slc $y_slc]
	
	set cell_name [format "%s/%sD" $instance_name $lut_name]
	
	set ind_tile [get_property TILE_TYPE [get_tiles -of_objects [get_sites -of_objects [get_cell $cell_name]]]]

	set slc_type [get_property SITE_TYPE [get_sites -of_objects [get_cell $cell_name]]]

	set net_3 [format "%s/%s[3]" $instance_name $net_name]
	set net_2 [format "%s/%s[2]" $instance_name $net_name]
	set net_1 [format "%s/%s[1]" $instance_name $net_name]
	set net_0 [format "%s/%s[0]" $instance_name $net_name]

	# upper slice is in routing view, in non-routing it is the right one of the CLB
	
	set result_clb 0
	set result_slc 0
	
	if { $slc_type == "SLICEL"} {
		set result_slc 1
	} elseif { $slc_type == "SLICEM"} {
		set result_slc 2
	}	
	
	# logic CLB on left side of switchbox
	if { $ind_tile == "CLBLL_L" } {
		
		set result_clb 1
		
		if { $x_slc%2 } {
			# upper slice with odd index
			set_property fixed_route { { CLBLL_L_D CLBLL_LOGIC_OUTS11 IMUX_L30 CLBLL_L_C5 } } [get_nets $net_3]
			set_property fixed_route { { CLBLL_L_C CLBLL_LOGIC_OUTS10 IMUX_L13 CLBLL_L_B6 } } [get_nets $net_2]
			set_property fixed_route { { CLBLL_L_B CLBLL_LOGIC_OUTS9 IMUX_L10 CLBLL_L_A4 } } [get_nets $net_1]
			set_property fixed_route { { CLBLL_L_A CLBLL_LOGIC_OUTS8 IMUX_L41 CLBLL_L_D1 } } [get_nets $net_0]
			
			# feedback
			set_property fixed_route { { CLBLL_L_B CLBLL_LOGIC_OUTS9 IMUX_L42 CLBLL_L_D6 } } [get_nets $net_1]
			
		} else {
			# lower slice with even index
			set_property fixed_route { { CLBLL_LL_D CLBLL_LOGIC_OUTS15 IMUX_L31 CLBLL_LL_C5 } } [get_nets $net_3]
			set_property fixed_route { { CLBLL_LL_C CLBLL_LOGIC_OUTS14 IMUX_L12 CLBLL_LL_B6 } } [get_nets $net_2]
			set_property fixed_route { { CLBLL_LL_B CLBLL_LOGIC_OUTS13 IMUX_L11 CLBLL_LL_A4 } } [get_nets $net_1]
			set_property fixed_route { { CLBLL_LL_A CLBLL_LOGIC_OUTS12 IMUX_L40 CLBLL_LL_D1 } } [get_nets $net_0]
			
			# feedback
			set_property fixed_route { { CLBLL_LL_B CLBLL_LOGIC_OUTS13 IMUX_L43 CLBLL_LL_D6 } } [get_nets $net_1]
		}
	}
	
	# logic CLB on right side of switchbox
	if { $ind_tile == "CLBLL_R"} {
		
		set result_clb 2
		
		if { $x_slc%2 } {
			# upper slice with odd index
			set_property fixed_route { { CLBLL_L_D CLBLL_LOGIC_OUTS11 IMUX30 CLBLL_L_C5 } } [get_nets $net_3]
			set_property fixed_route { { CLBLL_L_C CLBLL_LOGIC_OUTS10 IMUX13 CLBLL_L_B6 } } [get_nets $net_2]
			set_property fixed_route { { CLBLL_L_B CLBLL_LOGIC_OUTS9 IMUX10 CLBLL_L_A4 } } [get_nets $net_1]
			set_property fixed_route { { CLBLL_L_A CLBLL_LOGIC_OUTS8 IMUX41 CLBLL_L_D1 } } [get_nets $net_0]
			
			# feedback 
			set_property fixed_route { { CLBLL_L_B CLBLL_LOGIC_OUTS9 IMUX42 CLBLL_L_D6 } } [get_nets $net_1]
			
		} else {
			# lower slice with even index
			set_property fixed_route { { CLBLL_LL_D CLBLL_LOGIC_OUTS15 IMUX31 CLBLL_LL_C5 } } [get_nets $net_3]
			set_property fixed_route { { CLBLL_LL_C CLBLL_LOGIC_OUTS14 IMUX12 CLBLL_LL_B6 } } [get_nets $net_2]
			set_property fixed_route { { CLBLL_LL_B CLBLL_LOGIC_OUTS13 IMUX11 CLBLL_LL_A4 } } [get_nets $net_1]
			set_property fixed_route { { CLBLL_LL_A CLBLL_LOGIC_OUTS12 IMUX40 CLBLL_LL_D1 } } [get_nets $net_0]
			
			# feedback
			set_property fixed_route { { CLBLL_LL_B CLBLL_LOGIC_OUTS13 IMUX43 CLBLL_LL_D6 } } [get_nets $net_1]
		}
	}

	# memory CLB on left side of switchbox
	if { $ind_tile == "CLBLM_L"} {
		
		set result_clb 3
		
		if { $x_slc%2 } {
			# upper slice with odd index
			set_property fixed_route { { CLBLM_L_D CLBLM_LOGIC_OUTS11 IMUX_L30 CLBLM_L_C5 } } [get_nets $net_3]
			set_property fixed_route { { CLBLM_L_C CLBLM_LOGIC_OUTS10 IMUX_L13 CLBLM_L_B6 } } [get_nets $net_2]
			set_property fixed_route { { CLBLM_L_B CLBLM_LOGIC_OUTS9 IMUX_L10 CLBLM_L_A4 } } [get_nets $net_1]
			set_property fixed_route { { CLBLM_L_A CLBLM_LOGIC_OUTS8 IMUX_L41 CLBLM_L_D1 } } [get_nets $net_0]
			
			# feedback
			set_property fixed_route { { CLBLM_L_B CLBLM_LOGIC_OUTS9 IMUX_L42 CLBLM_L_D6 } } [get_nets $net_1]
			
		} else {
			# lower slice with even index
			set_property fixed_route { { CLBLM_M_D CLBLM_LOGIC_OUTS15 IMUX_L31 CLBLM_M_C5 } } [get_nets $net_3]
			set_property fixed_route { { CLBLM_M_C CLBLM_LOGIC_OUTS14 IMUX_L12 CLBLM_M_B6 } } [get_nets $net_2]
			set_property fixed_route { { CLBLM_M_B CLBLM_LOGIC_OUTS13 IMUX_L11 CLBLM_M_A4 } } [get_nets $net_1]
			set_property fixed_route { { CLBLM_M_A CLBLM_LOGIC_OUTS12 IMUX_L40 CLBLM_M_D1 } } [get_nets $net_0]
			
			# feedback
			set_property fixed_route { { CLBLM_M_B CLBLM_LOGIC_OUTS13 IMUX_L43 CLBLM_M_D6 } } [get_nets $net_1]
		}
	}
	
	# memory CLB on right side of switchbox
	if {$ind_tile == "CLBLM_R" } {
		
		set result_clb 4
	
		if { $x_slc%2 } {
			# upper slice with odd index
			set_property fixed_route { { CLBLM_L_D CLBLM_LOGIC_OUTS11 IMUX30 CLBLM_L_C5 } } [get_nets $net_3]
			set_property fixed_route { { CLBLM_L_C CLBLM_LOGIC_OUTS10 IMUX13 CLBLM_L_B6 } } [get_nets $net_2]
			set_property fixed_route { { CLBLM_L_B CLBLM_LOGIC_OUTS9 IMUX10 CLBLM_L_A4 } } [get_nets $net_1]
			set_property fixed_route { { CLBLM_L_A CLBLM_LOGIC_OUTS8 IMUX41 CLBLM_L_D1 } } [get_nets $net_0]

			# feedback
			set_property fixed_route { { CLBLM_L_B CLBLM_LOGIC_OUTS9  IMUX42 CLBLM_L_D6 } } [get_nets $net_1]
			
		} else {
			# lower slice with even index
			set_property fixed_route { { CLBLM_M_D CLBLM_LOGIC_OUTS15 IMUX31 CLBLM_M_C5 } } [get_nets $net_3]
			set_property fixed_route { { CLBLM_M_C CLBLM_LOGIC_OUTS14 IMUX12 CLBLM_M_B6 } } [get_nets $net_2]
			set_property fixed_route { { CLBLM_M_B CLBLM_LOGIC_OUTS13 IMUX11 CLBLM_M_A4 } } [get_nets $net_1]
			set_property fixed_route { { CLBLM_M_A CLBLM_LOGIC_OUTS12 IMUX40 CLBLM_M_D1 } } [get_nets $net_0]
			
			# feedback
			set_property fixed_route { { CLBLM_M_B CLBLM_LOGIC_OUTS13 IMUX43 CLBLM_M_D6 } } [get_nets $net_1]
		}
	}
	
	set_property LOCK_PINS {I0:A1 I1:A2 I2:A3 I3:A4 I4:A5 I5:A6} [get_cells [format "%s/%sD" $instance_name $lut_name]]
	set_property LOCK_PINS {I0:A1 I1:A2 I2:A3 I3:A4 I4:A5 I5:A6} [get_cells [format "%s/%sC" $instance_name $lut_name]]
	set_property LOCK_PINS {I0:A1 I1:A2 I2:A3 I3:A4 I4:A5 I5:A6} [get_cells [format "%s/%sB" $instance_name $lut_name]]
	set_property LOCK_PINS {I0:A1 I1:A2 I2:A3 I3:A4 I4:A5 I5:A6} [get_cells [format "%s/%sA" $instance_name $lut_name]]
	set_property ALLOW_COMBINATORIAL_LOOPS TRUE [get_nets [format "%s/%s[3]" $instance_name $net_name]]
	
	return [list $result_clb $result_slc]
}
