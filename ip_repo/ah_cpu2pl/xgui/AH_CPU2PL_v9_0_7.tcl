
# Loading additional proc with user specified bodies to compute parameter values.
source [file join [file dirname [file dirname [info script]]] gui/AXI4_CPU2PL_v1_5.gtcl]

# Definitional proc to organize widgets for parameters.
proc init_gui { IPINST } {
  ipgui::add_param $IPINST -name "Component_Name"
  #Adding Page
  set Customize_connections [ipgui::add_page $IPINST -name "Customize connections"]
  set_property tooltip {User defined customization of the number of inputs and outputs} ${Customize_connections}
  #Adding Group
  set Inputs [ipgui::add_group $IPINST -name "Inputs" -parent ${Customize_connections}]
  #Adding Group
  set _ [ipgui::add_group $IPINST -name " " -parent ${Inputs} -display_name {Number of inputs}]
  set_property tooltip {Number of inputs} ${_}
  set USED_INPUTS [ipgui::add_param $IPINST -name "USED_INPUTS" -parent ${_} -show_label false]
  set_property tooltip {Select the number of inputs available to be read by the CPU} ${USED_INPUTS}
  set SERIALIZE_INPUT [ipgui::add_param $IPINST -name "SERIALIZE_INPUT" -parent ${_}]
  set_property tooltip {Concatenates the 32-bit intputs to a single intput with the corresponding bitwidth, indexing begins from the LSB} ${SERIALIZE_INPUT}

  #Adding Group
  set 1 [ipgui::add_group $IPINST -name "1" -parent ${Inputs} -display_name {Interrupts}]
  set_property tooltip {Interrupts} ${1}
  ipgui::add_param $IPINST -name "ENABLE_IRQ" -parent ${1}
  set IRQ_ACK [ipgui::add_param $IPINST -name "IRQ_ACK" -parent ${1}]
  set_property tooltip {Provides a 1 clock cycle feedback pulse when the software interrupt handler sends an interrupt acknowledge} ${IRQ_ACK}


  #Adding Group
  set Outputs [ipgui::add_group $IPINST -name "Outputs" -parent ${Customize_connections}]
  #Adding Group
  set Number_of_outputs [ipgui::add_group $IPINST -name "Number of outputs" -parent ${Outputs}]
  set USED_OUTPUTS [ipgui::add_param $IPINST -name "USED_OUTPUTS" -parent ${Number_of_outputs} -show_label false]
  set_property tooltip {Select the number of outputs available to be written by the CPU} ${USED_OUTPUTS}
  set SERIALIZE_OUTPUT [ipgui::add_param $IPINST -name "SERIALIZE_OUTPUT" -parent ${Number_of_outputs}]
  set_property tooltip {Concatenates the 32-bit outputs to a single output with the corresponding bitwidth, indexing begins from the LSB} ${SERIALIZE_OUTPUT}

  #Adding Group
  set Interrupts [ipgui::add_group $IPINST -name "Interrupts" -parent ${Outputs}]
  set ENABLE_INTR [ipgui::add_param $IPINST -name "ENABLE_INTR" -parent ${Interrupts}]
  set_property tooltip {Enable generation of a pulse (1 clock cycle high) each time a value is written to the corresponding register} ${ENABLE_INTR}
  set READ_ACK [ipgui::add_param $IPINST -name "READ_ACK" -parent ${Interrupts}]
  set_property tooltip {Enable generation of a pulse (1 clock cycle high) each time a value is read from the corresponding register} ${READ_ACK}


  #Adding Group
  set General [ipgui::add_group $IPINST -name "General" -parent ${Customize_connections}]
  set ADVANCED_CLOCKING [ipgui::add_param $IPINST -name "ADVANCED_CLOCKING" -parent ${General}]
  set_property tooltip {Provides an additional  input for the PL clock in order to synchronize the pulse generation (intr_input, intr_output, intr_ack), which guarantees a pulse 1 clock cycle pulse width in reference to the corresponding clock. Enable this parameter if your PL clock frequency differs from the AXI clocks frequency!} ${ADVANCED_CLOCKING}



}

