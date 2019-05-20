
source -notrace [format "%s/tcl/settings_paths.tcl" [get_property DIRECTORY [current_project]]]

set_property constrset constrs_synth [get_runs synth_1]
set_property constrset constrs_static_1 [get_runs impl_1]
set_property constrset constrs_static_2 [get_runs impl_2]

delete_runs -quiet [get_runs *child_impl_*_constr_*]


set fs [get_filesets constr_1_*]
foreach fs_c $fs {
	delete_fileset $fs_c
	file delete -force "$project_sources/$fs_c"
}

set fs [get_filesets constr_2_*]
foreach fs_c $fs {
	delete_fileset $fs_c
	file delete -force "$project_sources/$fs_c"
}