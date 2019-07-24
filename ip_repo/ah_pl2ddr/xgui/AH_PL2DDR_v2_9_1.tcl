
# Loading additional proc with user specified bodies to compute parameter values.
source [file join [file dirname [file dirname [info script]]] gui/AH_PL2DDR_v1_0.gtcl]

# Definitional proc to organize widgets for parameters.
proc init_gui { IPINST } {
  ipgui::add_param $IPINST -name "Component_Name"
  #Adding Page
  set Data_options [ipgui::add_page $IPINST -name "Data options"]
  ipgui::add_param $IPINST -name "DATA_WIDTH" -parent ${Data_options} -widget comboBox

  #Adding Page
  set Page_0 [ipgui::add_page $IPINST -name "Page 0" -display_name {Port options}]
  ipgui::add_param $IPINST -name "ENABLE_CMD_INPUT" -parent ${Page_0}
  ipgui::add_param $IPINST -name "ENABLE_MODE_INPUT" -parent ${Page_0}
  ipgui::add_param $IPINST -name "ENABLE_SAMPLES_INPUT" -parent ${Page_0}
  ipgui::add_param $IPINST -name "ENABLE_UNDERSAMPLES_INPUT" -parent ${Page_0}
  ipgui::add_param $IPINST -name "ENABLE_ADDRESS_INPUT" -parent ${Page_0}
  ipgui::add_param $IPINST -name "ENABLE_INTR_SENT" -parent ${Page_0}
  ipgui::add_param $IPINST -name "ENABLE_INTR_DONE" -parent ${Page_0}

  #Adding Page
  set Sampling_options [ipgui::add_page $IPINST -name "Sampling options"]
  ipgui::add_param $IPINST -name "DEFAULT_SAMPLING_MODE" -parent ${Sampling_options} -widget comboBox
  ipgui::add_param $IPINST -name "DEFAULT_SAMPLE_NUMBER" -parent ${Sampling_options}
  ipgui::add_param $IPINST -name "DEFAULT_UNDERSAMPLING_VALUE" -parent ${Sampling_options}

  #Adding Page
  set Address_options [ipgui::add_page $IPINST -name "Address options"]
  ipgui::add_param $IPINST -name "DEFAULT_DDR_LOW" -parent ${Address_options}
  set DEFAULT_DDR_HIGH [ipgui::add_param $IPINST -name "DEFAULT_DDR_HIGH" -parent ${Address_options}]
  set_property tooltip {Target DDR base address} ${DEFAULT_DDR_HIGH}

  #Adding Page
  set Advanced [ipgui::add_page $IPINST -name "Advanced"]
  ipgui::add_param $IPINST -name "ENABLE_INFO_OUTPUT" -parent ${Advanced}
  ipgui::add_param $IPINST -name "ENABLE_DEBUG_OUTPUT" -parent ${Advanced}
  ipgui::add_param $IPINST -name "ENABLE_ERROR_OUTPUT" -parent ${Advanced}
  ipgui::add_param $IPINST -name "ENABLE_INTR_ACK" -parent ${Advanced}
  ipgui::add_param $IPINST -name "ENABLE_INTR_ERROR" -parent ${Advanced}
  ipgui::add_param $IPINST -name "ENABLE_TRANSFER_CONTROL" -parent ${Advanced}
  set DSP_FOR_CALC [ipgui::add_param $IPINST -name "DSP_FOR_CALC" -parent ${Advanced}]
  set_property tooltip {DSP48 elements are used for internal calculations. Reduces utilized logic (SLICE and LUT) greatly, but could potentially lead to timing issues.} ${DSP_FOR_CALC}
  set RESET_WAIT [ipgui::add_param $IPINST -name "RESET_WAIT" -parent ${Advanced}]
  set_property tooltip {Number of clock cycles to wait after any reset occured. Use this to avoid synchronization problems: the reset wait should be at least as long as ceil(freq(system clock) / freq(data clock)), e.g. system clock = 100MHz, data clock = 30MHz, reset wait = 4 } ${RESET_WAIT}

  #Adding Page
  set Help [ipgui::add_page $IPINST -name "Help"]
  #Adding Group
  set Sampling_modes [ipgui::add_group $IPINST -name "Sampling modes" -parent ${Help}]
  ipgui::add_static_text $IPINST -name "content_sampling" -parent ${Sampling_modes} -text {In the following, the available sampling modes are explained.
The input port data_in is used to collect the samples, in some modes
only if the input port data_en is high.
Sampling can be free running or with a defined number of samples,
even with additional undersampling.
Most complex mode is manual mode, where a single sample is only taken
when the corresponding command is received.
All modes are only active if the IP is enabled, either by the command CMD_ENABLE
or by setting the input port enable to high.

No sampling
	- standby like mode
    - does not collect any samples

Running
	- samples are collected only if the input port data_en is high
    - collects and transfers samples continuously 

Free running
    - input port data_en is ignored
    - collects and transfers samples continuously 
	
Sampled
    - collects number of samples set by the input port number_samples
    - samples are collected only if the input port data_en is high
	   
Undersampled
   - same behavior as Sampled, but only stores every x-th sample, where x is set by the input port undersample_factor
   
Manual
    - functional only, when command input is used
    - collects a single sample when the specific command CMD_TRIGGER_SAMPLE is received
	- input port data_en is ignored
	- additional commands may be necessairy to receive data, such as CMD_TRIGGER_FILLDATA, CMD_TRIGGER_TX and CMD_FORCE_TX
	}

  #Adding Group
  set Addresses [ipgui::add_group $IPINST -name "Addresses" -parent ${Help}]
  ipgui::add_static_text $IPINST -name "content_addresses" -parent ${Addresses} -text {The DDR addresses define the target range of the AXI4 transfers regarding the address map of the Zynq (chpt. 4.1, UG585).
DDR is usually placed in the address range 0x00100000 to 0x3FFFFFFF, which corresponds to 1 GB of DDR.
The specific address mapping can be found in the linker script lscript.ld in an SDK project.
For the Zybo, the high address is 0x1FFFFFFF, which corresponds to 512 MB of DDR.

Attention: The compiled project files (.elf) are usually also placed at the beginning of the DDR range,
which again can be checked in the linker script. The size of the programm also depends on the 
parameters Stack size and Heap size in the linker script.
It is advisable to set the DDR low address higher to avoid conflicting with the programm memory.

The parameters DDR base address and max address define the range of DDR on which the IP is allowed to write.
Pay attention that these adresses are byte-wise addresses but that the IP bursts in transfers of 4 bytes at once.
This means that, e.g. for the Zybo, the last valid address is 0x1FFFFFFF - 4 = 0x1FFFFFFC,
and therefore the last burst will start at 0x1FFFFFFC and the last valid byte will be found at 0x1FFFFFFF.

Recommended values (assuming standard Stack and Heap sizes of 0x20000):
 - Target DDR base address: 0x01000000
 - Target DDR max address: 0x1FFFFFFC}

  #Adding Group
  set Commands [ipgui::add_group $IPINST -name "Commands" -parent ${Help}]
  ipgui::add_static_text $IPINST -name "content_commands" -parent ${Commands} -text {All the following commands (hexadecimal) can be written to the port cmd_in and will be processed on a rising edge on port cmd_en.
The header file, ah_pl2ddr_commands.h, will be provided with the driver for this IP, which contains the commands as C macros.
These macros can be used to write directly to the input port cmd_in, e.h. with the help of the IP AH_CPU2PL.

The following commands are used for setting the system in an initial state, e.g. for new capture runs
CMD_NONE (00000000) 	- no operation, for clearing the cmd register only
CMD_RST (00000001) 		- reset the whole system
CMD_RST_ADDR (00000002) - reset the DDR write adress to the given low address
CMD_RST_DATA (00000004) - reset the data collector and storage

The following commands control the data collection functionality as a whole
If enabled, data is then captured depending on the sampling mode and the data_en port
If disabled, data is not collected, independent from other settings
CMD_DISABLE (00000020) - disable the data collection functionality
CMD_ENABLE (00000021) - enable the data collection functionality

The following commands can be used for the manual mode and for resolving errors
CMD_TRIGGER_TX (00000100) - triggers a data transfer if enough data for sending is available
CMD_FORCE_TX (00000101) -  forces a transfer of all data
CMD_TRIGGER_SAMPLE (00000102) - triggers a single capture event
CMD_TRIGGER_FILLDATA (00000104) - fills the remaining bits of a 32-bit transfer packet with 0s, making the data available for transfer

The following commands control the interrupt behavior, switching specific interrupts either off or on
CMD_INTR_ONSENT_DISABLE (00001010) - no interrupt when data transfer finished
CMD_INTR_ONSENT_ENABLE (00001011) - interrupt when data transfer finished
CMD_INTR_ONDONE_DISABLE (00001020) - no interrupt when data collection is finished sampled mode
CMD_INTR_ONDONE_ENABLE (00001021) - interrupt when data collection is finished sampled mode
CMD_INTR_ONERROR_DISABLE (00001040) - no interrupt when an error occured
CMD_INTR_ONERROR_ENABLE (00001041) - interrupt when an error occured
CMD_INTR_ONACK_DISABLE (00001080) - no interrupt when command written is acknowledged and will be executed
CMD_INTR_ONACK_ENABLE (00001081) - interrupt when command written is acknowledged and will be executed

The following commands controls the internal test mode, which does not capture but produces its own data as an incrementing counter
CMD_TESTMODE_DISABLE (00010000) - disable test mode
CMD_TESTMODE_ENABLE (00010001) - enable test mode}

  #Adding Group
  set Driver [ipgui::add_group $IPINST -name "Driver" -parent ${Help}]
  ipgui::add_static_text $IPINST -name "content driver" -parent ${Driver} -text {

The IP will deliver helper files as a driver, which will be shown in the hardware description file (.hdf).

The file ah_pl2ddr.h provides the macros for the commands and the sampling modes

in addition to some helpful comments on caching, interrupt usage and reading valus from the DDR.



However, as it is not recognized as an IP with a driver (no direct input from the CPU),

the driver will not be included in the board support package.



In order to use the files (e.g. ah_pl2ddr.h), copy them from the driver folder of the hdf (in the SDK)

and paste it to the source folder of your project directly.



}



}

