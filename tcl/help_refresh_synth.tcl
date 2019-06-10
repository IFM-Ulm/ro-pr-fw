global call_by_script
if { $call_by_script != 1 } {
	error "this script file is not intended to be run independently"
}

source -notrace [format "%s/settings_paths.tcl" [file dirname [file normalize [info script]]]]
source -notrace [format "%s/settings_jobs.tcl" $project_sources_tcl]

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

# puts "checking run counter_fixed_synth_1 for REFRESH"
# if {[expr { [get_property NEEDS_REFRESH [get_runs counter_fixed_synth_1]] == 1 || [get_property PROGRESS [get_runs counter_fixed_synth_1]] != "100%"}]} {
	# puts "resetting run counter_fixed_synth_1"
	# reset_run [get_runs counter_fixed_synth_1]
	# puts "launching run counter_fixed_synth_1"
	# launch_runs [get_runs counter_fixed_synth_1]
# }

# puts "checking run system for REFRESH"
# if {[get_property NEEDS_REFRESH [get_runs system]] == 1} {
	# puts "resetting run system"
	# reset_run [get_runs system]
	# puts "launching run system"
	# launch_runs [get_runs system]
# }

puts "waiting on run PR_module_synth_1"
wait_on_run [get_runs PR_module_synth_1]

puts "waiting on run PR_empty_synth_1"
wait_on_run [get_runs PR_empty_synth_1]

# puts "waiting on run counter_fixed_synth_1"
# wait_on_run [get_runs counter_fixed_synth_1]

# puts "waiting on run system"
# wait_on_run [get_runs system]

# reset_target all [get_files  E:/FPGA_PUFs/RO/RO_PR/RO_PR.srcs/sources_1/bd/system/system.bd]
# export_ip_user_files -of_objects  [get_files  E:/FPGA_PUFs/RO/RO_PR/RO_PR.srcs/sources_1/bd/system/system.bd] -sync -no_script -force -quiet
# generate_target all [get_files  E:/FPGA_PUFs/RO/RO_PR/RO_PR.srcs/sources_1/bd/system/system.bd]


puts "checking run PR_module_synth_1 for PROGRESS"
if {[get_property PROGRESS [get_runs PR_module_synth_1]] != "100%"} {
   error "ERROR: PR_module_synth_1 failed"  
}

puts "checking run PR_empty_synth_1 for PROGRESS"
if {[get_property PROGRESS [get_runs PR_empty_synth_1]] != "100%"} {
   error "ERROR: PR_empty_synth_1 failed"  
}

# puts "checking run counter_fixed_synth_1 for PROGRESS"
# if {[get_property PROGRESS [get_runs counter_fixed_synth_1]] != "100%"} {
   # error "ERROR: counter_fixed_synth_1 failed"  
# }

# puts "checking run system for PROGRESS"
# if {[get_property PROGRESS [get_runs system]] != "100%"} {
   # error "ERROR: system failed"  
# }

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