cd D:/FPGA_PUFs/RO/test_zybo/test_zybo.sdk
setws D:/FPGA_PUFs/RO/test_zybo/test_zybo.sdk


createapp -name zynq_fw -app {Empty Application} -proc ps7_cortexa9_0 -bsp zynq_fw_bsp -hwproject zynq_fw_hw_platform -os standalone
# # createapp -name zynq_fw -app {Empty Application} -proc ps7_cortexa9_0 -hwproject zynq_fw_hw_platform -os standalone
configapp -app zynq_fw build-config release
configapp -app zynq_fw -add compiler-misc {-std=c11}

importsources -name zynq_fw -path "D:/FPGA_PUFs/RO/test_zybo/sdk" -linker-script

# changebsp -app zynq_fw -newbsp zynq_fw_bsp

# projects -clean
projects -build

exec bootgen -image D:/FPGA_PUFs/RO/test_zybo/sdk/zynq_fw.bif -arch zynq -w -o D:/FPGA_PUFs/RO/test_zybo/bitstreams/BOOT.bin