proc update_PARAM_VALUE.ENABLE_INTR_ACK { PARAM_VALUE.ENABLE_INTR_ACK PARAM_VALUE.ENABLE_DEBUG_OUTPUT } {
	# Procedure called to update ENABLE_INTR_ACK when any of the dependent parameters in the arguments change
	
	set ENABLE_INTR_ACK ${PARAM_VALUE.ENABLE_INTR_ACK}
	set ENABLE_DEBUG_OUTPUT ${PARAM_VALUE.ENABLE_DEBUG_OUTPUT}
	set values(ENABLE_DEBUG_OUTPUT) [get_property value $ENABLE_DEBUG_OUTPUT]
	if { [gen_USERPARAMETER_ENABLE_INTR_ACK_ENABLEMENT $values(ENABLE_DEBUG_OUTPUT)] } {
		set_property enabled true $ENABLE_INTR_ACK
	} else {
		set_property enabled false $ENABLE_INTR_ACK
	}
}

proc validate_PARAM_VALUE.ENABLE_INTR_ACK { PARAM_VALUE.ENABLE_INTR_ACK } {
	# Procedure called to validate ENABLE_INTR_ACK
	return true
}

proc update_PARAM_VALUE.C_M_AXI_OUT_ADDR_WIDTH { PARAM_VALUE.C_M_AXI_OUT_ADDR_WIDTH } {
	# Procedure called to update C_M_AXI_OUT_ADDR_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_M_AXI_OUT_ADDR_WIDTH { PARAM_VALUE.C_M_AXI_OUT_ADDR_WIDTH } {
	# Procedure called to validate C_M_AXI_OUT_ADDR_WIDTH
	return true
}

