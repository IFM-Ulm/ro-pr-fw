global call_by_script
if { $call_by_script != 1 } {
	error "this script file is not intended to be run independently"
}

set ro_nets [get_nets * -hierarchical -filter {NAME =~ "*RoGen[*].puf2/*"}]
set_property is_route_fixed false $ro_nets

route_design -unroute -nets $ro_nets

set ro_luts [get_cells * -hierarchical -filter {NAME =~ "*RoGen[*].puf2/ro4LUT6_*"}]
set_property is_bel_fixed false $ro_luts

set_property is_loc_fixed false $ro_luts

reset_property LOCK_PINS $ro_luts

unplace_cell $ro_luts

reset_property -quiet ALLOW_COMBINATORIAL_LOOPS  [get_nets -hierarchical ro4_con[3]]
