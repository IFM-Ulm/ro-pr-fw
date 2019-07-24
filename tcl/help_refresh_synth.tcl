global call_by_script
if { $call_by_script != 1 } {
	error "this script file is not intended to be run independently"
}

source -notrace [format "%s/settings_paths.tcl" [file dirname [file normalize [info script]]]]
source -notrace [format "%s/settings_jobs.tcl" $project_generated_sources_tcl]

puts "checking run PR_module_synth_1 for REFRESH"
if {[expr { [get_property NEEDS_REFRESH [get_runs PR_module_synth_1]] == 1 || [get_property PROGRESS [get_runs PR_module_synth_1]] != "100%"}]} {
	puts "resetting run PR_module_synth_1"
	reset_run [get_runs PR_module_synth_1]
	puts "launching run PR_module_synth_1"
	launch_runs [get_runs PR_module_synth_1]
}

puts "checking run PR_empty_synth_1 for REFRESH"
if {[expr { [get_property NEEDS_REFRESH [get_runs PR_empty_synth_1]] == 1 || [get_property PROGRESS [get_runs PR_empty_synth_1]] != "100%"}]} {
	puts "resetting run PR_empty_synth_1"
	reset_run [get_runs PR_empty_synth_1]
	puts "launching run PR_empty_synth_1"
	launch_runs [get_runs PR_empty_synth_1]
}

puts "waiting on run PR_module_synth_1"
wait_on_run [get_runs PR_module_synth_1]

puts "waiting on run PR_empty_synth_1"
wait_on_run [get_runs PR_empty_synth_1]

puts "checking run PR_module_synth_1 for PROGRESS"
if {[get_property PROGRESS [get_runs PR_module_synth_1]] != "100%"} {
   error "ERROR: PR_module_synth_1 failed"  
}

puts "checking run PR_empty_synth_1 for PROGRESS"
if {[get_property PROGRESS [get_runs PR_empty_synth_1]] != "100%"} {
   error "ERROR: PR_empty_synth_1 failed"  
}

puts "checking run synth_1 for REFRESH"
if {[expr { [get_property NEEDS_REFRESH [get_runs synth_1]] == 1 || [get_property PROGRESS [get_runs synth_1]] != "100%"}]} {
	puts "resetting run synth_1"
	reset_run [get_runs synth_1]
	puts "launching run synth_1"
	launch_runs [get_runs synth_1] -jobs $jobs_synth
}

puts "waiting on run synth_1"
wait_on_run [get_runs synth_1]

puts "checking run synth_1 for PROGRESS"
if {[get_property PROGRESS [get_runs synth_1]] != "100%"} {
   error "ERROR: synth_1 failed"  
}