proc update_PARAM_VALUE.C_M_AXI_OUT_ARUSER_WIDTH { PARAM_VALUE.C_M_AXI_OUT_ARUSER_WIDTH } {
	# Procedure called to update C_M_AXI_OUT_ARUSER_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_M_AXI_OUT_ARUSER_WIDTH { PARAM_VALUE.C_M_AXI_OUT_ARUSER_WIDTH } {
	# Procedure called to validate C_M_AXI_OUT_ARUSER_WIDTH
	return true
}

proc update_PARAM_VALUE.C_M_AXI_OUT_AWUSER_WIDTH { PARAM_VALUE.C_M_AXI_OUT_AWUSER_WIDTH } {
	# Procedure called to update C_M_AXI_OUT_AWUSER_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_M_AXI_OUT_AWUSER_WIDTH { PARAM_VALUE.C_M_AXI_OUT_AWUSER_WIDTH } {
	# Procedure called to validate C_M_AXI_OUT_AWUSER_WIDTH
	return true
}

proc update_PARAM_VALUE.C_M_AXI_OUT_BUSER_WIDTH { PARAM_VALUE.C_M_AXI_OUT_BUSER_WIDTH } {
	# Procedure called to update C_M_AXI_OUT_BUSER_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_M_AXI_OUT_BUSER_WIDTH { PARAM_VALUE.C_M_AXI_OUT_BUSER_WIDTH } {
	# Procedure called to validate C_M_AXI_OUT_BUSER_WIDTH
	return true
}

