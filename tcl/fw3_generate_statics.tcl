source -notrace [format "%s/tcl/settings_paths.tcl" [get_property DIRECTORY [current_project]]]
source -notrace [format "%s/tcl/settings_project.tcl" $project_path]

set fw_flow_current 3
global call_by_script
set call_by_script 1

if { ! [file exists [format "%s/misc_fw_flow.tcl" $project_generated_sources_tcl]] } {
	error "flow control file misc_fw_flow.tcl not existent, call fw1_generate_filesets.tcl first"
}

source -notrace [format "%s/misc_fw_flow.tcl" $project_generated_sources_tcl]

if { $fw_flow_execute != $fw_flow_current } {
	error "wrong call order of files, current call index is $fw_flow_current, expected call index is $fw_flow_execute"
}

launch_runs synth_1 -jobs 2

puts "waiting on run synth_1"
wait_on_run [get_runs synth_1]

puts "checking run synth_1 for PROGRESS"
if {[get_property PROGRESS [get_runs synth_1]] != "100%"} {
	error "ERROR: synth_1 failed"  
}


set coord_ref_X $coord_ref1_X
set coord_ref_Y $coord_ref1_Y

set coord_SLICE_partial_X_start $coord_SLICE_partial1_X_start
set coord_SLICE_partial_Y_start $coord_SLICE_partial1_Y_start
set coord_SLICE_partial_X_end $coord_SLICE_partial1_X_end
set coord_SLICE_partial_Y_end $coord_SLICE_partial1_Y_end

set coord_DSP48_partial_X_start $coord_DSP48_partial1_X_start
set coord_DSP48_partial_Y_start $coord_DSP48_partial1_Y_start
set coord_DSP48_partial_X_end $coord_DSP48_partial1_X_end
set coord_DSP48_partial_Y_end $coord_DSP48_partial1_Y_end

set coord_RAMB18_partial_X_start $coord_RAMB18_partial1_X_start
set coord_RAMB18_partial_Y_start $coord_RAMB18_partial1_Y_start
set coord_RAMB18_partial_X_end $coord_RAMB18_partial1_X_end
set coord_RAMB18_partial_Y_end $coord_RAMB18_partial1_Y_end

set coord_RAMB36_partial_X_start $coord_RAMB36_partial1_X_start
set coord_RAMB36_partial_Y_start $coord_RAMB36_partial1_Y_start
set coord_RAMB36_partial_X_end $coord_RAMB36_partial1_X_end
set coord_RAMB36_partial_Y_end $coord_RAMB36_partial1_Y_end


set lst_prohibits_X $lst_prohibits1_X
set lst_prohibits_Y_start $lst_prohibits1_Y_start
set lst_prohibits_Y_end $lst_prohibits1_Y_end

set_property constrset constrs_static_1 [get_runs impl_1]

# set_property target_constrs_file "$project_path/src/constr/constrs_static_1/puf_ref_ro4.xdc" [get_filesets constrs_static_1]
set_property target_constrs_file "$project_sources/constrs_static_1/imports/constrs_static_1/puf_ref_ro4.xdc" [get_filesets constrs_static_1]

open_run synth_1 -name synth_1 -pr_config [current_pr_configuration]

source -notrace "$project_path/tcl/help_generate_ref.tcl"

save_constraints

# set_property target_constrs_file "$project_path/src/constr/constrs_static_1/partial.xdc" [get_filesets constrs_static_1]
set_property target_constrs_file "$project_sources/constrs_static_1/imports/constrs_static_1/partial.xdc" [get_filesets constrs_static_1]

source -notrace "$project_path/tcl/help_generate_partial.tcl"

save_constraints


set_property target_constrs_file "$project_sources/constrs_static_1/imports/constrs_static_1/prohibits.xdc" [get_filesets constrs_static_1]

source -notrace "$project_path/tcl/help_generate_prohibits.tcl"

save_constraints



# set_property target_constrs_file "$project_path/src/constr/constrs_static_1/vivado.xdc" [get_filesets constrs_static_1]
set_property target_constrs_file "$project_sources/constrs_static_1/imports/constrs_static_1/vivado.xdc" [get_filesets constrs_static_1]

close_design



set coord_ref_X $coord_ref2_X
set coord_ref_Y $coord_ref2_Y

set coord_SLICE_partial_X_start $coord_SLICE_partial2_X_start
set coord_SLICE_partial_Y_start $coord_SLICE_partial2_Y_start
set coord_SLICE_partial_X_end $coord_SLICE_partial2_X_end
set coord_SLICE_partial_Y_end $coord_SLICE_partial2_Y_end

set coord_DSP48_partial_X_start $coord_DSP48_partial2_X_start
set coord_DSP48_partial_Y_start $coord_DSP48_partial2_Y_start
set coord_DSP48_partial_X_end $coord_DSP48_partial2_X_end
set coord_DSP48_partial_Y_end $coord_DSP48_partial2_Y_end

set coord_RAMB18_partial_X_start $coord_RAMB18_partial2_X_start
set coord_RAMB18_partial_Y_start $coord_RAMB18_partial2_Y_start
set coord_RAMB18_partial_X_end $coord_RAMB18_partial2_X_end
set coord_RAMB18_partial_Y_end $coord_RAMB18_partial2_Y_end

set coord_RAMB36_partial_X_start $coord_RAMB36_partial2_X_start
set coord_RAMB36_partial_Y_start $coord_RAMB36_partial2_Y_start
set coord_RAMB36_partial_X_end $coord_RAMB36_partial2_X_end
set coord_RAMB36_partial_Y_end $coord_RAMB36_partial2_Y_end

set lst_prohibits_X $lst_prohibits2_X
set lst_prohibits_Y_start $lst_prohibits2_Y_start
set lst_prohibits_Y_end $lst_prohibits2_Y_end

set_property constrset constrs_static_2 [get_runs impl_1]
# set_property target_constrs_file "$project_path/src/constr/constrs_static_2/puf_ref_ro4.xdc" [get_filesets constrs_static_2]
set_property target_constrs_file "$project_sources/constrs_static_2/imports/constrs_static_2/puf_ref_ro4.xdc" [get_filesets constrs_static_2]

open_run synth_1 -name synth_1 -pr_config [current_pr_configuration]

source -notrace "$project_path/tcl/help_generate_ref.tcl"

save_constraints

# set_property target_constrs_file "$project_path/src/constr/constrs_static_2/partial.xdc" [get_filesets constrs_static_2]
set_property target_constrs_file "$project_sources/constrs_static_2/imports/constrs_static_2/partial.xdc" [get_filesets constrs_static_2]

source -notrace "$project_path/tcl/help_generate_partial.tcl"

save_constraints


set_property target_constrs_file "$project_sources/constrs_static_2/imports/constrs_static_2/prohibits.xdc" [get_filesets constrs_static_2]

source -notrace "$project_path/tcl/help_generate_prohibits.tcl"

save_constraints


# set_property target_constrs_file "$project_path/src/constr/constrs_static_2/vivado.xdc" [get_filesets constrs_static_2]
set_property target_constrs_file "$project_sources/constrs_static_2/imports/constrs_static_2/vivado.xdc" [get_filesets constrs_static_2]

close_design


set_property constrset constrs_static_1 [get_runs impl_1]

# file mkdir $project_bitstreams

set flowfile [open [format "%s/misc_fw_flow.tcl" $project_generated_sources_tcl] "w+"]
puts $flowfile [format "set fw_flow_execute %d" [expr { $fw_flow_current + 1 } ]]
close $flowfile

set call_by_script 0