proc update_PARAM_VALUE.ADVANCED_CLOCKING { PARAM_VALUE.ADVANCED_CLOCKING PARAM_VALUE.ENABLE_INTR PARAM_VALUE.IRQ_ACK } {
	# Procedure called to update ADVANCED_CLOCKING when any of the dependent parameters in the arguments change
	
	set ADVANCED_CLOCKING ${PARAM_VALUE.ADVANCED_CLOCKING}
	set ENABLE_INTR ${PARAM_VALUE.ENABLE_INTR}
	set IRQ_ACK ${PARAM_VALUE.IRQ_ACK}
	set values(ENABLE_INTR) [get_property value $ENABLE_INTR]
	set values(IRQ_ACK) [get_property value $IRQ_ACK]
	if { [gen_USERPARAMETER_ADVANCED_CLOCKING_ENABLEMENT $values(ENABLE_INTR) $values(IRQ_ACK)] } {
		set_property enabled true $ADVANCED_CLOCKING
	} else {
		set_property enabled false $ADVANCED_CLOCKING
		set_property value [gen_USERPARAMETER_ADVANCED_CLOCKING_VALUE $values(ENABLE_INTR) $values(IRQ_ACK)] $ADVANCED_CLOCKING
	}
}

proc validate_PARAM_VALUE.ADVANCED_CLOCKING { PARAM_VALUE.ADVANCED_CLOCKING } {
	# Procedure called to validate ADVANCED_CLOCKING
	return true
}

proc update_PARAM_VALUE.CLOCKING_ADVANCED { PARAM_VALUE.CLOCKING_ADVANCED PARAM_VALUE.ADVANCED_CLOCKING } {
	# Procedure called to update CLOCKING_ADVANCED when any of the dependent parameters in the arguments change
	
	set CLOCKING_ADVANCED ${PARAM_VALUE.CLOCKING_ADVANCED}
	set ADVANCED_CLOCKING ${PARAM_VALUE.ADVANCED_CLOCKING}
	set values(ADVANCED_CLOCKING) [get_property value $ADVANCED_CLOCKING]
	set_property value [gen_USERPARAMETER_CLOCKING_ADVANCED_VALUE $values(ADVANCED_CLOCKING)] $CLOCKING_ADVANCED
}

proc validate_PARAM_VALUE.CLOCKING_ADVANCED { PARAM_VALUE.CLOCKING_ADVANCED } {
	# Procedure called to validate CLOCKING_ADVANCED
	return true
}

proc update_PARAM_VALUE.ENABLE_INTR { PARAM_VALUE.ENABLE_INTR PARAM_VALUE.USED_OUTPUTS } {
	# Procedure called to update ENABLE_INTR when any of the dependent parameters in the arguments change
	
	set ENABLE_INTR ${PARAM_VALUE.ENABLE_INTR}
	set USED_OUTPUTS ${PARAM_VALUE.USED_OUTPUTS}
	set values(USED_OUTPUTS) [get_property value $USED_OUTPUTS]
	if { [gen_USERPARAMETER_ENABLE_INTR_ENABLEMENT $values(USED_OUTPUTS)] } {
		set_property enabled true $ENABLE_INTR
	} else {
		set_property enabled false $ENABLE_INTR
		set_property value [gen_USERPARAMETER_ENABLE_INTR_VALUE $values(USED_OUTPUTS)] $ENABLE_INTR
	}
}

proc validate_PARAM_VALUE.ENABLE_INTR { PARAM_VALUE.ENABLE_INTR } {
	# Procedure called to validate ENABLE_INTR
	return true
}

proc update_PARAM_VALUE.ENABLE_IRQ { PARAM_VALUE.ENABLE_IRQ PARAM_VALUE.USED_INPUTS } {
	# Procedure called to update ENABLE_IRQ when any of the dependent parameters in the arguments change
	
	set ENABLE_IRQ ${PARAM_VALUE.ENABLE_IRQ}
	set USED_INPUTS ${PARAM_VALUE.USED_INPUTS}
	set values(USED_INPUTS) [get_property value $USED_INPUTS]
	if { [gen_USERPARAMETER_ENABLE_IRQ_ENABLEMENT $values(USED_INPUTS)] } {
		set_property enabled true $ENABLE_IRQ
	} else {
		set_property enabled false $ENABLE_IRQ
		set_property value [gen_USERPARAMETER_ENABLE_IRQ_VALUE $values(USED_INPUTS)] $ENABLE_IRQ
	}
}