proc update_PARAM_VALUE.C_M_AXI_OUT_DATA_WIDTH { PARAM_VALUE.C_M_AXI_OUT_DATA_WIDTH } {
	# Procedure called to update C_M_AXI_OUT_DATA_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_M_AXI_OUT_DATA_WIDTH { PARAM_VALUE.C_M_AXI_OUT_DATA_WIDTH } {
	# Procedure called to validate C_M_AXI_OUT_DATA_WIDTH
	return true
}

proc update_PARAM_VALUE.C_M_AXI_OUT_ID_WIDTH { PARAM_VALUE.C_M_AXI_OUT_ID_WIDTH } {
	# Procedure called to update C_M_AXI_OUT_ID_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_M_AXI_OUT_ID_WIDTH { PARAM_VALUE.C_M_AXI_OUT_ID_WIDTH } {
	# Procedure called to validate C_M_AXI_OUT_ID_WIDTH
	return true
}

proc update_PARAM_VALUE.C_M_AXI_OUT_RUSER_WIDTH { PARAM_VALUE.C_M_AXI_OUT_RUSER_WIDTH } {
	# Procedure called to update C_M_AXI_OUT_RUSER_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_M_AXI_OUT_RUSER_WIDTH { PARAM_VALUE.C_M_AXI_OUT_RUSER_WIDTH } {
	# Procedure called to validate C_M_AXI_OUT_RUSER_WIDTH
	return true
}

proc update_PARAM_VALUE.C_M_AXI_OUT_WUSER_WIDTH { PARAM_VALUE.C_M_AXI_OUT_WUSER_WIDTH } {
	# Procedure called to update C_M_AXI_OUT_WUSER_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_M_AXI_OUT_WUSER_WIDTH { PARAM_VALUE.C_M_AXI_OUT_WUSER_WIDTH } {
	# Procedure called to validate C_M_AXI_OUT_WUSER_WIDTH
	return true
}

proc update_PARAM_VALUE.DATA_WIDTH { PARAM_VALUE.DATA_WIDTH } {
	# Procedure called to update DATA_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.DATA_WIDTH { PARAM_VALUE.DATA_WIDTH } {
	# Procedure called to validate DATA_WIDTH
	return true
}

proc update_PARAM_VALUE.DEFAULT_DDR_HIGH { PARAM_VALUE.DEFAULT_DDR_HIGH } {
	# Procedure called to update DEFAULT_DDR_HIGH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.DEFAULT_DDR_HIGH { PARAM_VALUE.DEFAULT_DDR_HIGH } {
	# Procedure called to validate DEFAULT_DDR_HIGH
	return true
}

proc update_PARAM_VALUE.DEFAULT_DDR_LOW { PARAM_VALUE.DEFAULT_DDR_LOW } {
	# Procedure called to update DEFAULT_DDR_LOW when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.DEFAULT_DDR_LOW { PARAM_VALUE.DEFAULT_DDR_LOW } {
	# Procedure called to validate DEFAULT_DDR_LOW
	return true
}

