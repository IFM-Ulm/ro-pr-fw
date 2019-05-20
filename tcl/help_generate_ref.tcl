global call_by_script
if { $call_by_script != 1 } {
	error "this script file is not intended to be run independently"
}

# lists all synergies of implementations, which only differ in their placement, but not ro type

set_property BEL D6LUT [get_cells ro_top_inst/RO_ref_inst/puf_ref/ro4LUT6_D]
set_property LOC [format "SLICE_X%dY%d" $coord_ref_X $coord_ref_Y] [get_cells ro_top_inst/RO_ref_inst/puf_ref/ro4LUT6_D]
set_property BEL C6LUT [get_cells ro_top_inst/RO_ref_inst/puf_ref/ro4LUT6_C]
set_property LOC [format "SLICE_X%dY%d" $coord_ref_X $coord_ref_Y] [get_cells ro_top_inst/RO_ref_inst/puf_ref/ro4LUT6_C]
set_property BEL B6LUT [get_cells ro_top_inst/RO_ref_inst/puf_ref/ro4LUT6_B]
set_property LOC [format "SLICE_X%dY%d" $coord_ref_X $coord_ref_Y] [get_cells ro_top_inst/RO_ref_inst/puf_ref/ro4LUT6_B]
set_property BEL A6LUT [get_cells ro_top_inst/RO_ref_inst/puf_ref/ro4LUT6_A]
set_property LOC [format "SLICE_X%dY%d" $coord_ref_X $coord_ref_Y] [get_cells ro_top_inst/RO_ref_inst/puf_ref/ro4LUT6_A]

set_property LOCK_PINS {I0:A1 I1:A2 I2:A3 I3:A4 I4:A5 I5:A6} [get_cells ro_top_inst/RO_ref_inst/puf_ref/ro4LUT6_D]
set_property LOCK_PINS {I0:A1 I1:A2 I2:A3 I3:A4 I4:A5 I5:A6} [get_cells ro_top_inst/RO_ref_inst/puf_ref/ro4LUT6_C]
set_property LOCK_PINS {I0:A1 I1:A2 I2:A3 I3:A4 I4:A5 I5:A6} [get_cells ro_top_inst/RO_ref_inst/puf_ref/ro4LUT6_B]
set_property LOCK_PINS {I0:A1 I1:A2 I2:A3 I3:A4 I4:A5 I5:A6} [get_cells ro_top_inst/RO_ref_inst/puf_ref/ro4LUT6_A]

set_property FIXED_ROUTE { { CLBLM_M_D CLBLM_LOGIC_OUTS15 IMUX_L31 CLBLM_M_C5 }  } [get_nets {ro_top_inst/RO_ref_inst/puf_ref/ro4_con[3]}]
set_property FIXED_ROUTE { { CLBLM_M_C CLBLM_LOGIC_OUTS14 IMUX_L12 CLBLM_M_B6 }  } [get_nets {ro_top_inst/RO_ref_inst/puf_ref/ro4_con[2]}]
set_property FIXED_ROUTE { { CLBLM_M_B CLBLM_LOGIC_OUTS13  { IMUX_L11 CLBLM_M_A4 }  IMUX_L43 CLBLM_M_D6 }  } [get_nets {ro_top_inst/RO_ref_inst/puf_ref/ro4_con[1]}]
set_property FIXED_ROUTE { { CLBLM_M_A CLBLM_LOGIC_OUTS12 IMUX_L40 CLBLM_M_D1 }  } [get_nets {ro_top_inst/RO_ref_inst/puf_ref/ro4_con[0]}]

set_property ALLOW_COMBINATORIAL_LOOPS true [get_nets {ro_top_inst/RO_ref_inst/puf_ref/ro4_con[3]}]

