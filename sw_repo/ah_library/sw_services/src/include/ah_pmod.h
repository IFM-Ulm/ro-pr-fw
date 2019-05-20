#include "xparameters.h"

#ifndef AH_PMOD_H
#define AH_PMOD_H

/* Important notice:

	For this library function to work, one has to follow these steps:
		- instantiate the IP "AXI GPIO" in a block design in Vivado for each PMOD port to be used
		- ensure that the name of the IP instances are as follows: "axi_pgio_0", "axi_pgio_1", ..., "axi_pgio_7"
		- select "IP Interface" as "Custom"
		- set "GPIO Width" to 8
		- do NOT select "Enable Dual Channel", "All Inputs" or "All Outputs"
	
	Additionally, these IPs have to be connected to gpio-interfaces created in the block design as follows:
		- "Create Interface Port" -> "Interface name" = jb, jc, jd or je
		- Mode: Master
		- Type: xilinx.com:interface:gpio_rtl:1.0
	
	Finally, the package pins have to be declared in the .xdc file as follows:
	
	##Pmod Header JB
	set_property -dict { PACKAGE_PIN T20   IOSTANDARD LVCMOS33 } [get_ports { jb_tri_io[0] }]; #IO_L15P_T2_DQS_34 Sch=JB1_p
	set_property -dict { PACKAGE_PIN U20   IOSTANDARD LVCMOS33 } [get_ports { jb_tri_io[1] }]; #IO_L15N_T2_DQS_34 Sch=JB1_N
	set_property -dict { PACKAGE_PIN V20   IOSTANDARD LVCMOS33 } [get_ports { jb_tri_io[2] }]; #IO_L16P_T2_34 Sch=JB2_P
	set_property -dict { PACKAGE_PIN W20   IOSTANDARD LVCMOS33 } [get_ports { jb_tri_io[3] }]; #IO_L16N_T2_34 Sch=JB2_N
	set_property -dict { PACKAGE_PIN Y18   IOSTANDARD LVCMOS33 } [get_ports { jb_tri_io[4] }]; #IO_L17P_T2_34 Sch=JB3_P
	set_property -dict { PACKAGE_PIN Y19   IOSTANDARD LVCMOS33 } [get_ports { jb_tri_io[5] }]; #IO_L17N_T2_34 Sch=JB3_N
	set_property -dict { PACKAGE_PIN W18   IOSTANDARD LVCMOS33 } [get_ports { jb_tri_io[6] }]; #IO_L22P_T3_34 Sch=JB4_P
	set_property -dict { PACKAGE_PIN W19   IOSTANDARD LVCMOS33 } [get_ports { jb_tri_io[7] }]; #IO_L22N_T3_34 Sch=JB4_N
	
	##Pmod Header JC
	#set_property -dict { PACKAGE_PIN V15   IOSTANDARD LVCMOS33 } [get_ports { jc_tri_io[0] }]; #IO_L10P_T1_34 Sch=JC1_P
	#set_property -dict { PACKAGE_PIN W15   IOSTANDARD LVCMOS33 } [get_ports { jc_tri_io[1] }]; #IO_L10N_T1_34 Sch=JC1_N
	#set_property -dict { PACKAGE_PIN T11   IOSTANDARD LVCMOS33 } [get_ports { jc_tri_io[2] }]; #IO_L1P_T0_34 Sch=JC2_P
	#set_property -dict { PACKAGE_PIN T10   IOSTANDARD LVCMOS33 } [get_ports { jc_tri_io[3] }]; #IO_L1N_T0_34 Sch=JC2_N
	#set_property -dict { PACKAGE_PIN W14   IOSTANDARD LVCMOS33 } [get_ports { jc_tri_io[4] }]; #IO_L8P_T1_34 Sch=JC3_P
	#set_property -dict { PACKAGE_PIN Y14   IOSTANDARD LVCMOS33 } [get_ports { jc_tri_io[5] }]; #IO_L8N_T1_34 Sch=JC3_N
	#set_property -dict { PACKAGE_PIN T12   IOSTANDARD LVCMOS33 } [get_ports { jc_tri_io[6] }]; #IO_L2P_T0_34 Sch=JC4_P
	#set_property -dict { PACKAGE_PIN U12   IOSTANDARD LVCMOS33 } [get_ports { jc_tri_io[7] }]; #IO_L2N_T0_34 Sch=JC4_N

	##Pmod Header JD
	#set_property -dict { PACKAGE_PIN T14   IOSTANDARD LVCMOS33 } [get_ports { jd_tri_io[0] }]; #IO_L5P_T0_34 Sch=JD1_P
	#set_property -dict { PACKAGE_PIN T15   IOSTANDARD LVCMOS33 } [get_ports { jd_tri_io[1] }]; #IO_L5N_T0_34 Sch=JD1_N
	#set_property -dict { PACKAGE_PIN P14   IOSTANDARD LVCMOS33 } [get_ports { jd_tri_io[2] }]; #IO_L6P_T0_34 Sch=JD2_P
	#set_property -dict { PACKAGE_PIN R14   IOSTANDARD LVCMOS33 } [get_ports { jd_tri_io[3] }]; #IO_L6N_T0_VREF_34 Sch=JD2_N
	#set_property -dict { PACKAGE_PIN U14   IOSTANDARD LVCMOS33 } [get_ports { jd_tri_io[4] }]; #IO_L11P_T1_SRCC_34 Sch=JD3_P
	#set_property -dict { PACKAGE_PIN U15   IOSTANDARD LVCMOS33 } [get_ports { jd_tri_io[5] }]; #IO_L11N_T1_SRCC_34 Sch=JD3_N
	#set_property -dict { PACKAGE_PIN V17   IOSTANDARD LVCMOS33 } [get_ports { jd_tri_io[6] }]; #IO_L21P_T3_DQS_34 Sch=JD4_P
	#set_property -dict { PACKAGE_PIN V18   IOSTANDARD LVCMOS33 } [get_ports { jd_tri_io[7] }]; #IO_L21N_T3_DQS_34 Sch=JD4_N

	##Pmod Header JE
	#set_property -dict { PACKAGE_PIN V12   IOSTANDARD LVCMOS33 } [get_ports { je_tri_io[0] }]; #IO_L4P_T0_34 Sch=JE1
	#set_property -dict { PACKAGE_PIN W16   IOSTANDARD LVCMOS33 } [get_ports { je_tri_io[1] }]; #IO_L18N_T2_34 Sch=JE2
	#set_property -dict { PACKAGE_PIN J15   IOSTANDARD LVCMOS33 } [get_ports { je_tri_io[2] }]; #IO_25_35 Sch=JE3
	#set_property -dict { PACKAGE_PIN H15   IOSTANDARD LVCMOS33 } [get_ports { je_tri_io[3] }]; #IO_L19P_T3_35 Sch=JE4
	#set_property -dict { PACKAGE_PIN V13   IOSTANDARD LVCMOS33 } [get_ports { je_tri_io[4] }]; #IO_L3N_T0_DQS_34 Sch=JE7
	#set_property -dict { PACKAGE_PIN U17   IOSTANDARD LVCMOS33 } [get_ports { je_tri_io[5] }]; #IO_L9N_T1_DQS_34 Sch=JE8
	#set_property -dict { PACKAGE_PIN T17   IOSTANDARD LVCMOS33 } [get_ports { je_tri_io[6] }]; #IO_L20P_T3_34 Sch=JE9
	#set_property -dict { PACKAGE_PIN Y17   IOSTANDARD LVCMOS33 } [get_ports { je_tri_io[7] }]; #IO_L7N_T1_34 Sch=JE10

	The function ah_pmod_setupPMOD(u8 device, u8 id) then has to be used such that the index of the axi_gpio_* IP is the index
	and the corresponding PMOD port is used as device.
	Examples: 
		axi_gpio_2 is connected to port jd -> ah_pmod_setupPMOD(AH_PMOD_DEVICE_JD, 2)
		axi_gpio_0 is connected to port jb -> ah_pmod_setupPMOD(AH_PMOD_DEVICE_JB, 0)
	
*/

