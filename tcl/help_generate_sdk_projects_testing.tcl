
# # in vivado:
# file copy -force "$project_path/$project_name.runs/impl_1/toplevel.sysdef" "$project_path/$project_name.sdk/toplevel.hdf"
#  xsdk -batch -source test.tcl 
# exec xsdk -workspace "$project_path/$project_name.sdk" -hwspec "$project_path/$project_name.sdk/toplevel.hdf"

# # script content:
cd D:/FPGA_PUFs/RO/test_zybo/test_zybo.sdk

createhw -name toplevel_hw_platform_0 -hwspec toplevel.hdf

createapp -name zybo_fsbl -app {Zynq FSBL} -proc ps7_cortexa9_0 -hwproject toplevel_hw_platform_0 -os standalone
configapp -app zybo_fsbl build-config release

createapp -name test_project -app {Empty Application} -proc ps7_cortexa9_0 -hwproject toplevel_hw_platform_0 -os standalone
configapp -app test_project build-config release

importsources -name test_project -path "D:/FPGA_PUFs/RO/test_zybo/sdk" -linker-script

repo -set D:/FPGA_PUFs/RO/test_zybo/sw_repo
repo -scan

setlib -bsp test_project_bsp -lib ah_lib
setlib -bsp test_project_bsp -lib lwip202
setlib -bsp test_project_bsp -lib xilffs

regenbsp -bsp test_project_bsp

configbsp -bsp test_project_bsp pcap true
configbsp -bsp test_project_bsp scugic true
configbsp -bsp test_project_bsp sd true
configbsp -bsp test_project_bsp xadc true
configbsp -bsp test_project_bsp gpio true
configbsp -bsp test_project_bsp tcpip true
configbsp -bsp test_project_bsp timer true
configbsp -bsp test_project_bsp uart true

configbsp -bsp test_project_bsp mem_size 2097152
configbsp -bsp test_project_bsp memp_n_pbuf 8
configbsp -bsp test_project_bsp memp_n_tcp_pcb 2
configbsp -bsp test_project_bsp memp_n_tcp_pcb_listen 4096
configbsp -bsp test_project_bsp memp_n_tcp_seg 4096
configbsp -bsp test_project_bsp pbuf_pool_size 4096
configbsp -bsp test_project_bsp tcp_snd_buf 65535
configbsp -bsp test_project_bsp tcp_wnd 65535
configbsp -bsp test_project_bsp phy_link_speed CONFIG_LINKSPEED1000
configbsp -bsp test_project_bsp lwip_udp false

regenbsp -bsp test_project_bsp

projects -clean
projects -build -type bsp
projects -build -type app

# //arch = zynq; split = false; format = BIN
# the_ROM_image:
# {
	# [bootloader]D:\FPGA_PUFs\RO\test_zybo\test_zybo.sdk\zybo_fsbl\Release\zybo_fsbl.elf
	# D:\FPGA_PUFs\RO\test_zybo\test_zybo.sdk\toplevel_hw_platform_0\toplevel.bit
	# D:\FPGA_PUFs\RO\test_zybo\test_zybo.sdk\test_project\Release\test_project.elf
# }

exec bootgen -image D:/FPGA_PUFs/RO/RO_PR/sdk/test_project.bif -arch zynq -w -o D:/FPGA_PUFs/RO/test_zybo/bitstreams/BOOT.bin
