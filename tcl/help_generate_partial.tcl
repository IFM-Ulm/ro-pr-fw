global call_by_script
if { $call_by_script != 1 } {
	error "this script file is not intended to be run independently"
}

create_pblock pblock_PR_module_inst1
add_cells_to_pblock [get_pblocks pblock_PR_module_inst1] [get_cells -quiet [list ro_top_inst/PR_module_inst1]]

resize_pblock [get_pblocks pblock_PR_module_inst1] -add [format "SLICE_X%dY%d" $coord_SLICE_partial_X_start $coord_SLICE_partial_Y_start]:[format "SLICE_X%dY%d" $coord_SLICE_partial_X_end $coord_SLICE_partial_Y_end]
resize_pblock [get_pblocks pblock_PR_module_inst1] -add [format "DSP48_X%dY%d" $coord_DSP48_partial_X_start $coord_DSP48_partial_Y_start]:[format "DSP48_X%dY%d" $coord_DSP48_partial_X_end $coord_DSP48_partial_Y_end]
resize_pblock [get_pblocks pblock_PR_module_inst1] -add [format "RAMB18_X%dY%d" $coord_RAMB18_partial_X_start $coord_RAMB18_partial_Y_start]:[format "RAMB18_X%dY%d" $coord_RAMB18_partial_X_end $coord_RAMB18_partial_Y_end]
resize_pblock [get_pblocks pblock_PR_module_inst1] -add [format "RAMB36_X%dY%d" $coord_RAMB36_partial_X_start $coord_RAMB36_partial_Y_start]:[format "RAMB36_X%dY%d" $coord_RAMB36_partial_X_end $coord_RAMB36_partial_Y_end]

set_property RESET_AFTER_RECONFIG true [get_pblocks pblock_PR_module_inst1]
set_property SNAPPING_MODE ON [get_pblocks pblock_PR_module_inst1]