#ifdef AH_PMOD_ACTIVATED

#include "xil_types.h"
#include "xstatus.h"

#define AH_PMOD_DEVICE_JB 0x2
#define AH_PMOD_DEVICE_JC 0x3
#define AH_PMOD_DEVICE_JD 0x4
#define AH_PMOD_DEVICE_JE 0x5
#define AH_PMOD_DEVICE_JF 0x6

#define AH_PMOD_PIN_IN 0x1
#define AH_PMOD_PIN_OUT 0x0

#define AH_PMOD_PIN_1 0x1
#define AH_PMOD_PIN_2 0x2
#define AH_PMOD_PIN_3 0x3
#define AH_PMOD_PIN_4 0x4
#define AH_PMOD_PIN_5 0x5
#define AH_PMOD_PIN_6 0x6
#define AH_PMOD_PIN_7 0x7
#define AH_PMOD_PIN_8 0x8

#define AH_PMOD_VDD 0x1
#define AH_PMOD_GND 0x0

s32 ah_pmod_init(void);
u8 ah_pmod_isInit(void);

s32 ah_pmod_setup(void);
u8 ah_pmod_isSetup(void);

s32 ah_pmod_setupPMOD(u8 device);
s32 ah_pmod_setupPin(u8 device, u8 pin, u8 mode);

s32 ah_pmod_enable(void);
u8 ah_pmod_isEnabled(void);

s32 ah_pmod_writePin(u8 device, u8 pin, u8 value);
s32 ah_pmod_readPin(u8 device, u8 pin, u8* value);


#endif

#endif