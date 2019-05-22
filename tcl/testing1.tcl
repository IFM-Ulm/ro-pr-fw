cd D:/FPGA_PUFs/RO/test_zybo/test_zybo.sdk
setws D:/FPGA_PUFs/RO/test_zybo/test_zybo.sdk



createhw -name zynq_fw_hw_platform -hwspec toplevel.hdf

createapp -name zybo_fsbl -app {Zynq FSBL} -proc ps7_cortexa9_0 -hwproject zynq_fw_hw_platform -os standalone
configapp -app zybo_fsbl build-config release
repo -set D:/FPGA_PUFs/RO/test_zybo/sw_repo
repo -scan

createbsp -name zynq_fw_bsp -proc ps7_cortexa9_0 -hwproject zynq_fw_hw_platform -os standalone
setlib -bsp zynq_fw_bsp -lib lwip202
setlib -bsp zynq_fw_bsp -lib xilffs
setlib -bsp zynq_fw_bsp -lib ah_lib

configbsp -bsp zynq_fw_bsp pcap true
configbsp -bsp zynq_fw_bsp scugic true
configbsp -bsp zynq_fw_bsp sd true
configbsp -bsp zynq_fw_bsp xadc true
configbsp -bsp zynq_fw_bsp gpio true
configbsp -bsp zynq_fw_bsp tcpip true
configbsp -bsp zynq_fw_bsp timer true
configbsp -bsp zynq_fw_bsp uart true

configbsp -bsp zynq_fw_bsp mem_size 2097152
configbsp -bsp zynq_fw_bsp memp_n_pbuf 8
configbsp -bsp zynq_fw_bsp memp_n_tcp_pcb 2
configbsp -bsp zynq_fw_bsp memp_n_tcp_pcb_listen 4096
configbsp -bsp zynq_fw_bsp memp_n_tcp_seg 4096
configbsp -bsp zynq_fw_bsp pbuf_pool_size 4096
configbsp -bsp zynq_fw_bsp tcp_snd_buf 65535
configbsp -bsp zynq_fw_bsp tcp_wnd 65535
configbsp -bsp zynq_fw_bsp phy_link_speed CONFIG_LINKSPEED1000
configbsp -bsp zynq_fw_bsp lwip_udp false

updatemss -mss zynq_fw_bsp/system.mss

after 5000
regenbsp -bsp zynq_fw_bsp

projects -build


