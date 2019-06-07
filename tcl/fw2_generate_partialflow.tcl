
source -notrace [format "%s/tcl/settings_paths.tcl" [get_property DIRECTORY [current_project]]]
source -notrace [format "%s/settings_project.tcl" $project_sources_tcl]

set fw_flow_current 2
global call_by_script
set call_by_script 1

if { ! [file exists [format "%s/misc_fw_flow.tcl" $project_generated_sources_tcl]] } {
	error "flow control file misc_fw_flow.tcl not existent, call fw1_generate_filesets.tcl first"
}

source -notrace [format "%s/misc_fw_flow.tcl" $project_generated_sources_tcl]

if { $fw_flow_execute != $fw_flow_current } {
	error "wrong call order of files, current call index is $fw_flow_current, expected call index is $fw_flow_execute"
}

set_property name impl_old [get_runs impl_1]
set_property constrset constrs_synth [get_runs impl_old]

set_property PR_FLOW 1 [current_project] 

create_partition_def -name PR_definition -module PR_module

create_reconfig_module -name PR_module -partition_def [get_partition_defs PR_definition ]  -top PR_module
import_files -norecurse "$project_import_sources_hdl/ro4.v" "$project_import_sources_hdl/PR_module.v"  -of_objects [get_reconfig_modules PR_module]
create_pr_configuration -name PR_config -partitions [list ro_top_inst/PR_module_inst1:PR_module ]

create_reconfig_module -name PR_empty -partition_def [get_partition_defs PR_definition ]  -top PR_empty
import_files -norecurse "$project_import_sources_hdl/PR_empty.v"  -of_objects [get_reconfig_modules PR_empty]
create_pr_configuration -name PR_config_empty -partitions [list ro_top_inst/PR_module_inst1:PR_empty ]

create_run impl_1 -parent_run synth_1 -constrset constrs_static_1 -flow {Vivado Implementation 2018} -pr_config PR_config_empty
create_run impl_2 -parent_run synth_1 -constrset constrs_static_2 -flow {Vivado Implementation 2018} -pr_config PR_config_empty

current_run [get_runs impl_1]
delete_runs "impl_old"

set flowfile [open [format "%s/misc_fw_flow.tcl" $project_generated_sources_tcl] "w+"]
puts $flowfile [format "set fw_flow_execute %d" [expr { $fw_flow_current + 1 } ]]
close $flowfile

set call_by_script 0