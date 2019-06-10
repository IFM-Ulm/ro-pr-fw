global call_by_script
if { $call_by_script != 1 } {
	error "this script file is not intended to be run independently"
}

proc pr_create_constrset {pr_X_start pr_Y_start pr_X_max pr_Y_max} {
	
	source -notrace [format "%s/settings_paths.tcl" [file dirname [file normalize [info script]]]]
	source -notrace [format "%s/settings_project.tcl" $project_sources_tcl]
	source -notrace [format "%s/settings_ro.tcl" $project_sources_tcl]
	
	global DEBUG
	global fast_approach
	
	global constrset_name
	global impl_parent
	global impl_ro
	global toplevel_prefix
	global run_counter
	
	global pr_X
	global pr_Y
	global pr_X_offset
	global pr_Y_offset
	global pr_X_shift
	global pr_Y_shift
	
	global pr_Y_SLC_offset
	global pr_X_SLC_offset
	
	global pr_stop
	global pr_counter
	global ro_number
		
	global pr_module
	
	global lst_prohibits_X

	set pr_route_tcl [format "%s/%s" $project_sources_tcl $pr_route_file]
	
	puts "sourcing $pr_route_tcl"
	source -notrace $pr_route_tcl
	

	set file_ident [format "t%si1r%02d" $toplevel_prefix $run_counter]
	
	set constrset_path [format "%s/%s" $project_generated_sources_constr $constrset_name]
	set constrset_file [format "%s/%s_inst.xdc" $constrset_path $constrset_name]

	if { $DEBUG < 2 } {

		if { [string match -nocase [format "*child_%s_%s*" $impl_parent $constrset_name] [get_runs]] } {
			delete_runs [format "child_%s_%s" $impl_parent $constrset_name]
		}

		if { [string match -nocase [format "*%s*" $constrset_name] [get_filesets]] } {
			delete_fileset $constrset_name
			file delete -force [format "%s/%s" $project_sources $constrset_name]
		}
		
		if { ! $fast_approach } {
			create_fileset -constrset $constrset_name
			file mkdir $constrset_path
			close [ open $constrset_file w ]
			add_files -fileset $constrset_name $constrset_file

			set_property used_in_synthesis false [get_files $constrset_file]
			set_property used_in_implementation true [get_files $constrset_file]
				
			set_property constrset $constrset_name [get_runs synth_1]
			set_property constrset $constrset_name [get_runs impl_1]
			set_property constrset $constrset_name [get_runs impl_2]
		}

		set run_name [format "child_%s_%s" $impl_parent $constrset_name]		
	}
	
	set csvId [open [format "%s/config.csv" $project_bitstreams] "a+"]
	
	if { $DEBUG < 2 } {
		
		if { ! $fast_approach } {
			open_run -name synth_1 -pr_config [current_pr_configuration] synth_1
			current_instance "ro_top_inst/PR_module_inst1"
		
			set_property constrset $constrset_name [get_runs impl_1]
			set_property constrset $constrset_name [get_runs impl_2]
			set_property target_constrs_file $constrset_file [get_filesets $constrset_name]
		}
	}

	
	# route PR_module_1	

	
	source -notrace [format "%s/%s" $project_sources_tcl $pr_undo_file]
	
	set placed_ROs 0
	
	set break_loop 0
	if { $pr_stop == 0 } {

		for { set index 0 } {$index < $ro_number} {incr index} {
				
			while { [lsearch $lst_prohibits_X $pr_X] > -1 } {
				set pr_X [expr {$pr_X + $pr_X_shift}]
			}
			
			if { $pr_X <= $pr_X_max } {
				if { $DEBUG < 2 } {
					set instance_name [pr_set_instance_name $index $impl_ro]
					puts "placing instance $pr_counter ($index, $instance_name) of $impl_parent at X/Y: $pr_X / $pr_Y"
					pr_route_puf $instance_name $pr_X $pr_Y
				}
				
				incr pr_counter 1
				set placed_ROs [expr {$placed_ROs + 1}]
				puts $csvId [format "%s,%s,%d,%d,%d,1" $constrset_name $file_ident $index $pr_X $pr_Y]
			} else {
				puts "skipping instance $index $instance_name at X/Y: $pr_X / $pr_Y"
				set pr_Y $pr_Y_max
			}
			
			set pr_Y [expr {$pr_Y + $pr_Y_shift}]
			if { $pr_Y > $pr_Y_max } {

				set pr_X [expr {$pr_X + $pr_X_shift}]
				set pr_Y [expr {$pr_Y_start + $pr_Y_offset}]
				if { $pr_X > $pr_X_max } {

					set pr_Y_offset [expr {$pr_Y_offset + $pr_Y_SLC_offset}]
					if { $pr_Y_offset >= $pr_Y_shift } {

						set pr_Y_offset 0
						set pr_X_offset [expr {$pr_X_offset + $pr_X_SLC_offset}]
						
						if { $pr_X_offset >= $pr_X_shift } {
							set pr_stop 1
						}
					}

					set break_loop 1
					break
				}
			}

		}
	}

	set misplaced_ROs [expr {$ro_number - $placed_ROs}]
		
	if { $break_loop == 1 } {
		set pr_X [expr {$pr_X_start + $pr_X_offset}]
		set pr_Y [expr {$pr_Y_start + $pr_Y_offset}]
	}
	
	if { $misplaced_ROs > 0 } {
		
		puts "starting misplace"
		
		# place unused ROs most-left				
		set misplace_X $pr_X_start
		set misplace_Y $pr_Y_start
		
		for { set index $placed_ROs } {$index < $ro_number} {incr index} {
			
			while { [lsearch $lst_prohibits_X $misplace_X] > -1 } {
				set misplace_X [expr {$misplace_X + $pr_X_shift}]
			}
			
			if { $DEBUG < 2 } {
				set instance_name [pr_set_instance_name $index $impl_ro]
				puts "(mis)placing instance $index ($instance_name) of $impl_parent at X/Y: $misplace_X / $misplace_Y"
				pr_route_puf $instance_name $misplace_X $misplace_Y
			}
			
			puts $csvId [format "%s,%s,%d,%d,%d,0" $constrset_name $file_ident $index $misplace_X $misplace_Y]
						
			set misplace_Y [expr {$misplace_Y + 1}]
		}
	}


	if { $DEBUG < 2 } {
		if { ! $fast_approach } {
			save_constraints
		} else {
		
						
			save_constraints_as -dir $constrset_path -target_constrs_file [format "%s_inst.xdc" $constrset_name] $constrset_name
			
			set_property used_in_synthesis false [get_files $constrset_file]
			set_property used_in_implementation true [get_files $constrset_file]

			remove_files -fileset $constrset_name [get_files -of_objects [get_filesets $constrset_name] -filter [format "NAME !~ *%s_inst.xdc" $constrset_name]]
		}
	}
				
	if { $DEBUG < 2 } {
	
		create_run $run_name -parent_run $impl_parent -constrset $constrset_name -flow {Vivado Implementation 2017} -pr_config PR_config
		# set_property STRATEGY custom_no_opt [get_runs $run_name]
		
		# the following script contains a single, out-dated line: set_property SEVERITY {Warning} [get_drc_checks LUTLP-1]
		# set_property STEPS.WRITE_BITSTREAM.TCL.PRE [format "%s/ignoreCombLoops.tcl" $project_sources_tcl] [get_runs $run_name]
		set_property GEN_FULL_BITSTREAM 0 [get_runs $run_name]
		set_property APPLY_CONSTRSET 1 [get_runs $run_name]
	}
		
	close $csvId
	

	if { $DEBUG < 2 } {
		if { ! $fast_approach } {
			close_design
		}
	}

	
}