proc update_PARAM_VALUE.DEFAULT_SAMPLE_NUMBER { PARAM_VALUE.DEFAULT_SAMPLE_NUMBER } {
	# Procedure called to update DEFAULT_SAMPLE_NUMBER when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.DEFAULT_SAMPLE_NUMBER { PARAM_VALUE.DEFAULT_SAMPLE_NUMBER } {
	# Procedure called to validate DEFAULT_SAMPLE_NUMBER
	return true
}

proc update_PARAM_VALUE.DEFAULT_SAMPLING_MODE { PARAM_VALUE.DEFAULT_SAMPLING_MODE } {
	# Procedure called to update DEFAULT_SAMPLING_MODE when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.DEFAULT_SAMPLING_MODE { PARAM_VALUE.DEFAULT_SAMPLING_MODE } {
	# Procedure called to validate DEFAULT_SAMPLING_MODE
	return true
}

proc update_PARAM_VALUE.DEFAULT_UNDERSAMPLING_VALUE { PARAM_VALUE.DEFAULT_UNDERSAMPLING_VALUE } {
	# Procedure called to update DEFAULT_UNDERSAMPLING_VALUE when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.DEFAULT_UNDERSAMPLING_VALUE { PARAM_VALUE.DEFAULT_UNDERSAMPLING_VALUE } {
	# Procedure called to validate DEFAULT_UNDERSAMPLING_VALUE
	return true
}

proc update_PARAM_VALUE.DSP_FOR_CALC { PARAM_VALUE.DSP_FOR_CALC } {
	# Procedure called to update DSP_FOR_CALC when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.DSP_FOR_CALC { PARAM_VALUE.DSP_FOR_CALC } {
	# Procedure called to validate DSP_FOR_CALC
	return true
}

proc update_PARAM_VALUE.ENABLE_ADDRESS_INPUT { PARAM_VALUE.ENABLE_ADDRESS_INPUT } {
	# Procedure called to update ENABLE_ADDRESS_INPUT when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.ENABLE_ADDRESS_INPUT { PARAM_VALUE.ENABLE_ADDRESS_INPUT } {
	# Procedure called to validate ENABLE_ADDRESS_INPUT
	return true
}

proc update_PARAM_VALUE.ENABLE_CMD_INPUT { PARAM_VALUE.ENABLE_CMD_INPUT } {
	# Procedure called to update ENABLE_CMD_INPUT when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.ENABLE_CMD_INPUT { PARAM_VALUE.ENABLE_CMD_INPUT } {
	# Procedure called to validate ENABLE_CMD_INPUT
	return true
}

proc update_PARAM_VALUE.ENABLE_DEBUG_OUTPUT { PARAM_VALUE.ENABLE_DEBUG_OUTPUT } {
	# Procedure called to update ENABLE_DEBUG_OUTPUT when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.ENABLE_DEBUG_OUTPUT { PARAM_VALUE.ENABLE_DEBUG_OUTPUT } {
	# Procedure called to validate ENABLE_DEBUG_OUTPUT
	return true
}

proc update_PARAM_VALUE.ENABLE_ERROR_OUTPUT { PARAM_VALUE.ENABLE_ERROR_OUTPUT } {
	# Procedure called to update ENABLE_ERROR_OUTPUT when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.ENABLE_ERROR_OUTPUT { PARAM_VALUE.ENABLE_ERROR_OUTPUT } {
	# Procedure called to validate ENABLE_ERROR_OUTPUT
	return true
}

proc update_PARAM_VALUE.ENABLE_INFO_OUTPUT { PARAM_VALUE.ENABLE_INFO_OUTPUT } {
	# Procedure called to update ENABLE_INFO_OUTPUT when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.ENABLE_INFO_OUTPUT { PARAM_VALUE.ENABLE_INFO_OUTPUT } {
	# Procedure called to validate ENABLE_INFO_OUTPUT
	return true
}

