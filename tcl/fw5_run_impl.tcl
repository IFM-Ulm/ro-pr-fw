source -notrace [format "%s/settings_paths.tcl" [file dirname [file normalize [info script]]]]
source -notrace [format "%s/settings_project.tcl" $project_sources_tcl]
source -notrace [format "%s/settings_jobs.tcl" $project_generated_sources_tcl]

set fw_flow_current 5
global call_by_script
set call_by_script 1

if { ! [file exists [format "%s/misc_fw_flow.tcl" $project_generated_sources_tcl]] } {
	error "flow control file misc_fw_flow.tcl not existent, call fw1_generate_filesets.tcl first"
}

source -notrace [format "%s/misc_fw_flow.tcl" $project_generated_sources_tcl]

if { $fw_flow_execute != $fw_flow_current } {
	error "wrong call order of files, current call index is $fw_flow_current, expected call index is $fw_flow_execute"
}

source -notrace [format "%s/help_refresh_synth.tcl" $project_sources_tcl]

puts "checking run impl_1 for REFRESH"
if { [get_property NEEDS_REFRESH [get_runs impl_1]] == 1 } {
	puts "resetting run impl_1"
	reset_run [get_runs impl_1]
}

puts "checking run impl_2 for REFRESH"
if { [get_property NEEDS_REFRESH [get_runs impl_2]] == 1 } {
	puts "resetting run impl_2"
	reset_run [get_runs impl_2]
}

puts "checking run impl_1 for PROGRESS"
if {[get_property PROGRESS [get_runs impl_1]] != "100%"} {
	puts "launching run impl_1"
	launch_runs [get_runs impl_1] -to_step write_bitstream -jobs 1
}

puts "checking run impl_2 for PROGRESS"
if {[get_property PROGRESS [get_runs impl_2]] != "100%"} {
	puts "launching run impl_2"
	launch_runs [get_runs impl_2] -to_step write_bitstream -jobs 1
}

puts "waiting on run impl_1"
wait_on_run [get_runs impl_1]

puts "waiting on run impl_2"
wait_on_run [get_runs impl_2]

puts "checking run impl_1 for PROGRESS"
if {[get_property PROGRESS [get_runs impl_1]] != "100%"} {
   error "ERROR: impl_1 failed"  
}

puts "checking run impl_2 for PROGRESS"
if {[get_property PROGRESS [get_runs impl_2]] != "100%"} {
   error "ERROR: impl_2 failed"  
}


set child_runs_all [get_runs *child_impl_*_constr_*]

puts "launching runs child_impl_*_constr_*"
launch_runs $child_runs_all -to_step write_bitstream -jobs $jobs_impl_all

puts "waiting on runs child_impl_*_constr_*"
foreach run $child_runs_all {

	wait_on_run $run
	
	while {[get_property PROGRESS [get_runs $run]] != "100%"} {

		wait_on_run $run
		
		puts [format "checking run %s for PROGRESS" $run]
		if {[get_property PROGRESS [get_runs $run]] != "100%"} {
		   # error "ERROR: run failed"  
		   puts "run failed, resetting and restarting..."
		   reset_runs [get_runs $run]
		   launch_runs [get_runs $run] -to_step write_bitstream -jobs 1
		} else {
			puts "run successful"
		}
		
	}
	
}

# set child_runs_1 [get_runs *child_impl_1_constr_*]
# set child_runs_2 [get_runs *child_impl_2_constr_*]

# puts "launching runs child_impl_1_constr_*"
# launch_runs $child_runs_1 -to_step write_bitstream -jobs $jobs_impl_1

# puts "launching runs child_impl_2_constr_*"
# launch_runs $child_runs_2 -to_step write_bitstream -jobs $jobs_impl_2

# puts "waiting on runs child_impl_1_constr_*"
# foreach run $child_runs_1 {

	# wait_on_run $run
	
	# while {[get_property PROGRESS [get_runs $run]] != "100%"} {

		# wait_on_run $run
		
		# puts [format "checking run %s for PROGRESS" $run]
		# if {[get_property PROGRESS [get_runs $run]] != "100%"} {
		   # # error "ERROR: run failed"  
		   # puts "run failed, resetting and restarting..."
		   # reset_runs [get_runs $run]
		   # launch_runs [get_runs $run] -to_step write_bitstream -jobs 1
		# } else {
			# puts "run successful"
		# }
		
	# }
	
# }

# puts "waiting on runs child_impl_2_constr_*"
# foreach run $child_runs_2 {

	# while {[get_property PROGRESS [get_runs $run]] != "100%"} {

		# wait_on_run $run
		
		# puts [format "checking run %s for PROGRESS" $run]
		# if {[get_property PROGRESS [get_runs $run]] != "100%"} {
		   # puts "run failed, resetting and restarting..."
		   # reset_runs [get_runs $run]
		   # launch_runs [get_runs $run] -to_step write_bitstream -jobs 1
		# } else {
			# puts "run successful"
		# }
		
	# }
# }

puts ""
puts "all done"

set flowfile [open [format "%s/misc_fw_flow.tcl" $project_generated_sources_tcl] "w+"]
puts $flowfile [format "set fw_flow_execute %d" [expr { $fw_flow_current + 1 } ]]
close $flowfile

set call_by_script 0