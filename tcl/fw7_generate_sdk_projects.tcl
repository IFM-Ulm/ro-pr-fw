source -notrace [format "%s/settings_paths.tcl" [file dirname [file normalize [info script]]]]
source -notrace [format "%s/settings_project.tcl" $project_sources_tcl]
source -notrace [format "%s/settings_impl.tcl" $project_generated_sources_tcl]

set fw_flow_current 7
global call_by_script
set call_by_script 1

if { ! [file exists [format "%s/misc_fw_flow.tcl" $project_generated_sources_tcl]] } {
	error "flow control file misc_fw_flow.tcl not existent, call fw1_generate_filesets.tcl first"
}

source -notrace [format "%s/misc_fw_flow.tcl" $project_generated_sources_tcl]

if { $fw_flow_execute != $fw_flow_current } {
	error "wrong call order of files, current call index is $fw_flow_current, expected call index is $fw_flow_execute"
}


file delete -force "$project_path/$project_name.sdk"
after 1000
file mkdir "$project_path/$project_name.sdk"
file copy -force "$project_path/$project_name.runs/impl_1/toplevel.sysdef" "$project_path/$project_name.sdk/toplevel.hdf"

set comheaderId [open [format "%s/fw_com_generated.h" $project_generated_sources_sdk] "w+"]
puts $comheaderId "#ifndef SRC_FW_COM_GENERATED_H_"
puts $comheaderId "#define SRC_FW_COM_GENERATED_H_"
puts $comheaderId ""
puts $comheaderId "#define IMPL_COM_TCP 1"
puts $comheaderId "#define IMPL_COM_UART 2"
puts $comheaderId ""
if { $impl_com == "tcp" } {
	puts $comheaderId "#define IMPL_COM IMPL_COM_TCP"
	puts "generating implementation: tcp"
}
if { $impl_com == "uart" } {
	puts $comheaderId "#define IMPL_COM IMPL_COM_UART"
	puts "generating implementation: uart"
}
puts $comheaderId ""
puts $comheaderId "#endif"
puts $comheaderId ""
close $comheaderId

set bifId [open [format "%s/%s.bif" $project_generated_sources_sdk $project_sdk_name_project] "w+"]
puts $bifId "//arch = zynq; split = false; format = BIN"
puts $bifId "the_ROM_image:"
puts $bifId "{"
puts $bifId [format "\t\[bootloader\]%s/%s.sdk/%s/Release/%s.elf" $project_path $project_name $project_sdk_name_fsbl $project_sdk_name_fsbl]
puts $bifId [format "\t%s/%s.sdk/%s/toplevel.bit" $project_path $project_name $project_sdk_name_hw]
puts $bifId [format "\t%s/%s.sdk/%s/Release/%s.elf" $project_path $project_name $project_sdk_name_project $project_sdk_name_project]
puts $bifId "}"
close $bifId

set helperId [open [format "%s/%s" $project_generated_sources_tcl "help_generate_sdk_projects.tcl"] "w+"]
puts $helperId [format "cd %s/%s.sdk" $project_path $project_name]
puts $helperId ""
puts $helperId [format "setws %s/%s.sdk" $project_path $project_name]
puts $helperId [format "createhw -name %s -hwspec toplevel.hdf" $project_sdk_name_hw]
puts $helperId ""