proc update_PARAM_VALUE.ENABLE_INTR_DONE { PARAM_VALUE.ENABLE_INTR_DONE } {
	# Procedure called to update ENABLE_INTR_DONE when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.ENABLE_INTR_DONE { PARAM_VALUE.ENABLE_INTR_DONE } {
	# Procedure called to validate ENABLE_INTR_DONE
	return true
}

proc update_PARAM_VALUE.ENABLE_INTR_ERROR { PARAM_VALUE.ENABLE_INTR_ERROR } {
	# Procedure called to update ENABLE_INTR_ERROR when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.ENABLE_INTR_ERROR { PARAM_VALUE.ENABLE_INTR_ERROR } {
	# Procedure called to validate ENABLE_INTR_ERROR
	return true
}

proc update_PARAM_VALUE.ENABLE_INTR_SENT { PARAM_VALUE.ENABLE_INTR_SENT } {
	# Procedure called to update ENABLE_INTR_SENT when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.ENABLE_INTR_SENT { PARAM_VALUE.ENABLE_INTR_SENT } {
	# Procedure called to validate ENABLE_INTR_SENT
	return true
}

proc update_PARAM_VALUE.ENABLE_MODE_INPUT { PARAM_VALUE.ENABLE_MODE_INPUT } {
	# Procedure called to update ENABLE_MODE_INPUT when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.ENABLE_MODE_INPUT { PARAM_VALUE.ENABLE_MODE_INPUT } {
	# Procedure called to validate ENABLE_MODE_INPUT
	return true
}

proc update_PARAM_VALUE.ENABLE_SAMPLES_INPUT { PARAM_VALUE.ENABLE_SAMPLES_INPUT } {
	# Procedure called to update ENABLE_SAMPLES_INPUT when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.ENABLE_SAMPLES_INPUT { PARAM_VALUE.ENABLE_SAMPLES_INPUT } {
	# Procedure called to validate ENABLE_SAMPLES_INPUT
	return true
}

proc update_PARAM_VALUE.ENABLE_TRANSFER_CONTROL { PARAM_VALUE.ENABLE_TRANSFER_CONTROL } {
	# Procedure called to update ENABLE_TRANSFER_CONTROL when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.ENABLE_TRANSFER_CONTROL { PARAM_VALUE.ENABLE_TRANSFER_CONTROL } {
	# Procedure called to validate ENABLE_TRANSFER_CONTROL
	return true
}

proc update_PARAM_VALUE.ENABLE_UNDERSAMPLES_INPUT { PARAM_VALUE.ENABLE_UNDERSAMPLES_INPUT } {
	# Procedure called to update ENABLE_UNDERSAMPLES_INPUT when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.ENABLE_UNDERSAMPLES_INPUT { PARAM_VALUE.ENABLE_UNDERSAMPLES_INPUT } {
	# Procedure called to validate ENABLE_UNDERSAMPLES_INPUT
	return true
}

proc update_PARAM_VALUE.RESET_WAIT { PARAM_VALUE.RESET_WAIT } {
	# Procedure called to update RESET_WAIT when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.RESET_WAIT { PARAM_VALUE.RESET_WAIT } {
	# Procedure called to validate RESET_WAIT
	return true
}


proc update_MODELPARAM_VALUE.DATA_WIDTH { MODELPARAM_VALUE.DATA_WIDTH PARAM_VALUE.DATA_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.DATA_WIDTH}] ${MODELPARAM_VALUE.DATA_WIDTH}
}

proc update_MODELPARAM_VALUE.ENABLE_CMD_INPUT { MODELPARAM_VALUE.ENABLE_CMD_INPUT PARAM_VALUE.ENABLE_CMD_INPUT } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.ENABLE_CMD_INPUT}] ${MODELPARAM_VALUE.ENABLE_CMD_INPUT}
}

proc update_MODELPARAM_VALUE.ENABLE_MODE_INPUT { MODELPARAM_VALUE.ENABLE_MODE_INPUT PARAM_VALUE.ENABLE_MODE_INPUT } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.ENABLE_MODE_INPUT}] ${MODELPARAM_VALUE.ENABLE_MODE_INPUT}
}

