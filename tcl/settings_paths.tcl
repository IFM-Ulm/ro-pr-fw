# call:
# set project_path [get_property DIRECTORY [current_project]]
# source -notrace [format "%s/tcl/get_paths.tcl" $project_path]

set project_path [get_property DIRECTORY [current_project]]
set project_name [current_project]
set project_sources [format "%s/%s.srcs" $project_path $project_name]
set project_import_sources [format "%s/src" $project_path]
set project_import_sources_hdl [format "%s/hdl" $project_import_sources]
set project_import_sources_constr [format "%s/constr" $project_import_sources]
set project_import_sources_constr_synth [format "%s/constrs_synth" $project_import_sources_constr]
set project_import_sources_constr_static1 [format "%s/constrs_static_1" $project_import_sources_constr]
set project_import_sources_constr_static2 [format "%s/constrs_static_2" $project_import_sources_constr]
set project_import_sources_constr_partial [format "%s/constrs_partial" $project_import_sources_constr]
set project_import_sources_bd [format "%s/bd" $project_import_sources]
set project_sources_tcl [format "%s/tcl" $project_path]
set project_sources_sdk [format "%s/sdk" $project_path]
set project_sources_sw_repo [format "%s/sw_repo" $project_path]
set project_bitstreams [format "%s/bitstreams" $project_path]
set project_sdk_name_project "zynq_fw_project"
set project_sdk_name_hw "zynq_fw_toplevel_hw"
set project_sdk_name_fsbl "zynq_fw_fsbl"