proc validate_PARAM_VALUE.ENABLE_IRQ { PARAM_VALUE.ENABLE_IRQ } {
	# Procedure called to validate ENABLE_IRQ
	return true
}

proc update_PARAM_VALUE.INTR_OUTPUT_ENABLED { PARAM_VALUE.INTR_OUTPUT_ENABLED PARAM_VALUE.ENABLE_INTR PARAM_VALUE.ADVANCED_CLOCKING } {
	# Procedure called to update INTR_OUTPUT_ENABLED when any of the dependent parameters in the arguments change
	
	set INTR_OUTPUT_ENABLED ${PARAM_VALUE.INTR_OUTPUT_ENABLED}
	set ENABLE_INTR ${PARAM_VALUE.ENABLE_INTR}
	set ADVANCED_CLOCKING ${PARAM_VALUE.ADVANCED_CLOCKING}
	set values(ENABLE_INTR) [get_property value $ENABLE_INTR]
	set values(ADVANCED_CLOCKING) [get_property value $ADVANCED_CLOCKING]
	set_property value [gen_USERPARAMETER_INTR_OUTPUT_ENABLED_VALUE $values(ENABLE_INTR) $values(ADVANCED_CLOCKING)] $INTR_OUTPUT_ENABLED
}

proc validate_PARAM_VALUE.INTR_OUTPUT_ENABLED { PARAM_VALUE.INTR_OUTPUT_ENABLED } {
	# Procedure called to validate INTR_OUTPUT_ENABLED
	return true
}

proc update_PARAM_VALUE.IRQ_ACK { PARAM_VALUE.IRQ_ACK PARAM_VALUE.ENABLE_IRQ } {
	# Procedure called to update IRQ_ACK when any of the dependent parameters in the arguments change
	
	set IRQ_ACK ${PARAM_VALUE.IRQ_ACK}
	set ENABLE_IRQ ${PARAM_VALUE.ENABLE_IRQ}
	set values(ENABLE_IRQ) [get_property value $ENABLE_IRQ]
	if { [gen_USERPARAMETER_IRQ_ACK_ENABLEMENT $values(ENABLE_IRQ)] } {
		set_property enabled true $IRQ_ACK
	} else {
		set_property enabled false $IRQ_ACK
		set_property value [gen_USERPARAMETER_IRQ_ACK_VALUE $values(ENABLE_IRQ)] $IRQ_ACK
	}
}

proc validate_PARAM_VALUE.IRQ_ACK { PARAM_VALUE.IRQ_ACK } {
	# Procedure called to validate IRQ_ACK
	return true
}

proc update_PARAM_VALUE.IRQ_ENABLED { PARAM_VALUE.IRQ_ENABLED PARAM_VALUE.ENABLE_IRQ } {
	# Procedure called to update IRQ_ENABLED when any of the dependent parameters in the arguments change
	
	set IRQ_ENABLED ${PARAM_VALUE.IRQ_ENABLED}
	set ENABLE_IRQ ${PARAM_VALUE.ENABLE_IRQ}
	set values(ENABLE_IRQ) [get_property value $ENABLE_IRQ]
	set_property value [gen_USERPARAMETER_IRQ_ENABLED_VALUE $values(ENABLE_IRQ)] $IRQ_ENABLED
}

proc validate_PARAM_VALUE.IRQ_ENABLED { PARAM_VALUE.IRQ_ENABLED } {
	# Procedure called to validate IRQ_ENABLED
	return true
}