set_property PROHIBIT true [get_bels [format "SLICE_X%dY%d" $coord_ref_X $coord_ref_Y]/D5FF]
set_property PROHIBIT true [get_bels [format "SLICE_X%dY%d" $coord_ref_X $coord_ref_Y]/DFF]
set_property PROHIBIT true [get_bels [format "SLICE_X%dY%d" $coord_ref_X $coord_ref_Y]/C5FF]
set_property PROHIBIT true [get_bels [format "SLICE_X%dY%d" $coord_ref_X $coord_ref_Y]/CFF]
set_property PROHIBIT true [get_bels [format "SLICE_X%dY%d" $coord_ref_X $coord_ref_Y]/B5FF]
set_property PROHIBIT true [get_bels [format "SLICE_X%dY%d" $coord_ref_X $coord_ref_Y]/BFF]
set_property PROHIBIT true [get_bels [format "SLICE_X%dY%d" $coord_ref_X $coord_ref_Y]/A5FF]
set_property PROHIBIT true [get_bels [format "SLICE_X%dY%d" $coord_ref_X $coord_ref_Y]/AFF]
set_property PROHIBIT true [get_bels [format "SLICE_X%dY%d" $coord_ref_X $coord_ref_Y]/CARRY4]

set_property PROHIBIT true [get_sites [format "SLICE_X%dY%d" [expr {$coord_ref_X - 2}] [expr {$coord_ref_Y - 1}]]]
set_property PROHIBIT true [get_sites [format "SLICE_X%dY%d" [expr {$coord_ref_X - 1}] [expr {$coord_ref_Y - 1}]]]
set_property PROHIBIT true [get_sites [format "SLICE_X%dY%d" [expr {$coord_ref_X - 0}] [expr {$coord_ref_Y - 1}]]]
set_property PROHIBIT true [get_sites [format "SLICE_X%dY%d" [expr {$coord_ref_X + 1}] [expr {$coord_ref_Y - 1}]]]
set_property PROHIBIT true [get_sites [format "SLICE_X%dY%d" [expr {$coord_ref_X + 2}] [expr {$coord_ref_Y - 1}]]]
set_property PROHIBIT true [get_sites [format "SLICE_X%dY%d" [expr {$coord_ref_X + 3}] [expr {$coord_ref_Y - 1}]]]

set_property PROHIBIT true [get_sites [format "SLICE_X%dY%d" [expr {$coord_ref_X - 2}] [expr {$coord_ref_Y + 0}]]]
set_property PROHIBIT true [get_sites [format "SLICE_X%dY%d" [expr {$coord_ref_X - 1}] [expr {$coord_ref_Y + 0}]]]
set_property PROHIBIT true [get_sites [format "SLICE_X%dY%d" [expr {$coord_ref_X + 1}] [expr {$coord_ref_Y + 0}]]]
set_property PROHIBIT true [get_sites [format "SLICE_X%dY%d" [expr {$coord_ref_X + 2}] [expr {$coord_ref_Y + 0}]]]
set_property PROHIBIT true [get_sites [format "SLICE_X%dY%d" [expr {$coord_ref_X + 3}] [expr {$coord_ref_Y + 0}]]]

set_property PROHIBIT true [get_sites [format "SLICE_X%dY%d" [expr {$coord_ref_X - 2}] [expr {$coord_ref_Y + 1}]]]
set_property PROHIBIT true [get_sites [format "SLICE_X%dY%d" [expr {$coord_ref_X - 1}] [expr {$coord_ref_Y + 1}]]]
set_property PROHIBIT true [get_sites [format "SLICE_X%dY%d" [expr {$coord_ref_X - 0}] [expr {$coord_ref_Y + 1}]]]
set_property PROHIBIT true [get_sites [format "SLICE_X%dY%d" [expr {$coord_ref_X + 1}] [expr {$coord_ref_Y + 1}]]]
set_property PROHIBIT true [get_sites [format "SLICE_X%dY%d" [expr {$coord_ref_X + 2}] [expr {$coord_ref_Y + 1}]]]
set_property PROHIBIT true [get_sites [format "SLICE_X%dY%d" [expr {$coord_ref_X + 3}] [expr {$coord_ref_Y + 1}]]]