proc update_MODELPARAM_VALUE.ENABLE_SAMPLES_INPUT { MODELPARAM_VALUE.ENABLE_SAMPLES_INPUT PARAM_VALUE.ENABLE_SAMPLES_INPUT } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.ENABLE_SAMPLES_INPUT}] ${MODELPARAM_VALUE.ENABLE_SAMPLES_INPUT}
}

proc update_MODELPARAM_VALUE.ENABLE_UNDERSAMPLES_INPUT { MODELPARAM_VALUE.ENABLE_UNDERSAMPLES_INPUT PARAM_VALUE.ENABLE_UNDERSAMPLES_INPUT } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.ENABLE_UNDERSAMPLES_INPUT}] ${MODELPARAM_VALUE.ENABLE_UNDERSAMPLES_INPUT}
}

proc update_MODELPARAM_VALUE.ENABLE_ADDRESS_INPUT { MODELPARAM_VALUE.ENABLE_ADDRESS_INPUT PARAM_VALUE.ENABLE_ADDRESS_INPUT } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.ENABLE_ADDRESS_INPUT}] ${MODELPARAM_VALUE.ENABLE_ADDRESS_INPUT}
}

proc update_MODELPARAM_VALUE.ENABLE_INTR_SENT { MODELPARAM_VALUE.ENABLE_INTR_SENT PARAM_VALUE.ENABLE_INTR_SENT } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.ENABLE_INTR_SENT}] ${MODELPARAM_VALUE.ENABLE_INTR_SENT}
}

proc update_MODELPARAM_VALUE.ENABLE_INTR_DONE { MODELPARAM_VALUE.ENABLE_INTR_DONE PARAM_VALUE.ENABLE_INTR_DONE } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.ENABLE_INTR_DONE}] ${MODELPARAM_VALUE.ENABLE_INTR_DONE}
}

proc update_MODELPARAM_VALUE.ENABLE_INTR_ERROR { MODELPARAM_VALUE.ENABLE_INTR_ERROR PARAM_VALUE.ENABLE_INTR_ERROR } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.ENABLE_INTR_ERROR}] ${MODELPARAM_VALUE.ENABLE_INTR_ERROR}
}

proc update_MODELPARAM_VALUE.DSP_FOR_CALC { MODELPARAM_VALUE.DSP_FOR_CALC PARAM_VALUE.DSP_FOR_CALC } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.DSP_FOR_CALC}] ${MODELPARAM_VALUE.DSP_FOR_CALC}
}

proc update_MODELPARAM_VALUE.ENABLE_TRANSFER_CONTROL { MODELPARAM_VALUE.ENABLE_TRANSFER_CONTROL PARAM_VALUE.ENABLE_TRANSFER_CONTROL } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.ENABLE_TRANSFER_CONTROL}] ${MODELPARAM_VALUE.ENABLE_TRANSFER_CONTROL}
}

proc update_MODELPARAM_VALUE.RESET_WAIT { MODELPARAM_VALUE.RESET_WAIT PARAM_VALUE.RESET_WAIT } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.RESET_WAIT}] ${MODELPARAM_VALUE.RESET_WAIT}
}

proc update_MODELPARAM_VALUE.DEFAULT_SAMPLING_MODE { MODELPARAM_VALUE.DEFAULT_SAMPLING_MODE PARAM_VALUE.DEFAULT_SAMPLING_MODE } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.DEFAULT_SAMPLING_MODE}] ${MODELPARAM_VALUE.DEFAULT_SAMPLING_MODE}
}

proc update_MODELPARAM_VALUE.DEFAULT_SAMPLE_NUMBER { MODELPARAM_VALUE.DEFAULT_SAMPLE_NUMBER PARAM_VALUE.DEFAULT_SAMPLE_NUMBER } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.DEFAULT_SAMPLE_NUMBER}] ${MODELPARAM_VALUE.DEFAULT_SAMPLE_NUMBER}
}

proc update_MODELPARAM_VALUE.DEFAULT_UNDERSAMPLING_VALUE { MODELPARAM_VALUE.DEFAULT_UNDERSAMPLING_VALUE PARAM_VALUE.DEFAULT_UNDERSAMPLING_VALUE } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.DEFAULT_UNDERSAMPLING_VALUE}] ${MODELPARAM_VALUE.DEFAULT_UNDERSAMPLING_VALUE}
}

