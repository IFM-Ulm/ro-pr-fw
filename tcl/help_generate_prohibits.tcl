global call_by_script
if { $call_by_script != 1 } {
	error "this script file is not intended to be run independently"
}

set index 0
foreach prohibit_x $lst_prohibits_X {
	
	for {set prohibit_y [lindex $lst_prohibits_Y_start $index]} {$prohibit_y <= [lindex $lst_prohibits_Y_end $index]} {incr prohibit_y} {
		set_property PROHIBIT 1 [get_sites [format "SLICE_X%dY%d" $prohibit_x $prohibit_y]]
	}
	
	incr index
}
	