proc update_PARAM_VALUE.READ_ACK { PARAM_VALUE.READ_ACK PARAM_VALUE.USED_INPUTS } {
	# Procedure called to update READ_ACK when any of the dependent parameters in the arguments change
	
	set READ_ACK ${PARAM_VALUE.READ_ACK}
	set USED_INPUTS ${PARAM_VALUE.USED_INPUTS}
	set values(USED_INPUTS) [get_property value $USED_INPUTS]
	if { [gen_USERPARAMETER_READ_ACK_ENABLEMENT $values(USED_INPUTS)] } {
		set_property enabled true $READ_ACK
	} else {
		set_property enabled false $READ_ACK
		set_property value [gen_USERPARAMETER_READ_ACK_VALUE $values(USED_INPUTS)] $READ_ACK
	}
}

proc validate_PARAM_VALUE.READ_ACK { PARAM_VALUE.READ_ACK } {
	# Procedure called to validate READ_ACK
	return true
}

proc update_PARAM_VALUE.SERIALIZE_INPUT { PARAM_VALUE.SERIALIZE_INPUT PARAM_VALUE.USED_INPUTS } {
	# Procedure called to update SERIALIZE_INPUT when any of the dependent parameters in the arguments change
	
	set SERIALIZE_INPUT ${PARAM_VALUE.SERIALIZE_INPUT}
	set USED_INPUTS ${PARAM_VALUE.USED_INPUTS}
	set values(USED_INPUTS) [get_property value $USED_INPUTS]
	if { [gen_USERPARAMETER_SERIALIZE_INPUT_ENABLEMENT $values(USED_INPUTS)] } {
		set_property enabled true $SERIALIZE_INPUT
	} else {
		set_property enabled false $SERIALIZE_INPUT
		set_property value [gen_USERPARAMETER_SERIALIZE_INPUT_VALUE $values(USED_INPUTS)] $SERIALIZE_INPUT
	}
}

proc validate_PARAM_VALUE.SERIALIZE_INPUT { PARAM_VALUE.SERIALIZE_INPUT } {
	# Procedure called to validate SERIALIZE_INPUT
	return true
}

proc update_PARAM_VALUE.SERIALIZE_INPUT_ENABLED { PARAM_VALUE.SERIALIZE_INPUT_ENABLED PARAM_VALUE.SERIALIZE_INPUT } {
	# Procedure called to update SERIALIZE_INPUT_ENABLED when any of the dependent parameters in the arguments change
	
	set SERIALIZE_INPUT_ENABLED ${PARAM_VALUE.SERIALIZE_INPUT_ENABLED}
	set SERIALIZE_INPUT ${PARAM_VALUE.SERIALIZE_INPUT}
	set values(SERIALIZE_INPUT) [get_property value $SERIALIZE_INPUT]
	set_property value [gen_USERPARAMETER_SERIALIZE_INPUT_ENABLED_VALUE $values(SERIALIZE_INPUT)] $SERIALIZE_INPUT_ENABLED
}

proc validate_PARAM_VALUE.SERIALIZE_INPUT_ENABLED { PARAM_VALUE.SERIALIZE_INPUT_ENABLED } {
	# Procedure called to validate SERIALIZE_INPUT_ENABLED
	return true
}

proc update_PARAM_VALUE.SERIALIZE_OUTPUT { PARAM_VALUE.SERIALIZE_OUTPUT PARAM_VALUE.USED_OUTPUTS } {
	# Procedure called to update SERIALIZE_OUTPUT when any of the dependent parameters in the arguments change
	
	set SERIALIZE_OUTPUT ${PARAM_VALUE.SERIALIZE_OUTPUT}
	set USED_OUTPUTS ${PARAM_VALUE.USED_OUTPUTS}
	set values(USED_OUTPUTS) [get_property value $USED_OUTPUTS]
	if { [gen_USERPARAMETER_SERIALIZE_OUTPUT_ENABLEMENT $values(USED_OUTPUTS)] } {
		set_property enabled true $SERIALIZE_OUTPUT
	} else {
		set_property enabled false $SERIALIZE_OUTPUT
		set_property value [gen_USERPARAMETER_SERIALIZE_OUTPUT_VALUE $values(USED_OUTPUTS)] $SERIALIZE_OUTPUT
	}
}

proc validate_PARAM_VALUE.SERIALIZE_OUTPUT { PARAM_VALUE.SERIALIZE_OUTPUT } {
	# Procedure called to validate SERIALIZE_OUTPUT
	return true
}

