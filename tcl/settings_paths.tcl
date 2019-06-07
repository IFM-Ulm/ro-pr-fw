set script_path [file dirname [file normalize [info script]]]

set project_path [get_property DIRECTORY [current_project]]

set project_name [current_project]
set project_sources [format "%s/%s.srcs" $project_path $project_name]
set project_sources_bd [format "%s/sources_1/bd/system" $project_sources]
set project_sources_constr_static_1 [format "%s/constrs_static_1/imports/constrs_static_1" $project_sources]
set project_sources_constr_static_2 [format "%s/constrs_static_1/imports/constrs_static_2" $project_sources]

set project_import_sources [format "%s/src" $project_path]
set project_import_sources_hdl [format "%s/hdl" $project_import_sources]
set project_import_sources_repo [format "%s/ip_repo" $project_import_sources]
set project_import_sources_constr [format "%s/constr" $project_import_sources]
set project_import_sources_constr_synth [format "%s/constrs_synth" $project_import_sources_constr]
set project_import_sources_constr_static1 [format "%s/constrs_static_1" $project_import_sources_constr]
set project_import_sources_constr_static2 [format "%s/constrs_static_2" $project_import_sources_constr]
set project_import_sources_constr_partial [format "%s/constrs_partial" $project_import_sources_constr]
set project_import_sources_bd [format "%s/bd" $project_import_sources]

set project_sources_tcl [format "%s/tcl" $script_path]
set project_sources_sdk [format "%s/sdk" $script_path]
set project_sources_sw_repo [format "%s/sw_repo" $script_path]

set project_generated_sources [format "%s/generated" $project_path]
file mkdir $project_generated_sources
set project_bitstreams [format "%s/bitstreams" $project_generated_sources]
file mkdir $project_bitstreams
set project_generated_sources_constr [format "%s/constr" $project_generated_sources]
file mkdir $project_generated_sources_constr
set project_generated_sources_sdk [format "%s/sdk" $project_generated_sources]
file mkdir $project_generated_sources_sdk
set project_generated_sources_tcl [format "%s/tcl" $project_generated_sources]
file mkdir $project_generated_sources_tcl

set project_sdk_name $project_name
set project_sdk_name_project [format "%s_app" $project_sdk_name]
set project_sdk_name_hw [format "%s_hw" $project_sdk_name]
set project_sdk_name_bsp [format "%s_bsp" $project_sdk_name]
set project_sdk_name_fsbl [format "%s_fsbl" $project_sdk_name]


