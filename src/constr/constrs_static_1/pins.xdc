##Clock signal
##IO_L11P_T1_SRCC_35
#set_property PACKAGE_PIN L16 [get_ports CLK125M]
#set_property IOSTANDARD LVCMOS33 [get_ports CLK125M]

##Switches
##IO_L19N_T3_35
#set_property PACKAGE_PIN G15 [get_ports {SW[0]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {SW[0]}]

##IO_L24P_T3_34
#set_property PACKAGE_PIN P15 [get_ports {SW[1]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {SW[1]}]

##IO_L4N_T0_34
#set_property PACKAGE_PIN W13 [get_ports {SW[2]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {SW[2]}]

##IO_L9P_T1_DQS_34
#set_property PACKAGE_PIN T16 [get_ports {SW[3]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {SW[3]}]

##Buttons
##IO_L20N_T3_34
#set_property PACKAGE_PIN R18 [get_ports {BTN[0]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {BTN[0]}]

##IO_L24N_T3_34
#set_property PACKAGE_PIN P16 [get_ports {BTN[1]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {BTN[1]}]

##IO_L18P_T2_34
#set_property PACKAGE_PIN V16 [get_ports {BTN[2]}]
#et_property IOSTANDARD LVCMOS33 [get_ports {BTN[2]}]

##IO_L7P_T1_34
#set_property PACKAGE_PIN Y16 [get_ports {BTN[3]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {BTN[3]}]

##LEDs
##IO_L23P_T3_35
#set_property PACKAGE_PIN M14 [get_ports {LED[0]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {LED[0]}]

##IO_L23N_T3_35
#set_property PACKAGE_PIN M15 [get_ports {LED[1]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {LED[1]}]

##IO_0_35
#set_property PACKAGE_PIN G14 [get_ports {LED[2]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {LED[2]}]

##IO_L3N_T0_DQS_AD1N_35
#set_property PACKAGE_PIN D18 [get_ports {LED[3]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {LED[3]}]

##Bank Voltage Settings
set_property CFGBVS VCCO [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]

## I2c
#set_property IOSTANDARD LVCMOS33 [get_ports IIC_0_0_scl_io]
#set_property IOSTANDARD LVCMOS33 [get_ports IIC_0_0_sda_io]
#set_property PULLUP true [get_ports IIC_0_0_scl_io]
#set_property PULLUP true [get_ports IIC_0_0_sda_io]