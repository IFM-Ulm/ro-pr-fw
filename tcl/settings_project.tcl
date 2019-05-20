set project_part [get_property PART [current_project]]
puts "found part is $project_part"

if { $project_part == "xc7z010clg400-1" } {
		
	set coord_ref1_X 28
	set coord_ref1_Y 36

	set coord_SLICE_partial1_X_start 0
	set coord_SLICE_partial1_Y_start 0
	set coord_SLICE_partial1_X_end 21
	set coord_SLICE_partial1_Y_end 99

	set coord_DSP48_partial1_X_start 0
	set coord_DSP48_partial1_Y_start 0
	set coord_DSP48_partial1_X_end 0
	set coord_DSP48_partial1_Y_end 39
	
	set coord_RAMB18_partial1_X_start 0
	set coord_RAMB18_partial1_Y_start 0
	set coord_RAMB18_partial1_X_end 0
	set coord_RAMB18_partial1_Y_end 39
	
	set coord_RAMB36_partial1_X_start 0
	set coord_RAMB36_partial1_Y_start 0
	set coord_RAMB36_partial1_X_end 0
	set coord_RAMB36_partial1_Y_end 19

	set lst_partial1_areas_X_start [list 0 ]
	set lst_partial1_areas_X_end [list 21 ]
	set lst_partial1_areas_Y_start [list 0 ]
	set lst_partial1_areas_Y_end [list 99 ]
	
	set lst_prohibits1_X [list 0 1 14 15 20 21]
	set lst_prohibits1_Y_start [list 0 0 0 0 0 0 ]
	set lst_prohibits1_Y_end [list 99 99 99 99 99 99 ]
	
	
	set coord_ref2_X 16
	set coord_ref2_Y 36

	set coord_SLICE_partial2_X_start 22
	set coord_SLICE_partial2_Y_start 0
	set coord_SLICE_partial2_X_end 43
	set coord_SLICE_partial2_Y_end 99

	set coord_DSP48_partial2_X_start 1
	set coord_DSP48_partial2_Y_start 0
	set coord_DSP48_partial2_X_end 1
	set coord_DSP48_partial2_Y_end 39
	
	set coord_RAMB18_partial2_X_start 1
	set coord_RAMB18_partial2_Y_start 0
	set coord_RAMB18_partial2_X_end 2
	set coord_RAMB18_partial2_Y_end 39
	
	set coord_RAMB36_partial2_X_start 1
	set coord_RAMB36_partial2_Y_start 0
	set coord_RAMB36_partial2_X_end 2
	set coord_RAMB36_partial2_Y_end 19

	set lst_partial2_areas_X_start [list 22 ]
	set lst_partial2_areas_X_end [list 43 ]
	set lst_partial2_areas_Y_start [list 0 ]
	set lst_partial2_areas_Y_end [list 99 ]
	
	set lst_prohibits2_X [list ]
	set lst_prohibits2_Y_start [list ]
	set lst_prohibits2_Y_end [list ]

} elseif { $project_part == "xc7z020clg400-1" || $project_part == "xc7z020clg484-1" } {

	set coord_ref1_X 86
	set coord_ref1_Y 40

	set coord_SLICE_partial1_X_start 0
	set coord_SLICE_partial1_Y_start 0
	set coord_SLICE_partial1_X_end 49
	set coord_SLICE_partial1_Y_end 149

	set coord_DSP48_partial1_X_start 0
	set coord_DSP48_partial1_Y_start 0
	set coord_DSP48_partial1_X_end 2
	set coord_DSP48_partial1_Y_end 59
	
	set coord_RAMB18_partial1_X_start 0
	set coord_RAMB18_partial1_Y_start 0
	set coord_RAMB18_partial1_X_end 2
	set coord_RAMB18_partial1_Y_end 59
	
	set coord_RAMB36_partial1_X_start 0
	set coord_RAMB36_partial1_Y_start 0
	set coord_RAMB36_partial1_X_end 2
	set coord_RAMB36_partial1_Y_end 9
	
	set lst_partial1_areas_X_start [list 0 26 ]
	set lst_partial1_areas_X_end [list 49 49 ]
	set lst_partial1_areas_Y_start [list 0 50 ]
	set lst_partial1_areas_Y_end [list 49 149 ]
	
	set lst_prohibits1_X [list 26 27 48 49 ]
	set lst_prohibits1_Y_start [list 50 50 0 0 ]
	set lst_prohibits1_Y_end [list 149 149 149 149 ]
	
	
	set coord_ref2_X 12
	set coord_ref2_Y 40

	set coord_SLICE_partial2_X_start 50
	set coord_SLICE_partial2_Y_start 0
	set coord_SLICE_partial2_X_end 113
	set coord_SLICE_partial2_Y_end 149
	
	set coord_DSP48_partial2_X_start 3
	set coord_DSP48_partial2_Y_start 0
	set coord_DSP48_partial2_X_end 4
	set coord_DSP48_partial2_Y_end 59
	
	set coord_RAMB18_partial2_X_start 3
	set coord_RAMB18_partial2_Y_start 0
	set coord_RAMB18_partial2_X_end 5
	set coord_RAMB18_partial2_Y_end 59
	
	set coord_RAMB36_partial2_X_start 3
	set coord_RAMB36_partial2_Y_start 0
	set coord_RAMB36_partial2_X_end 5
	set coord_RAMB36_partial2_Y_end 29
	
	set lst_partial2_areas_X_start [list 50 68 80 ]
	set lst_partial2_areas_X_end [list 67 79 113 ]
	set lst_partial2_areas_Y_start [list 0 0 0 ]
	set lst_partial2_areas_Y_end [list 149 49 149 ]
	
	
	set lst_prohibits2_X [list 80 81]
	set lst_prohibits2_Y_start [list 50 50 ]
	set lst_prohibits2_Y_end [list 149 149 ]
	
} else {
	error "unknown device"
}
