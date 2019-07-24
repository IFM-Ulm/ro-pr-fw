source -notrace [format "%s/settings_paths.tcl" [file dirname [file normalize [info script]]]]
source -notrace [format "%s/settings_impl.tcl" $project_generated_sources_tcl]

set project_part [get_property PART [current_project]]
puts "found part is $project_part"


if { $impl_ro == "ro4" } {
	set pr_X_shift 2
	set pr_Y_shift 2
	set pr_Y_SLC_offset 1
	set pr_X_SLC_offset 1
	
	set pr_route_file "impl_place_route_ro4.tcl"
	set pr_undo_file "impl_undo_ro4.tcl"
	set pr_extract_file "impl_extract_ro4.tcl"
	
} else {
	error [format "unknown impl_ro = %s" $impl_ro]
}


proc pr_set_instance_name { index impl_ro } {
	if { $impl_ro == "ro4" } {
		set instance_name [format "ro_top_inst/PR_module_inst1/RoGen\[%d\].puf2" $index]
	} else {
		error [format "unknown impl_ro = %s" $impl_ro]
	}
	
	return $instance_name
}

proc pr_set_ref_name { index impl_ro } {
	if { $impl_ro == "ro4" } {
		set instance_name "ro_top_inst/RO_ref_inst/puf_ref"
	} else {
		error [format "unknown impl_ro = %s" $impl_ro]
	}
	
	return $instance_name
}
