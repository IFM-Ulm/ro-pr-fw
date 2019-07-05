source -notrace [format "%s/settings_paths.tcl" [file dirname [file normalize [info script]]]]
source -notrace [format "%s/settings_project.tcl" $project_sources_tcl]
source -notrace [format "%s/settings_ro.tcl" $project_sources_tcl]

set fw_flow_current 8
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
source -notrace [format "%s/settings_extract.tcl" $project_generated_sources_tcl]
source -notrace [format "%s/%s" $project_sources_tcl $pr_extract_file]

source -notrace [format "%s/misc/misc_extract_continue.tcl" $project_sources_tcl]

if { $EXTRACT_DELAY > 0 } {

	set netdelayrefId [open [format "%s/netdelays_ref.csv" $project_bitstreams] "w+"]
	close $netdelayrefId

	open_run "impl_1"
	
	set instance_name [format "%s" [pr_set_ref_name 0 $impl_ro]]
	pr_extract_delay $instance_name [format "%s/netdelays_ref.csv" $project_bitstreams] "ref_t1" 0
	
	close_design


	open_run "impl_2"

	set instance_name [format "%s" [pr_set_ref_name 0 $impl_ro]]
	pr_extract_delay $instance_name [format "%s/netdelays_ref.csv" $project_bitstreams] "ref_t2" 0
	
	close_design

}

puts "netdelay extraction for ref done"

set extract_counter 0
if { $EXTRACT_DELAY == 2 } {

	if { $continue_set == 1 } {
		error "error thrown on purpose to prevent handling this file wrong, disable it for sourcing and re-enable immediately afterwards"
		puts [format "continuing runs at %s, appending to %s" $continue_run [format "%s/netdelays.csv" $project_bitstreams]]
	} else {
		set netdelayId [open [format "%s/netdelays.csv" $project_bitstreams] "w+"]
		close $netdelayId
	}

	set all_runs [get_runs -filter "NAME =~ *child_impl_*"]


	foreach run_name $all_runs {
		
		incr extract_counter
		
		if { $continue_set == 1 } {
			if { $run_name == $continue_run } {
				puts [format "continue_run found: %s" $continue_run]
				set continue_set 0
				puts [format "opening run %s" $run_name]
			} else {
				puts [format "skipping run %s" $run_name]
				continue
			}
		} else {	
			puts [format "opening run %s" $run_name]
		}
		
		puts ""
		puts [format "extraction delays from run %d / %d " $extract_counter [llength $all_runs]]
		
		open_run $run_name
		
		for { set index 0 } {$index < $ro_number} {incr index} {
		
			puts [format "extracting index %d" $index]
			
			set instance_name [format "%s" [pr_set_instance_name $index $impl_ro]]
			puts [format "instance_name: %s" $instance_name]
			pr_extract_delay $instance_name [format "%s/netdelays.csv" $project_bitstreams] $run_name $index
		}
		
		puts "closing design"
		puts ""
		puts ""
		
		close_design
		
	}
}

puts "netdelay extraction done"

set flowfile [open [format "%s/misc_fw_flow.tcl" $project_generated_sources_tcl] "w+"]
puts $flowfile [format "set fw_flow_execute %d" [expr { $fw_flow_current + 1 } ]]
close $flowfile

set call_by_script 0