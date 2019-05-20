error "not usuable yet"

source -notrace [format "%s/tcl/settings_paths.tcl" [get_property DIRECTORY [current_project]]]
source -notrace [format "%s/tcl/settings_project.tcl" $project_path]

set fw_flow_current 8
global call_by_script
set call_by_script 1

if { ! [file exists [format "%s/tcl/misc_fw_flow.tcl" [get_property DIRECTORY [current_project]]]] } {
	error "flow control file misc_fw_flow.tcl not existent, call fw1_generate_filesets.tcl first"
}

source -notrace [format "%s/tcl/misc_fw_flow.tcl" [get_property DIRECTORY [current_project]]]

if { $fw_flow_execute != $fw_flow_current } {
	error "wrong call order of files, current call index is $fw_flow_current, expected call index is $fw_flow_execute"
}

file mkdir "$project_path/$project_name.sdk"
file copy -force "$project_path/$project_name.runs/impl_1/toplevel.sysdef" "$project_path/$project_name.sdk/toplevel.hdf"

set bifId [open [format "%s/%s.bif" $project_sources_sdk $project_sdk_name_project] "w+"]
puts $bifId "//arch = zynq; split = false; format = BIN"
puts $bifId "the_ROM_image:"
puts $bifId "{"
puts $bifId [format "\t\[bootloader\]%s/%s.sdk/%s/Release/%s.elf" $project_path $project_name $project_sdk_name_fsbl $project_sdk_name_project]
puts $bifId [format "\t%s/%s.sdk/%s/toplevel.bit" $project_path $project_name $project_sdk_name_hw]
puts $bifId [format "\t%s/%s.sdk/%s/Release/%s.elf" $project_path $project_name $project_sdk_name_hw $project_sdk_name_project $project_sdk_name_project]
puts $bifId "}"
close $bifId


set helperId [open [format "%s/%s" $project_sources_tcl "help_generate_sdk_projects.tcl"] "w+"]
puts $helperId [format "cd %s/%s.sdk" $project_path $project_name]
puts $helperId [format "setws %s/%s.sdk" $project_path $project_name]
puts $helperId "createhw -name toplevel_hw_platform_0 -hwspec toplevel.hdf"
puts $helperId ""
puts $helperId "createapp -name zybo_fsbl -app {Zynq FSBL} -proc ps7_cortexa9_0 -hwproject toplevel_hw_platform_0 -os standalone"
puts $helperId "configapp -app zybo_fsbl build-config release"
puts $helperId ""
puts $helperId [format "createapp -name %s -app {Empty Application} -proc ps7_cortexa9_0 -hwproject toplevel_hw_platform_0 -os standalone" $project_sdk_name_project]
puts $helperId [format "configapp -app %s build-config release" $project_sdk_name_project]
puts $helperId ""
puts $helperId [format "importsources -name %s -path \"%s\" -linker-script" $project_sdk_name_project $project_sources_sdk]
puts $helperId ""
puts $helperId [format "repo -set %s" $project_sources_sw_repo]
puts $helperId "repo -scan"
puts $helperId ""
puts $helperId [format "setlib -bsp %s_bsp -lib ah_lib" $project_sdk_name_project]
puts $helperId [format "setlib -bsp %s_bsp -lib lwip202" $project_sdk_name_project]
puts $helperId [format "setlib -bsp %s_bsp -lib xilffs" $project_sdk_name_project]
puts $helperId ""
puts $helperId [format "regenbsp -bsp %s_bsp" $project_sdk_name_project]
puts $helperId ""
puts $helperId [format "configbsp -bsp %s_bsp pcap true" $project_sdk_name_project]
puts $helperId [format "configbsp -bsp %s_bsp scugic true" $project_sdk_name_project]
puts $helperId [format "configbsp -bsp %s_bsp sd true" $project_sdk_name_project]
puts $helperId [format "configbsp -bsp %s_bsp xadc true" $project_sdk_name_project]
puts $helperId [format "configbsp -bsp %s_bsp gpio true" $project_sdk_name_project]
puts $helperId [format "configbsp -bsp %s_bsp tcpip true" $project_sdk_name_project]
puts $helperId [format "configbsp -bsp %s_bsp timer true" $project_sdk_name_project]
puts $helperId [format "configbsp -bsp %s_bsp uart true" $project_sdk_name_project]
puts $helperId ""
puts $helperId [format "configbsp -bsp %s_bsp mem_size 2097152" $project_sdk_name_project]
puts $helperId [format "configbsp -bsp %s_bsp memp_n_pbuf 8" $project_sdk_name_project]
puts $helperId [format "configbsp -bsp %s_bsp memp_n_tcp_pcb 2" $project_sdk_name_project]
puts $helperId [format "configbsp -bsp %s_bsp memp_n_tcp_pcb_listen 4096" $project_sdk_name_project]
puts $helperId [format "configbsp -bsp %s_bsp memp_n_tcp_seg 4096" $project_sdk_name_project]
puts $helperId [format "configbsp -bsp %s_bsp pbuf_pool_size 4096" $project_sdk_name_project]
puts $helperId [format "configbsp -bsp %s_bsp tcp_snd_buf 65535" $project_sdk_name_project]
puts $helperId [format "configbsp -bsp %s_bsp tcp_wnd 65535" $project_sdk_name_project]
puts $helperId [format "configbsp -bsp %s_bsp phy_link_speed CONFIG_LINKSPEED1000" $project_sdk_name_project]
puts $helperId [format "configbsp -bsp %s_bsp lwip_udp false" $project_sdk_name_project]
puts $helperId ""
# puts $helperId [format "configapp -app %s -set linker-misc -Wl,--start-group,-lxil,-llwip4,-lgcc,-lc,--end-group -Wl,--start-group,-lxilffs,-lxil,-lgcc,-lc,--end-group" $project_sdk_name_project]
puts $helperId [format "configapp -app %s -add {-std=c11}" $project_sdk_name_project]
puts $helperId [format "regenbsp -bsp %s_bsp" $project_sdk_name_project]
puts $helperId ""
puts $helperId "projects -clean"
puts $helperId "projects -build"
puts $helperId ""
puts $helperId [format "exec bootgen -image %s/%s.bif -arch zynq -w -o %s/BOOT.bin" $project_sources_sdk $project_sdk_name_project $project_bitstreams]
puts $helperId ""
close $helperId

exec xsdk -batch -source [format "%s/%s" $project_sources_tcl "help_generate_sdk_projects.tcl"]


set flowfile [open [format "%s/misc_fw_flow.tcl" $project_sources_tcl] "w+"]
puts $flowfile [format "set fw_flow_execute %d" [expr { $fw_flow_current + 1 } ]]
close $flowfile

set call_by_script 0