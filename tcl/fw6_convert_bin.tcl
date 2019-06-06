# set project_path [get_property DIRECTORY [current_project]]
# set project_bitstreams [format "%s/bitstreams" $project_path]
# set project_sources_tcl [format "%s/tcl" [get_property DIRECTORY [current_project]]]
# set project_name [current_project]

source -notrace [format "%s/tcl/settings_paths.tcl" [get_property DIRECTORY [current_project]]]
source -notrace [format "%s/tcl/settings_project.tcl" $project_path]

set fw_flow_current 6
global call_by_script
set call_by_script 1

if { ! [file exists [format "%s/misc_fw_flow.tcl" $project_generated_sources_tcl]] } {
	error "flow control file misc_fw_flow.tcl not existent, call fw1_generate_filesets.tcl first"
}

source -notrace [format "%s/misc_fw_flow.tcl" $project_generated_sources_tcl]

if { $fw_flow_execute != $fw_flow_current } {
	error "wrong call order of files, current call index is $fw_flow_current, expected call index is $fw_flow_execute"
}

set file_list [glob -nocomplain [format "%s/*.bit" $project_bitstreams]]
if {[llength $file_list] > 0} {	
	foreach file $file_list {
		file delete $file
	}
}

set file_list [glob -nocomplain [format "%s/*.bin" $project_bitstreams]]
if {[llength $file_list] > 0} {	
	foreach file $file_list {
		file delete $file
	}
}

set file_list [glob -nocomplain [format "%s/*.prm" $project_bitstreams]]
if {[llength $file_list] > 0} {	
	foreach file $file_list {
		file delete $file
	}
}


file copy [format "%s/%s.runs/impl_1/toplevel.bit" $project_path $project_name] [format "%s/t1.bit" $project_bitstreams]
write_cfgmem -format BIN -interface SMAPx32 -disablebitswap -loadbit [format "up 0x0 %s/t1.bit" $project_bitstreams] [format "%s/T1.bin" $project_bitstreams]
file copy [format "%s/%s.runs/impl_2/toplevel.bit" $project_path $project_name] [format "%s/t2.bit" $project_bitstreams]
write_cfgmem -format BIN -interface SMAPx32 -disablebitswap -loadbit [format "up 0x0 %s/t2.bit" $project_bitstreams] [format "%s/T2.bin" $project_bitstreams]

set child_runs_1 [get_runs *child_impl_1_constr_*]
set run_counter 0
set bin_counter_1 0
foreach run $child_runs_1 {
	incr run_counter 1
	incr bin_counter_1 1
	file copy [format "%s/%s.runs/%s/ro_top_inst_PR_module_inst1_PR_module_partial.bit" $project_path $project_name $run] [format "%s/t1i1r%02d.bit" $project_bitstreams $run_counter]
	write_cfgmem -format BIN -interface SMAPx32 -disablebitswap -loadbit [format "up 0x0 %s/t1i1r%02d.bit" $project_bitstreams $run_counter] [format "%s/T1I1R%02d.bin" $project_bitstreams $run_counter]
}

set child_runs_2 [get_runs *child_impl_2_constr_*]
set run_counter 0
set bin_counter_2 0
foreach run $child_runs_2 {
	incr run_counter 1
	incr bin_counter_2 1
	file copy [format "%s/%s.runs/%s/ro_top_inst_PR_module_inst1_PR_module_partial.bit" $project_path $project_name $run] [format "%s/t2i1r%02d.bit" $project_bitstreams $run_counter]
	write_cfgmem -format BIN -interface SMAPx32 -disablebitswap -loadbit [format "up 0x0 %s/t2i1r%02d.bit" $project_bitstreams $run_counter] [format "%s/T2I1R%02d.bin" $project_bitstreams $run_counter]
}


set file_list [glob -nocomplain [format "%s/*.bit" $project_bitstreams]]
if {[llength $file_list] > 0} {	
	foreach file $file_list {
		file delete $file
	}
}

set file_list [glob -nocomplain [format "%s/*.prm" $project_bitstreams]]
if {[llength $file_list] > 0} {	
	foreach file $file_list {
		file delete $file
	}
}

source -notrace [format "%s/settings_impl.tcl" $project_sources_tcl]

set paramId [open [format "%s/params.csv" $project_bitstreams] "w+"]
puts $paramId [format "%s" $impl_ro]
puts $paramId [format "%d" $ro_number]
puts $paramId [format "%d" $bin_counter_1]
puts $paramId [format "%d" $bin_counter_2]
puts $paramId [format "%d" [expr { $bin_counter_1 + $bin_counter_2 }]]
set t1_size [file size [format "%s/T1.bin" $project_bitstreams]]
puts $paramId [format "%d" $t1_size]
set t2_size [file size [format "%s/T2.bin" $project_bitstreams]]
puts $paramId [format "%d" $t2_size]
set t1b_size [file size [format "%s/T%sI1R01.bin" $project_bitstreams "1"]]
puts $paramId [format "%d" $t1b_size]
set t2b_size [file size [format "%s/T%sI1R01.bin" $project_bitstreams "2"]]
puts $paramId [format "%d" $t2b_size]
close $paramId

set headerId [open [format "%s/fw_impl_generated.h" $project_generated_sources_sdk] "w+"]
puts $headerId "#ifndef SRC_FW_IMPL_GENERATED_H_"
puts $headerId "#define SRC_FW_IMPL_GENERATED_H_"
puts $headerId [format "#define IMPL_NUMBER_DUT %d" $ro_number]
puts $headerId [format "#define IMPL_NUMBER_REF %d" $ref_number]
puts $headerId "#endif"
puts $headerId ""
close $headerId

puts "conversion to .bin done"

set flowfile [open [format "%s/misc_fw_flow.tcl" $project_generated_sources_tcl] "w+"]
puts $flowfile [format "set fw_flow_execute %d" [expr { $fw_flow_current + 1 } ]]
close $flowfile

set call_by_script 0