proc update_PARAM_VALUE.SERIALIZE_OUTPUT_ENABLED { PARAM_VALUE.SERIALIZE_OUTPUT_ENABLED PARAM_VALUE.SERIALIZE_OUTPUT } {
	# Procedure called to update SERIALIZE_OUTPUT_ENABLED when any of the dependent parameters in the arguments change
	
	set SERIALIZE_OUTPUT_ENABLED ${PARAM_VALUE.SERIALIZE_OUTPUT_ENABLED}
	set SERIALIZE_OUTPUT ${PARAM_VALUE.SERIALIZE_OUTPUT}
	set values(SERIALIZE_OUTPUT) [get_property value $SERIALIZE_OUTPUT]
	set_property value [gen_USERPARAMETER_SERIALIZE_OUTPUT_ENABLED_VALUE $values(SERIALIZE_OUTPUT)] $SERIALIZE_OUTPUT_ENABLED
}

proc validate_PARAM_VALUE.SERIALIZE_OUTPUT_ENABLED { PARAM_VALUE.SERIALIZE_OUTPUT_ENABLED } {
	# Procedure called to validate SERIALIZE_OUTPUT_ENABLED
	return true
}

proc update_PARAM_VALUE.USED_INPUTS { PARAM_VALUE.USED_INPUTS } {
	# Procedure called to update USED_INPUTS when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.USED_INPUTS { PARAM_VALUE.USED_INPUTS } {
	# Procedure called to validate USED_INPUTS
	return true
}

proc update_PARAM_VALUE.USED_OUTPUTS { PARAM_VALUE.USED_OUTPUTS } {
	# Procedure called to update USED_OUTPUTS when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.USED_OUTPUTS { PARAM_VALUE.USED_OUTPUTS } {
	# Procedure called to validate USED_OUTPUTS
	return true
}

proc update_PARAM_VALUE.C_S_AXI_INTR_DATA_WIDTH { PARAM_VALUE.C_S_AXI_INTR_DATA_WIDTH } {
	# Procedure called to update C_S_AXI_INTR_DATA_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_S_AXI_INTR_DATA_WIDTH { PARAM_VALUE.C_S_AXI_INTR_DATA_WIDTH } {
	# Procedure called to validate C_S_AXI_INTR_DATA_WIDTH
	return true
}

proc update_PARAM_VALUE.C_S_AXI_INTR_ADDR_WIDTH { PARAM_VALUE.C_S_AXI_INTR_ADDR_WIDTH } {
	# Procedure called to update C_S_AXI_INTR_ADDR_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_S_AXI_INTR_ADDR_WIDTH { PARAM_VALUE.C_S_AXI_INTR_ADDR_WIDTH } {
	# Procedure called to validate C_S_AXI_INTR_ADDR_WIDTH
	return true
}

proc update_PARAM_VALUE.C_NUM_OF_INTR { PARAM_VALUE.C_NUM_OF_INTR } {
	# Procedure called to update C_NUM_OF_INTR when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_NUM_OF_INTR { PARAM_VALUE.C_NUM_OF_INTR } {
	# Procedure called to validate C_NUM_OF_INTR
	return true
}

proc update_PARAM_VALUE.C_INTR_SENSITIVITY { PARAM_VALUE.C_INTR_SENSITIVITY } {
	# Procedure called to update C_INTR_SENSITIVITY when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_INTR_SENSITIVITY { PARAM_VALUE.C_INTR_SENSITIVITY } {
	# Procedure called to validate C_INTR_SENSITIVITY
	return true
}

proc update_PARAM_VALUE.C_INTR_ACTIVE_STATE { PARAM_VALUE.C_INTR_ACTIVE_STATE } {
	# Procedure called to update C_INTR_ACTIVE_STATE when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_INTR_ACTIVE_STATE { PARAM_VALUE.C_INTR_ACTIVE_STATE } {
	# Procedure called to validate C_INTR_ACTIVE_STATE
	return true
}