puts $helperId [format "repo -set %s" $project_sources_sw_repo]
puts $helperId "repo -scan"
puts $helperId ""
puts $helperId [format "createbsp -name %s -proc ps7_cortexa9_0 -hwproject %s -os standalone" $project_sdk_name_bsp $project_sdk_name_hw]
if { $impl_com == "tcp" } {
	puts $helperId [format "setlib -bsp %s -lib lwip202" $project_sdk_name_bsp]
	puts $helperId [format "setlib -bsp %s -lib xilffs" $project_sdk_name_bsp]
	puts $helperId [format "setlib -bsp %s -lib ah_lib" $project_sdk_name_bsp]
	puts $helperId ""
	puts $helperId [format "configbsp -bsp %s pcap true" $project_sdk_name_bsp]
	puts $helperId [format "configbsp -bsp %s scugic true" $project_sdk_name_bsp]
	puts $helperId [format "configbsp -bsp %s sd true" $project_sdk_name_bsp]
	puts $helperId [format "configbsp -bsp %s xadc true" $project_sdk_name_bsp]
	puts $helperId [format "configbsp -bsp %s gpio true" $project_sdk_name_bsp]
	puts $helperId [format "configbsp -bsp %s tcpip true" $project_sdk_name_bsp]
	puts $helperId [format "configbsp -bsp %s timer true" $project_sdk_name_bsp]
	puts $helperId [format "configbsp -bsp %s uart false" $project_sdk_name_bsp]
	puts $helperId ""
	puts $helperId [format "configbsp -bsp %s mem_size 4194304" $project_sdk_name_bsp]
	puts $helperId [format "configbsp -bsp %s memp_n_pbuf 2048" $project_sdk_name_bsp]
	puts $helperId [format "configbsp -bsp %s memp_n_tcp_pcb 32" $project_sdk_name_bsp]
	puts $helperId [format "configbsp -bsp %s memp_n_tcp_pcb_listen 8" $project_sdk_name_bsp]
	puts $helperId [format "configbsp -bsp %s memp_n_tcp_seg 16384" $project_sdk_name_bsp]
	puts $helperId [format "configbsp -bsp %s pbuf_pool_size 16384" $project_sdk_name_bsp]
	puts $helperId [format "configbsp -bsp %s tcp_snd_buf 65535" $project_sdk_name_bsp]
	puts $helperId [format "configbsp -bsp %s tcp_wnd 65535" $project_sdk_name_bsp]
	puts $helperId [format "configbsp -bsp %s phy_link_speed CONFIG_LINKSPEED1000" $project_sdk_name_bsp]
	puts $helperId [format "configbsp -bsp %s lwip_udp false" $project_sdk_name_bsp]
}
if { $impl_com == "uart" } {
	puts $helperId [format "setlib -bsp %s -lib xilffs" $project_sdk_name_bsp]
	puts $helperId [format "setlib -bsp %s -lib ah_lib" $project_sdk_name_bsp]
	puts $helperId ""
	puts $helperId [format "configbsp -bsp %s pcap true" $project_sdk_name_bsp]
	puts $helperId [format "configbsp -bsp %s scugic true" $project_sdk_name_bsp]
	puts $helperId [format "configbsp -bsp %s sd true" $project_sdk_name_bsp]
	puts $helperId [format "configbsp -bsp %s xadc true" $project_sdk_name_bsp]
	puts $helperId [format "configbsp -bsp %s gpio true" $project_sdk_name_bsp]
	puts $helperId [format "configbsp -bsp %s tcpip false" $project_sdk_name_bsp]
	puts $helperId [format "configbsp -bsp %s timer true" $project_sdk_name_bsp]
	puts $helperId [format "configbsp -bsp %s uart true" $project_sdk_name_bsp]
}
puts $helperId ""
puts $helperId [format "updatemss -mss %s/system.mss" $project_sdk_name_bsp]
puts $helperId ""
puts $helperId "after 5000"
puts $helperId [format "regenbsp -bsp %s" $project_sdk_name_bsp]
puts $helperId ""
puts $helperId [format "createapp -name %s -app {Empty Application} -proc ps7_cortexa9_0 -bsp %s -hwproject %s -os standalone" $project_sdk_name_project $project_sdk_name_bsp $project_sdk_name_hw]
puts $helperId [format "configapp -app %s build-config release" $project_sdk_name_project]
puts $helperId [format "configapp -app %s -add compiler-misc {-std=c11}" $project_sdk_name_project]
puts $helperId ""
puts $helperId [format "importsources -name %s -path \"%s\" -linker-script" $project_sdk_name_project $project_sources_sdk]
puts $helperId [format "importsources -name %s -path \"%s\"" $project_sdk_name_project $project_generated_sources_sdk]
puts $helperId ""
puts $helperId [format "createapp -name %s -app {Zynq FSBL} -proc ps7_cortexa9_0 -hwproject %s -os standalone" $project_sdk_name_fsbl $project_sdk_name_hw]
puts $helperId [format "configapp -app %s build-config release" $project_sdk_name_fsbl]

puts $helperId "projects -build"
puts $helperId ""
puts $helperId [format "exec bootgen -image %s/%s.bif -arch zynq -w -o %s/BOOT.bin" $project_generated_sources_sdk $project_sdk_name_project $project_bitstreams]
puts $helperId ""
close $helperId

if { $impl_com == "tcp" } {

	# generate the file ip.csv, which has to be placed on the SD-Card, when using the tcp communication software 
	set ipId [open [format "%s/ip.csv" $project_generated_sources_sdk] "w+"]
	
	# generate MAC address, should be varied for different boards when used in parallel
	puts $ipId "00,0A,35,00,01,06"
	
	# generate IP address, should be varied for different boards when used in parallel
	puts $ipId "192,168,0,1"
	
	# generate sub-net mask
	puts $ipId "255,255,255,0"
	
	# generate IP address of standard gateway
	puts $ipId "192,168,0,100"
	
	# generate TCP communication port
	puts $ipId "7"
	
	close $ipId

	puts "generated tcp settings file ip.csv"
}

exec xsdk -batch -source [format "%s/%s" $project_generated_sources_tcl "help_generate_sdk_projects.tcl"]

set flowfile [open [format "%s/misc_fw_flow.tcl" $project_generated_sources_tcl] "w+"]
puts $flowfile [format "set fw_flow_execute %d" [expr { $fw_flow_current + 1 } ]]
close $flowfile

puts "compilation successful"

set call_by_script 0