proc update_MODELPARAM_VALUE.DEFAULT_DDR_LOW { MODELPARAM_VALUE.DEFAULT_DDR_LOW PARAM_VALUE.DEFAULT_DDR_LOW } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.DEFAULT_DDR_LOW}] ${MODELPARAM_VALUE.DEFAULT_DDR_LOW}
}

proc update_MODELPARAM_VALUE.DEFAULT_DDR_HIGH { MODELPARAM_VALUE.DEFAULT_DDR_HIGH PARAM_VALUE.DEFAULT_DDR_HIGH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.DEFAULT_DDR_HIGH}] ${MODELPARAM_VALUE.DEFAULT_DDR_HIGH}
}

proc update_MODELPARAM_VALUE.C_M_AXI_OUT_ID_WIDTH { MODELPARAM_VALUE.C_M_AXI_OUT_ID_WIDTH PARAM_VALUE.C_M_AXI_OUT_ID_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_M_AXI_OUT_ID_WIDTH}] ${MODELPARAM_VALUE.C_M_AXI_OUT_ID_WIDTH}
}

proc update_MODELPARAM_VALUE.C_M_AXI_OUT_ADDR_WIDTH { MODELPARAM_VALUE.C_M_AXI_OUT_ADDR_WIDTH PARAM_VALUE.C_M_AXI_OUT_ADDR_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_M_AXI_OUT_ADDR_WIDTH}] ${MODELPARAM_VALUE.C_M_AXI_OUT_ADDR_WIDTH}
}

proc update_MODELPARAM_VALUE.C_M_AXI_OUT_DATA_WIDTH { MODELPARAM_VALUE.C_M_AXI_OUT_DATA_WIDTH PARAM_VALUE.C_M_AXI_OUT_DATA_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_M_AXI_OUT_DATA_WIDTH}] ${MODELPARAM_VALUE.C_M_AXI_OUT_DATA_WIDTH}
}

proc update_MODELPARAM_VALUE.C_M_AXI_OUT_AWUSER_WIDTH { MODELPARAM_VALUE.C_M_AXI_OUT_AWUSER_WIDTH PARAM_VALUE.C_M_AXI_OUT_AWUSER_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_M_AXI_OUT_AWUSER_WIDTH}] ${MODELPARAM_VALUE.C_M_AXI_OUT_AWUSER_WIDTH}
}

proc update_MODELPARAM_VALUE.C_M_AXI_OUT_ARUSER_WIDTH { MODELPARAM_VALUE.C_M_AXI_OUT_ARUSER_WIDTH PARAM_VALUE.C_M_AXI_OUT_ARUSER_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_M_AXI_OUT_ARUSER_WIDTH}] ${MODELPARAM_VALUE.C_M_AXI_OUT_ARUSER_WIDTH}
}

proc update_MODELPARAM_VALUE.C_M_AXI_OUT_WUSER_WIDTH { MODELPARAM_VALUE.C_M_AXI_OUT_WUSER_WIDTH PARAM_VALUE.C_M_AXI_OUT_WUSER_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_M_AXI_OUT_WUSER_WIDTH}] ${MODELPARAM_VALUE.C_M_AXI_OUT_WUSER_WIDTH}
}

proc update_MODELPARAM_VALUE.C_M_AXI_OUT_RUSER_WIDTH { MODELPARAM_VALUE.C_M_AXI_OUT_RUSER_WIDTH PARAM_VALUE.C_M_AXI_OUT_RUSER_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_M_AXI_OUT_RUSER_WIDTH}] ${MODELPARAM_VALUE.C_M_AXI_OUT_RUSER_WIDTH}
}

proc update_MODELPARAM_VALUE.C_M_AXI_OUT_BUSER_WIDTH { MODELPARAM_VALUE.C_M_AXI_OUT_BUSER_WIDTH PARAM_VALUE.C_M_AXI_OUT_BUSER_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_M_AXI_OUT_BUSER_WIDTH}] ${MODELPARAM_VALUE.C_M_AXI_OUT_BUSER_WIDTH}
}