proc update_PARAM_VALUE.C_IRQ_SENSITIVITY { PARAM_VALUE.C_IRQ_SENSITIVITY } {
	# Procedure called to update C_IRQ_SENSITIVITY when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_IRQ_SENSITIVITY { PARAM_VALUE.C_IRQ_SENSITIVITY } {
	# Procedure called to validate C_IRQ_SENSITIVITY
	return true
}

proc update_PARAM_VALUE.C_IRQ_ACTIVE_STATE { PARAM_VALUE.C_IRQ_ACTIVE_STATE } {
	# Procedure called to update C_IRQ_ACTIVE_STATE when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_IRQ_ACTIVE_STATE { PARAM_VALUE.C_IRQ_ACTIVE_STATE } {
	# Procedure called to validate C_IRQ_ACTIVE_STATE
	return true
}

proc update_PARAM_VALUE.C_S_AXI_INTR_BASEADDR { PARAM_VALUE.C_S_AXI_INTR_BASEADDR } {
	# Procedure called to update C_S_AXI_INTR_BASEADDR when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_S_AXI_INTR_BASEADDR { PARAM_VALUE.C_S_AXI_INTR_BASEADDR } {
	# Procedure called to validate C_S_AXI_INTR_BASEADDR
	return true
}

proc update_PARAM_VALUE.C_S_AXI_INTR_HIGHADDR { PARAM_VALUE.C_S_AXI_INTR_HIGHADDR } {
	# Procedure called to update C_S_AXI_INTR_HIGHADDR when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_S_AXI_INTR_HIGHADDR { PARAM_VALUE.C_S_AXI_INTR_HIGHADDR } {
	# Procedure called to validate C_S_AXI_INTR_HIGHADDR
	return true
}

proc update_PARAM_VALUE.C_S_AXI_WRITE_DATA_WIDTH { PARAM_VALUE.C_S_AXI_WRITE_DATA_WIDTH } {
	# Procedure called to update C_S_AXI_WRITE_DATA_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_S_AXI_WRITE_DATA_WIDTH { PARAM_VALUE.C_S_AXI_WRITE_DATA_WIDTH } {
	# Procedure called to validate C_S_AXI_WRITE_DATA_WIDTH
	return true
}

proc update_PARAM_VALUE.C_S_AXI_WRITE_ADDR_WIDTH { PARAM_VALUE.C_S_AXI_WRITE_ADDR_WIDTH } {
	# Procedure called to update C_S_AXI_WRITE_ADDR_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_S_AXI_WRITE_ADDR_WIDTH { PARAM_VALUE.C_S_AXI_WRITE_ADDR_WIDTH } {
	# Procedure called to validate C_S_AXI_WRITE_ADDR_WIDTH
	return true
}

proc update_PARAM_VALUE.C_S_AXI_WRITE_BASEADDR { PARAM_VALUE.C_S_AXI_WRITE_BASEADDR } {
	# Procedure called to update C_S_AXI_WRITE_BASEADDR when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_S_AXI_WRITE_BASEADDR { PARAM_VALUE.C_S_AXI_WRITE_BASEADDR } {
	# Procedure called to validate C_S_AXI_WRITE_BASEADDR
	return true
}

proc update_PARAM_VALUE.C_S_AXI_WRITE_HIGHADDR { PARAM_VALUE.C_S_AXI_WRITE_HIGHADDR } {
	# Procedure called to update C_S_AXI_WRITE_HIGHADDR when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_S_AXI_WRITE_HIGHADDR { PARAM_VALUE.C_S_AXI_WRITE_HIGHADDR } {
	# Procedure called to validate C_S_AXI_WRITE_HIGHADDR
	return true
}

proc update_PARAM_VALUE.C_S_AXI_READ_DATA_WIDTH { PARAM_VALUE.C_S_AXI_READ_DATA_WIDTH } {
	# Procedure called to update C_S_AXI_READ_DATA_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_S_AXI_READ_DATA_WIDTH { PARAM_VALUE.C_S_AXI_READ_DATA_WIDTH } {
	# Procedure called to validate C_S_AXI_READ_DATA_WIDTH
	return true
}

