if { ! [info exists script_sourced_as_notrace] } {
	set script_sourced_as_notrace 1
	source -notrace [info script]
	return
}
if { [info exists script_sourced_as_notrace] } {
	unset script_sourced_as_notrace
}

source -notrace [format "%s/settings_paths.tcl" [file dirname [file normalize [info script]]]]
source -notrace [format "%s/settings_project.tcl" $project_sources_tcl]
source -notrace [format "%s/settings_ro.tcl" $project_sources_tcl]

set fw_flow_current 4
global call_by_script
set call_by_script 1

if { ! [file exists [format "%s/misc_fw_flow.tcl" $project_generated_sources_tcl]] } {
	error "flow control file misc_fw_flow.tcl not existent, call fw1_generate_filesets.tcl first"
}

source -notrace [format "%s/misc_fw_flow.tcl" $project_generated_sources_tcl]

if { $fw_flow_execute != $fw_flow_current } {
	error "wrong call order of files, current call index is $fw_flow_current, expected call index is $fw_flow_execute"
}

# set variables impl_ro and ro_number by script
source -notrace [format "%s/settings_impl.tcl" $project_generated_sources_tcl]

# set variables DEBUG and DEBUG_RUNS by script
source -notrace [format "%s/settings_debug.tcl" $project_generated_sources_tcl]

source -notrace [format "%s/help_create_constrsets_runs.tcl" $project_sources_tcl]

set_property constrset constrs_synth [get_runs synth_1]
set_property constrset constrs_static_1 [get_runs impl_1]
set_property constrset constrs_static_2 [get_runs impl_2]

set csvId [open [format "%s/config.csv" $project_bitstreams] "w+"]
puts $csvId [format "constrset,inst,index,x,y,valid,clbtype,slctype"]
close $csvId

set resultId [open [format "%s/placement_results.txt" $project_bitstreams] "w+"]
close $resultId

# global definitions
global pr_module
global constrset_name
global ro_number
global pr_stop
global pr_counter
global impl_parent
global impl_ro
global toplevel_prefix
global run_counter

global pr_X
global pr_Y
global pr_X_offset
global pr_Y_offset
global pr_X_shift
global pr_Y_shift

global pr_X_SLC_offset
global pr_Y_SLC_offset

global ref_netdelay_extracted
set ref_netdelay_extracted 0

global lst_prohibits_X

# placement variables
set ro_counter 0

set bin_counter 0

# name settings
set impl_parent_t1 "impl_1"
set impl_parent_t2 "impl_2"
set toplevel_prefix_t1 "1"
set toplevel_prefix_t2 "2"
set st_clock_region_t1 "1"
set st_clock_region_t2 "2"

# static settings
set pr_module "ro_top_inst/PR_module_inst1"

# toplevel_1 runs
set impl_parent $impl_parent_t1
set toplevel_prefix $toplevel_prefix_t1
set st_clock_region $st_clock_region_t1

set lst_prohibits_X $lst_prohibits1_X

set resultId [open [format "%s/placement_results.txt" $project_bitstreams] "a+"]
puts $resultId [format "DEBUG: %d (%d DEBUG_RUNS)" $DEBUG $DEBUG_RUNS]
puts $resultId ""
puts $resultId [format "implementation: %s" $impl_ro]
puts $resultId [format "ro_per_bin: %d" $ro_number]
puts $resultId ""
puts $resultId [format "pr_module: %s" $pr_module]
puts $resultId [format "pr_X_SLC_offset: %d" $pr_X_SLC_offset]
puts $resultId [format "pr_Y_SLC_offset: %d" $pr_Y_SLC_offset]
puts $resultId [format "pr_X_shift: %d" $pr_X_shift]
puts $resultId [format "pr_Y_shift: %d" $pr_Y_shift]
puts $resultId ""
puts $resultId [format "impl_parent: %s" $impl_parent]
puts $resultId [format "toplevel_prefix: %s" $toplevel_prefix]
puts $resultId [format "st_clock_region: %s" $st_clock_region]
close $resultId


# changing variables
set pr_counter 0
set run_counter 0

set lst_partial_areas_X_start $lst_partial1_areas_X_start
set lst_partial_areas_X_end $lst_partial1_areas_X_end
set lst_partial_areas_Y_start $lst_partial1_areas_Y_start
set lst_partial_areas_Y_end $lst_partial1_areas_Y_end

if { $DEBUG < 2 } {
		
	if { $fast_approach } {
		current_run [get_runs impl_1]
		open_run synth_1 -constrset constrs_synth -name synth_1 -pr_config [current_pr_configuration]
	}
}

set index_partial_areas 0
foreach partial_areas_x $lst_partial_areas_X_start {
	
	set pr_X_start $partial_areas_x
	set pr_Y_start [lindex $lst_partial_areas_Y_start $index_partial_areas]
	set pr_X $pr_X_start
	set pr_Y $pr_Y_start
	set pr_X_offset 0
	set pr_Y_offset 0
	
	set pr_X_max [lindex $lst_partial_areas_X_end $index_partial_areas]
	set pr_Y_max [lindex $lst_partial_areas_Y_end $index_partial_areas]
	
	incr index_partial_areas

	set resultId [open [format "%s/placement_results.txt" $project_bitstreams] "a+"]
	puts $resultId ""
	puts $resultId [format "partial_area: %d" $index_partial_areas]
	puts $resultId [format "pr_X_start: %d" $pr_X_start]
	puts $resultId [format "pr_Y_start: %d" $pr_Y_start]
	puts $resultId [format "pr_X_max: %d" $pr_X_max]
	puts $resultId [format "pr_Y_max: %d" $pr_Y_max]
	close $resultId

	set pr_stop 0

	while { $pr_stop == 0 } {

		puts [format "run %d, counter %d" $run_counter $pr_counter]

		incr run_counter 1
		incr bin_counter 1
		
		set constrset_name [format "constr_%s_%04d" $st_clock_region $pr_counter]
		
		pr_create_constrset $pr_X_start $pr_Y_start $pr_X_max $pr_Y_max
		
		if { $DEBUG == 1 || $DEBUG == 3 } {
			if { $run_counter == $DEBUG_RUNS } {
				set pr_stop 1
			}
		}
		
	}
}