proc update_PARAM_VALUE.C_S_AXI_READ_ADDR_WIDTH { PARAM_VALUE.C_S_AXI_READ_ADDR_WIDTH } {
	# Procedure called to update C_S_AXI_READ_ADDR_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_S_AXI_READ_ADDR_WIDTH { PARAM_VALUE.C_S_AXI_READ_ADDR_WIDTH } {
	# Procedure called to validate C_S_AXI_READ_ADDR_WIDTH
	return true
}

proc update_PARAM_VALUE.C_S_AXI_READ_BASEADDR { PARAM_VALUE.C_S_AXI_READ_BASEADDR } {
	# Procedure called to update C_S_AXI_READ_BASEADDR when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_S_AXI_READ_BASEADDR { PARAM_VALUE.C_S_AXI_READ_BASEADDR } {
	# Procedure called to validate C_S_AXI_READ_BASEADDR
	return true
}

proc update_PARAM_VALUE.C_S_AXI_READ_HIGHADDR { PARAM_VALUE.C_S_AXI_READ_HIGHADDR } {
	# Procedure called to update C_S_AXI_READ_HIGHADDR when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_S_AXI_READ_HIGHADDR { PARAM_VALUE.C_S_AXI_READ_HIGHADDR } {
	# Procedure called to validate C_S_AXI_READ_HIGHADDR
	return true
}


proc update_MODELPARAM_VALUE.USED_INPUTS { MODELPARAM_VALUE.USED_INPUTS PARAM_VALUE.USED_INPUTS } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.USED_INPUTS}] ${MODELPARAM_VALUE.USED_INPUTS}
}

proc update_MODELPARAM_VALUE.USED_OUTPUTS { MODELPARAM_VALUE.USED_OUTPUTS PARAM_VALUE.USED_OUTPUTS } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.USED_OUTPUTS}] ${MODELPARAM_VALUE.USED_OUTPUTS}
}

proc update_MODELPARAM_VALUE.IRQ_ENABLED { MODELPARAM_VALUE.IRQ_ENABLED PARAM_VALUE.IRQ_ENABLED } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.IRQ_ENABLED}] ${MODELPARAM_VALUE.IRQ_ENABLED}
}

proc update_MODELPARAM_VALUE.C_S_AXI_WRITE_DATA_WIDTH { MODELPARAM_VALUE.C_S_AXI_WRITE_DATA_WIDTH PARAM_VALUE.C_S_AXI_WRITE_DATA_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_S_AXI_WRITE_DATA_WIDTH}] ${MODELPARAM_VALUE.C_S_AXI_WRITE_DATA_WIDTH}
}

proc update_MODELPARAM_VALUE.C_S_AXI_WRITE_ADDR_WIDTH { MODELPARAM_VALUE.C_S_AXI_WRITE_ADDR_WIDTH PARAM_VALUE.C_S_AXI_WRITE_ADDR_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_S_AXI_WRITE_ADDR_WIDTH}] ${MODELPARAM_VALUE.C_S_AXI_WRITE_ADDR_WIDTH}
}

proc update_MODELPARAM_VALUE.C_S_AXI_READ_DATA_WIDTH { MODELPARAM_VALUE.C_S_AXI_READ_DATA_WIDTH PARAM_VALUE.C_S_AXI_READ_DATA_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_S_AXI_READ_DATA_WIDTH}] ${MODELPARAM_VALUE.C_S_AXI_READ_DATA_WIDTH}
}

proc update_MODELPARAM_VALUE.C_S_AXI_READ_ADDR_WIDTH { MODELPARAM_VALUE.C_S_AXI_READ_ADDR_WIDTH PARAM_VALUE.C_S_AXI_READ_ADDR_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_S_AXI_READ_ADDR_WIDTH}] ${MODELPARAM_VALUE.C_S_AXI_READ_ADDR_WIDTH}
}

proc update_MODELPARAM_VALUE.C_S_AXI_INTR_DATA_WIDTH { MODELPARAM_VALUE.C_S_AXI_INTR_DATA_WIDTH PARAM_VALUE.C_S_AXI_INTR_DATA_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_S_AXI_INTR_DATA_WIDTH}] ${MODELPARAM_VALUE.C_S_AXI_INTR_DATA_WIDTH}
}

proc update_MODELPARAM_VALUE.C_S_AXI_INTR_ADDR_WIDTH { MODELPARAM_VALUE.C_S_AXI_INTR_ADDR_WIDTH PARAM_VALUE.C_S_AXI_INTR_ADDR_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_S_AXI_INTR_ADDR_WIDTH}] ${MODELPARAM_VALUE.C_S_AXI_INTR_ADDR_WIDTH}
}

proc update_MODELPARAM_VALUE.C_NUM_OF_INTR { MODELPARAM_VALUE.C_NUM_OF_INTR PARAM_VALUE.C_NUM_OF_INTR } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_NUM_OF_INTR}] ${MODELPARAM_VALUE.C_NUM_OF_INTR}
}

proc update_MODELPARAM_VALUE.C_INTR_SENSITIVITY { MODELPARAM_VALUE.C_INTR_SENSITIVITY PARAM_VALUE.C_INTR_SENSITIVITY } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_INTR_SENSITIVITY}] ${MODELPARAM_VALUE.C_INTR_SENSITIVITY}
}

proc update_MODELPARAM_VALUE.C_INTR_ACTIVE_STATE { MODELPARAM_VALUE.C_INTR_ACTIVE_STATE PARAM_VALUE.C_INTR_ACTIVE_STATE } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_INTR_ACTIVE_STATE}] ${MODELPARAM_VALUE.C_INTR_ACTIVE_STATE}
}

proc update_MODELPARAM_VALUE.C_IRQ_SENSITIVITY { MODELPARAM_VALUE.C_IRQ_SENSITIVITY PARAM_VALUE.C_IRQ_SENSITIVITY } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_IRQ_SENSITIVITY}] ${MODELPARAM_VALUE.C_IRQ_SENSITIVITY}
}

proc update_MODELPARAM_VALUE.C_IRQ_ACTIVE_STATE { MODELPARAM_VALUE.C_IRQ_ACTIVE_STATE PARAM_VALUE.C_IRQ_ACTIVE_STATE } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_IRQ_ACTIVE_STATE}] ${MODELPARAM_VALUE.C_IRQ_ACTIVE_STATE}
}

proc update_MODELPARAM_VALUE.IRQ_ADVANCED { MODELPARAM_VALUE.IRQ_ADVANCED } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	# WARNING: There is no corresponding user parameter named "IRQ_ADVANCED". Setting updated value from the model parameter.
set_property value 0 ${MODELPARAM_VALUE.IRQ_ADVANCED}
}

proc update_MODELPARAM_VALUE.SERIALIZE_OUTPUT_ENABLED { MODELPARAM_VALUE.SERIALIZE_OUTPUT_ENABLED PARAM_VALUE.SERIALIZE_OUTPUT_ENABLED } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.SERIALIZE_OUTPUT_ENABLED}] ${MODELPARAM_VALUE.SERIALIZE_OUTPUT_ENABLED}
}

proc update_MODELPARAM_VALUE.SERIALIZE_INPUT_ENABLED { MODELPARAM_VALUE.SERIALIZE_INPUT_ENABLED PARAM_VALUE.SERIALIZE_INPUT_ENABLED } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.SERIALIZE_INPUT_ENABLED}] ${MODELPARAM_VALUE.SERIALIZE_INPUT_ENABLED}
}

proc update_MODELPARAM_VALUE.CLOCKING_ADVANCED { MODELPARAM_VALUE.CLOCKING_ADVANCED PARAM_VALUE.CLOCKING_ADVANCED } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.CLOCKING_ADVANCED}] ${MODELPARAM_VALUE.CLOCKING_ADVANCED}
}

proc update_MODELPARAM_VALUE.INTR_OUTPUT_ENABLED { MODELPARAM_VALUE.INTR_OUTPUT_ENABLED PARAM_VALUE.INTR_OUTPUT_ENABLED } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.INTR_OUTPUT_ENABLED}] ${MODELPARAM_VALUE.INTR_OUTPUT_ENABLED}
}