incr ro_counter $pr_counter

set resultId [open [format "%s/placement_results.txt" $project_bitstreams] "a+"]
puts $resultId ""
puts $resultId [format "ro_counter (impl_1): %d" $pr_counter]
puts $resultId [format "bin_counter (impl_1): %d" $bin_counter]
puts $resultId ""
close $resultId

puts [format "toplevel 1, ro counter %d" $pr_counter]

set bin_counter_prev $bin_counter


# toplevel_2 runs
set impl_parent $impl_parent_t2
set toplevel_prefix $toplevel_prefix_t2
set st_clock_region $st_clock_region_t2

set lst_prohibits_X $lst_prohibits2_X

set resultId [open [format "%s/placement_results.txt" $project_bitstreams] "a+"]
puts $resultId [format "impl_parent: %s" $impl_parent]
puts $resultId [format "toplevel_prefix: %s" $toplevel_prefix]
puts $resultId [format "st_clock_region: %s" $st_clock_region]
close $resultId


# changing variables

set pr_counter 0
set run_counter 0

set_property constrset constrs_synth [get_runs synth_1]
set_property constrset constrs_static_1 [get_runs impl_1]
set_property constrset constrs_static_2 [get_runs impl_2]

if { $DEBUG < 2 } {
	
	if { $fast_approach } {
	
		close_design
		
		current_run [get_runs impl_2]
		open_run synth_1 -constrset constrs_synth -name synth_1 -pr_config [current_pr_configuration]
	}
}

set lst_partial_areas_X_start $lst_partial2_areas_X_start
set lst_partial_areas_X_end $lst_partial2_areas_X_end
set lst_partial_areas_Y_start $lst_partial2_areas_Y_start
set lst_partial_areas_Y_end $lst_partial2_areas_Y_end

set index_partial_areas 0
foreach partial_areas_x $lst_partial_areas_X_start {
	
	set pr_X_start $partial_areas_x
	set pr_Y_start [lindex $lst_partial_areas_Y_start $index_partial_areas]
	set pr_X $pr_X_start
	set pr_Y $pr_Y_start
	set pr_X_offset 0
	set pr_Y_offset 0
	
	set pr_X_max [lindex $lst_partial_areas_X_end $index_partial_areas]
	set pr_Y_max [lindex $lst_partial_areas_Y_end $index_partial_areas]
	
	incr index_partial_areas

	set resultId [open [format "%s/placement_results.txt" $project_bitstreams] "a+"]
	puts $resultId ""
	puts $resultId [format "partial_area: %d" $index_partial_areas]
	puts $resultId [format "pr_X_start: %d" $pr_X_start]
	puts $resultId [format "pr_Y_start: %d" $pr_Y_start]
	puts $resultId [format "pr_X_max: %d" $pr_X_max]
	puts $resultId [format "pr_Y_max: %d" $pr_Y_max]
	close $resultId

	set pr_stop 0

	while { $pr_stop == 0} {

		puts [format "run %d, counter %d" $run_counter $pr_counter]

		incr run_counter 1
		incr bin_counter 1
		
		set constrset_name [format "constr_%s_%04d" $st_clock_region $pr_counter]
		pr_create_constrset $pr_X_start $pr_Y_start $pr_X_max $pr_Y_max
		
		if { $DEBUG == 1 || $DEBUG == 3 } {
			if { $run_counter == $DEBUG_RUNS } {
				set pr_stop 1 
			}
		}
	}
}

incr ro_counter $pr_counter

set resultId [open [format "%s/placement_results.txt" $project_bitstreams] "a+"]
puts $resultId ""
puts $resultId [format "ro_counter (impl_2): %d" $pr_counter]
puts $resultId [format "bin_counter (impl_2): %d" [expr { $bin_counter - $bin_counter_prev }]]
puts $resultId ""
close $resultId

puts [format "toplevel 2, ro counter %d" $pr_counter]

set_property constrset constrs_synth [get_runs synth_1]
set_property constrset constrs_static_1 [get_runs impl_1]
set_property constrset constrs_static_2 [get_runs impl_2]


if {  $DEBUG < 2 } {
	if { $fast_approach } {
		close_design
	}
}

current_run [get_runs impl_1]

puts [format "ro_counter (total): %d" $ro_counter]
puts [format "bin_counter (total): %d" $bin_counter]

set resultId [open [format "%s/placement_results.txt" $project_bitstreams] "a+"]
puts $resultId [format "ro_counter (total): %d" $ro_counter]
puts $resultId [format "bin_counter (total): %d" $bin_counter]
close $resultId

puts "done"

set flowfile [open [format "%s/misc_fw_flow.tcl" $project_generated_sources_tcl] "w+"]
puts $flowfile [format "set fw_flow_execute %d" [expr { $fw_flow_current + 1 } ]]
close $flowfile

set call_by_script 0