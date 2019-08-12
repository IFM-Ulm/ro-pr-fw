# # create with the following command:
# write_bd_tcl -force -no_project_wrapper -no_ip_version cr_bd_system.tcl
# # append the following lines
# # at the start of the function:
# source -notrace [format "%s/settings_paths.tcl" [file dirname [file normalize [info script]]]]
# source -notrace [format "%s/settings_project.tcl" $project_sources_tcl]
# # after the call of the two lines"set processing_system7_0 ..." and "apply_bd_automation ..."
# ps_apply_board_settings

# # call like:
# source -quiet D:/FPGA_PUFs/RO/pynq_fw/src/bd/cr_bd_system.tcl
# cr_bd_system ""

# Proc to create BD system
proc cr_bd_system { parentCell } {

	source -notrace [format "%s/settings_paths.tcl" [file dirname [file normalize [info script]]]]
	source -notrace [format "%s/settings_compability.tcl" $project_sources_tcl]

  # CHANGE DESIGN NAME HERE
  set design_name system

  common::send_msg_id "BD_TCL-003" "INFO" "Currently there is no design <$design_name> in project, so creating one..."

  create_bd_design $design_name

  set bCheckIPsPassed 1
  ##################################################################
  # CHECK IPs
  ##################################################################
  set bCheckIPs 1
  if { $bCheckIPs == 1 } {
     set list_check_ips "\ 
  uni-ulm.de:aherkle:AH_CPU2PL:*\
  uni-ulm.de:aherkle:AH_PL2DDR:*\
  xilinx.com:ip:axi_gpio:*\
  xilinx.com:ip:smartconnect:*\
  xilinx.com:ip:xlconcat:*\
  xilinx.com:ip:xlconstant:*\
  xilinx.com:ip:pr_decoupler:*\
  xilinx.com:ip:processing_system7:*\
  xilinx.com:ip:proc_sys_reset:*\
  xilinx.com:ip:xlslice:*\
  xilinx.com:ip:xadc_wiz:*\
  "

   set list_ips_missing ""
   common::send_msg_id "BD_TCL-006" "INFO" "Checking if the following IPs exist in the project's IP catalog: $list_check_ips ."

   foreach ip_vlnv $list_check_ips {
      set ip_obj [get_ipdefs -all $ip_vlnv]
      if { $ip_obj eq "" } {
         lappend list_ips_missing $ip_vlnv
      }
   }

   if { $list_ips_missing ne "" } {
      catch {common::send_msg_id "BD_TCL-115" "ERROR" "The following IPs are not found in the IP Catalog:\n  $list_ips_missing\n\nResolution: Please add the repository containing the IP(s) to the project." }
      set bCheckIPsPassed 0
   }

  }

  if { $bCheckIPsPassed != 1 } {
    common::send_msg_id "BD_TCL-1003" "WARNING" "Will not continue with creation of design due to the error(s) above."
    return 3
  }

  variable script_folder

  if { $parentCell eq "" } {
     set parentCell [get_bd_cells /]
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_msg_id "BD_TCL-100" "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_msg_id "BD_TCL-101" "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj

  # Create interface ports
  set btns_4bits [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:gpio_rtl:1.0 btns_4bits ]
  set leds_4bits [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:gpio_rtl:1.0 leds_4bits ]
  set sws_4bits [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:gpio_rtl:1.0 sws_4bits ]

  # Create ports
  set data_en [ create_bd_port -dir I -type data data_en ]
  set data_in [ create_bd_port -dir I -from 31 -to 0 -type data data_in ]
  set meas_cmd [ create_bd_port -dir O -from 31 -to 0 -type data meas_cmd ]
  set meas_cooldown [ create_bd_port -dir O -from 31 -to 0 -type data meas_cooldown ]
  set meas_done [ create_bd_port -dir I meas_done ]
  set meas_heatup [ create_bd_port -dir O -from 31 -to 0 -type data meas_heatup ]
  set meas_mode [ create_bd_port -dir O -from 31 -to 0 -type data meas_mode ]
  set meas_readouts [ create_bd_port -dir O -from 31 -to 0 -type data meas_readouts ]
  set meas_time [ create_bd_port -dir O -from 31 -to 0 -type data meas_time ]
  set sys_clk0 [ create_bd_port -dir O -type clk sys_clk0 ]
  set sys_decouple [ create_bd_port -dir O sys_decouple ]
  set sys_reset [ create_bd_port -dir O -from 0 -to 0 -type rst sys_reset ]
  set sys_resetn [ create_bd_port -dir O -from 0 -to 0 -type rst sys_resetn ]
  set transfer_active [ create_bd_port -dir O -type data transfer_active ]
  set transfer_en [ create_bd_port -dir I -type data transfer_en ]

  # Create instance: AH_CPU2PL_0, and set properties
  set AH_CPU2PL_0 [ create_bd_cell -type ip -vlnv uni-ulm.de:aherkle:AH_CPU2PL AH_CPU2PL_0 ]
  set_property -dict [ list \
   CONFIG.ADVANCED_CLOCKING {false} \
   CONFIG.ENABLE_INTR {true} \
   CONFIG.ENABLE_IRQ {true} \
   CONFIG.IRQ_ACK {false} \
   CONFIG.IRQ_ENABLED {1} \
   CONFIG.READ_ACK {false} \
   CONFIG.SERIALIZE_INPUT {false} \
   CONFIG.SERIALIZE_INPUT_ENABLED {0} \
   CONFIG.SERIALIZE_OUTPUT {false} \
   CONFIG.SERIALIZE_OUTPUT_ENABLED {0} \
   CONFIG.USED_INPUTS {1} \
   CONFIG.USED_OUTPUTS {11} \
 ] $AH_CPU2PL_0

  # Create instance: AH_PL2DDR_0, and set properties
  set AH_PL2DDR_0 [ create_bd_cell -type ip -vlnv uni-ulm.de:aherkle:AH_PL2DDR AH_PL2DDR_0 ]
  set_property -dict [ list \
   CONFIG.DATA_WIDTH {32} \
   CONFIG.ENABLE_ADDRESS_INPUT {true} \
   CONFIG.ENABLE_CMD_INPUT {true} \
   CONFIG.ENABLE_DEBUG_OUTPUT {true} \
   CONFIG.ENABLE_ERROR_OUTPUT {true} \
   CONFIG.ENABLE_INFO_OUTPUT {true} \
   CONFIG.ENABLE_INTR_DONE {true} \
   CONFIG.ENABLE_INTR_SENT {true} \
   CONFIG.ENABLE_MODE_INPUT {true} \
   CONFIG.ENABLE_SAMPLES_INPUT {true} \
   CONFIG.ENABLE_TRANSFER_CONTROL {true} \
 ] $AH_PL2DDR_0

  # Create instance: axi_gpio_0, and set properties
  # set axi_gpio_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_gpio axi_gpio_0 ]
  # set_property -dict [ list \
   # CONFIG.C_GPIO_WIDTH {4} \
   # CONFIG.GPIO_BOARD_INTERFACE {leds_4bits} \
   # CONFIG.USE_BOARD_FLOW {true} \
 # ] $axi_gpio_0

  # Create instance: axi_gpio_1, and set properties
  # set axi_gpio_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_gpio axi_gpio_1 ]
  # set_property -dict [ list \
   # CONFIG.C_ALL_INPUTS {1} \
   # CONFIG.C_GPIO_WIDTH {4} \
   # CONFIG.GPIO_BOARD_INTERFACE {btns_4bits} \
   # CONFIG.USE_BOARD_FLOW {true} \
 # ] $axi_gpio_1

  # Create instance: axi_gpio_2, and set properties
  # set axi_gpio_2 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_gpio axi_gpio_2 ]
  # set_property -dict [ list \
   # CONFIG.C_ALL_INPUTS {1} \
   # CONFIG.C_GPIO_WIDTH {4} \
   # CONFIG.GPIO_BOARD_INTERFACE {sws_4bits} \
   # CONFIG.USE_BOARD_FLOW {true} \
 # ] $axi_gpio_2

  # Create instance: axi_smc, and set properties
  set axi_smc [ create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect axi_smc ]
  set_property -dict [ list \
   CONFIG.NUM_SI {1} \
 ] $axi_smc

  # Create instance: concat_irq, and set properties
  set concat_irq [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat concat_irq ]
  set_property -dict [ list \
   CONFIG.NUM_PORTS {3} \
 ] $concat_irq

  # Create instance: const_32b0, and set properties
  set const_32b0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant const_32b0 ]
  set_property -dict [ list \
   CONFIG.CONST_VAL {0} \
   CONFIG.CONST_WIDTH {32} \
 ] $const_32b0

  # Create instance: pr_decoupler_0, and set properties
  set pr_decoupler_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:pr_decoupler pr_decoupler_0 ]
  set_property -dict [ list \
   CONFIG.ALL_PARAMS {HAS_AXI_LITE 1 HAS_SIGNAL_CONTROL 0 HAS_SIGNAL_STATUS 1 INTF {}} \
   CONFIG.GUI_HAS_AXI_LITE {1} \
   CONFIG.GUI_HAS_SIGNAL_CONTROL {0} \
   CONFIG.GUI_HAS_SIGNAL_STATUS {1} \
   CONFIG.GUI_INTERFACE_NAME { } \
   CONFIG.GUI_SELECT_INTERFACE {-1} \
   CONFIG.GUI_SIGNAL_DECOUPLED_0 {false} \
   CONFIG.GUI_SIGNAL_DECOUPLED_1 {false} \
   CONFIG.GUI_SIGNAL_DECOUPLED_2 {false} \
   CONFIG.GUI_SIGNAL_DECOUPLED_3 {false} \
   CONFIG.GUI_SIGNAL_DECOUPLED_4 {false} \
   CONFIG.GUI_SIGNAL_DIRECTION_0 {s} \
   CONFIG.GUI_SIGNAL_DIRECTION_1 {s} \
   CONFIG.GUI_SIGNAL_DIRECTION_2 {s} \
   CONFIG.GUI_SIGNAL_DIRECTION_3 {s} \
   CONFIG.GUI_SIGNAL_DIRECTION_4 {s} \
   CONFIG.GUI_SIGNAL_MANAGEMENT_0 {auto} \
   CONFIG.GUI_SIGNAL_MANAGEMENT_1 {auto} \
   CONFIG.GUI_SIGNAL_MANAGEMENT_2 {auto} \
   CONFIG.GUI_SIGNAL_MANAGEMENT_3 {auto} \
   CONFIG.GUI_SIGNAL_MANAGEMENT_4 {auto} \
   CONFIG.GUI_SIGNAL_PRESENT_0 {false} \
   CONFIG.GUI_SIGNAL_PRESENT_1 {false} \
   CONFIG.GUI_SIGNAL_PRESENT_2 {false} \
   CONFIG.GUI_SIGNAL_PRESENT_3 {false} \
   CONFIG.GUI_SIGNAL_PRESENT_4 {false} \
   CONFIG.GUI_SIGNAL_SELECT_0 {-1} \
   CONFIG.GUI_SIGNAL_SELECT_1 {-1} \
   CONFIG.GUI_SIGNAL_SELECT_2 {-1} \
   CONFIG.GUI_SIGNAL_SELECT_3 {-1} \
   CONFIG.GUI_SIGNAL_SELECT_4 {-1} \
   CONFIG.GUI_SIGNAL_WIDTH_0 {1} \
   CONFIG.GUI_SIGNAL_WIDTH_1 {1} \
   CONFIG.GUI_SIGNAL_WIDTH_2 {1} \
   CONFIG.GUI_SIGNAL_WIDTH_3 {1} \
   CONFIG.GUI_SIGNAL_WIDTH_4 {1} \
 ] $pr_decoupler_0

  # Create instance: processing_system7_0, and set properties
  set processing_system7_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:processing_system7 processing_system7_0 ]
  apply_bd_automation -rule xilinx.com:bd_rule:processing_system7 -config {make_external "FIXED_IO, DDR" apply_board_preset "1" Master "Disable" Slave "Disable" }  $processing_system7_0
  
	# from settings_project.tcl
	ps_apply_board_settings


  # Create instance: ps7_0_axi_periph, and set properties
  set ps7_0_axi_periph [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect ps7_0_axi_periph ]
  set_property -dict [ list \
   CONFIG.NUM_MI {5} \
 ] $ps7_0_axi_periph

  # Create instance: rst_ps7_0_100M, and set properties
  set rst_ps7_0_100M [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset rst_ps7_0_100M ]

  # Create instance: slice_cmd_end, and set properties
  set slice_cmd_end [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice slice_cmd_end ]
  set_property -dict [ list \
   CONFIG.DIN_FROM {0} \
   CONFIG.DIN_TO {0} \
   CONFIG.DIN_WIDTH {11} \
 ] $slice_cmd_end

  # Create instance: xadc_wiz_0, and set properties
  set xadc_wiz_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xadc_wiz xadc_wiz_0 ]
  set_property -dict [ list \
   CONFIG.ADC_OFFSET_CALIBRATION {true} \
   CONFIG.AVERAGE_ENABLE_TEMPERATURE {true} \
   CONFIG.AVERAGE_ENABLE_VCCINT {true} \
   CONFIG.CHANNEL_AVERAGING {16} \
   CONFIG.CHANNEL_ENABLE_CALIBRATION {true} \
   CONFIG.CHANNEL_ENABLE_TEMPERATURE {true} \
   CONFIG.CHANNEL_ENABLE_VCCINT {true} \
   CONFIG.CHANNEL_ENABLE_VP_VN {false} \
   CONFIG.ENABLE_VCCDDRO_ALARM {false} \
   CONFIG.ENABLE_VCCPAUX_ALARM {false} \
   CONFIG.ENABLE_VCCPINT_ALARM {false} \
   CONFIG.EXTERNAL_MUX_CHANNEL {VP_VN} \
   CONFIG.OT_ALARM {false} \
   CONFIG.SENSOR_OFFSET_CALIBRATION {true} \
   CONFIG.SEQUENCER_MODE {Continuous} \
   CONFIG.SINGLE_CHANNEL_SELECTION {TEMPERATURE} \
   CONFIG.USER_TEMP_ALARM {false} \
   CONFIG.VCCAUX_ALARM {false} \
   CONFIG.VCCINT_ALARM {false} \
   CONFIG.XADC_STARUP_SELECTION {channel_sequencer} \
 ] $xadc_wiz_0

  set_property -dict [ list \
   CONFIG.SUPPORTS_NARROW_BURST {0} \
   CONFIG.NUM_READ_OUTSTANDING {1} \
   CONFIG.NUM_WRITE_OUTSTANDING {1} \
   CONFIG.MAX_BURST_LENGTH {1} \
 ] [get_bd_intf_pins /xadc_wiz_0/s_axi_lite]

  # Create interface connections
  connect_bd_intf_net -intf_net AH_PL2DDR_1_M_AXI_OUT [get_bd_intf_pins AH_PL2DDR_0/M_AXI_OUT] [get_bd_intf_pins axi_smc/S00_AXI]
  # connect_bd_intf_net -intf_net axi_gpio_0_GPIO [get_bd_intf_ports leds_4bits] [get_bd_intf_pins axi_gpio_0/GPIO]
  # connect_bd_intf_net -intf_net axi_gpio_1_GPIO [get_bd_intf_ports btns_4bits] [get_bd_intf_pins axi_gpio_1/GPIO]
  # connect_bd_intf_net -intf_net axi_gpio_2_GPIO [get_bd_intf_ports sws_4bits] [get_bd_intf_pins axi_gpio_2/GPIO]
  connect_bd_intf_net -intf_net axi_smc_M00_AXI [get_bd_intf_pins axi_smc/M00_AXI] [get_bd_intf_pins processing_system7_0/S_AXI_HP0]
  # connect_bd_intf_net -intf_net processing_system7_0_DDR [get_bd_intf_ports DDR] [get_bd_intf_pins processing_system7_0/DDR]
  # connect_bd_intf_net -intf_net processing_system7_0_FIXED_IO [get_bd_intf_ports FIXED_IO] [get_bd_intf_pins processing_system7_0/FIXED_IO]
  connect_bd_intf_net -intf_net processing_system7_0_M_AXI_GP0 [get_bd_intf_pins processing_system7_0/M_AXI_GP0] [get_bd_intf_pins ps7_0_axi_periph/S00_AXI]
  connect_bd_intf_net -intf_net ps7_0_axi_periph_M00_AXI [get_bd_intf_pins ps7_0_axi_periph/M00_AXI] [get_bd_intf_pins xadc_wiz_0/s_axi_lite]
  connect_bd_intf_net -intf_net ps7_0_axi_periph_M01_AXI [get_bd_intf_pins AH_CPU2PL_0/S_AXI_WRITE] [get_bd_intf_pins ps7_0_axi_periph/M01_AXI]
  connect_bd_intf_net -intf_net ps7_0_axi_periph_M02_AXI [get_bd_intf_pins AH_CPU2PL_0/S_AXI_READ] [get_bd_intf_pins ps7_0_axi_periph/M02_AXI]
  connect_bd_intf_net -intf_net ps7_0_axi_periph_M03_AXI [get_bd_intf_pins AH_CPU2PL_0/S_AXI_INTR] [get_bd_intf_pins ps7_0_axi_periph/M03_AXI]
  connect_bd_intf_net -intf_net ps7_0_axi_periph_M04_AXI [get_bd_intf_pins pr_decoupler_0/s_axi_reg] [get_bd_intf_pins ps7_0_axi_periph/M04_AXI]
  # connect_bd_intf_net -intf_net ps7_0_axi_periph_M05_AXI [get_bd_intf_pins axi_gpio_0/S_AXI] [get_bd_intf_pins ps7_0_axi_periph/M05_AXI]
  # connect_bd_intf_net -intf_net ps7_0_axi_periph_M06_AXI [get_bd_intf_pins axi_gpio_1/S_AXI] [get_bd_intf_pins ps7_0_axi_periph/M06_AXI]
  # connect_bd_intf_net -intf_net ps7_0_axi_periph_M07_AXI [get_bd_intf_pins axi_gpio_2/S_AXI] [get_bd_intf_pins ps7_0_axi_periph/M07_AXI]

  # Create port connections
  connect_bd_net -net AH_CPU2PL_0_intr_output [get_bd_pins AH_CPU2PL_0/intr_output] [get_bd_pins slice_cmd_end/Din]
  connect_bd_net -net AH_CPU2PL_0_irq [get_bd_pins AH_CPU2PL_0/irq] [get_bd_pins concat_irq/In0]
  connect_bd_net -net AH_CPU2PL_0_output_0 [get_bd_pins AH_CPU2PL_0/output_0] [get_bd_pins AH_PL2DDR_0/cmd_in]
  connect_bd_net -net AH_CPU2PL_0_output_1 [get_bd_pins AH_CPU2PL_0/output_1] [get_bd_pins AH_PL2DDR_0/sampling_mode]
  connect_bd_net -net AH_CPU2PL_0_output_2 [get_bd_pins AH_CPU2PL_0/output_2] [get_bd_pins AH_PL2DDR_0/number_samples]
  connect_bd_net -net AH_CPU2PL_0_output_3 [get_bd_pins AH_CPU2PL_0/output_3] [get_bd_pins AH_PL2DDR_0/ddr_addr_low]
  connect_bd_net -net AH_CPU2PL_0_output_4 [get_bd_pins AH_CPU2PL_0/output_4] [get_bd_pins AH_PL2DDR_0/ddr_addr_high]
  connect_bd_net -net AH_CPU2PL_0_output_5 [get_bd_ports meas_cmd] [get_bd_pins AH_CPU2PL_0/output_5]
  connect_bd_net -net AH_CPU2PL_0_output_6 [get_bd_ports meas_mode] [get_bd_pins AH_CPU2PL_0/output_6]
  connect_bd_net -net AH_CPU2PL_0_output_7 [get_bd_ports meas_time] [get_bd_pins AH_CPU2PL_0/output_7]
  connect_bd_net -net AH_CPU2PL_0_output_8 [get_bd_ports meas_readouts] [get_bd_pins AH_CPU2PL_0/output_8]
  connect_bd_net -net AH_CPU2PL_0_output_9 [get_bd_ports meas_heatup] [get_bd_pins AH_CPU2PL_0/output_9]
  connect_bd_net -net AH_CPU2PL_0_output_10 [get_bd_ports meas_cooldown] [get_bd_pins AH_CPU2PL_0/output_10]
  connect_bd_net -net AH_PL2DDR_0_intr_done [get_bd_pins AH_PL2DDR_0/intr_done] [get_bd_pins concat_irq/In2]
  connect_bd_net -net AH_PL2DDR_0_intr_sent [get_bd_pins AH_PL2DDR_0/intr_sent] [get_bd_pins concat_irq/In1]
  connect_bd_net -net AH_PL2DDR_0_transfer_active [get_bd_ports transfer_active] [get_bd_pins AH_PL2DDR_0/transfer_active]
  connect_bd_net -net const_32b0_dout [get_bd_pins AH_CPU2PL_0/input_0] [get_bd_pins const_32b0/dout]
  connect_bd_net -net data_en_1 [get_bd_ports data_en] [get_bd_pins AH_PL2DDR_0/data_en]
  connect_bd_net -net data_in_1 [get_bd_ports data_in] [get_bd_pins AH_PL2DDR_0/data_in]
  connect_bd_net -net meas_done_1 [get_bd_ports meas_done] [get_bd_pins AH_CPU2PL_0/intr_input]
  connect_bd_net -net pr_decoupler_0_decouple_status [get_bd_ports sys_decouple] [get_bd_pins pr_decoupler_0/decouple_status]
  # connect_bd_net -net processing_system7_0_FCLK_CLK0 [get_bd_ports sys_clk0] [get_bd_pins AH_CPU2PL_0/s_axi_intr_aclk] [get_bd_pins AH_CPU2PL_0/s_axi_read_aclk] [get_bd_pins AH_CPU2PL_0/s_axi_write_aclk] [get_bd_pins AH_PL2DDR_0/clk_data] [get_bd_pins AH_PL2DDR_0/m_axi_out_aclk] [get_bd_pins axi_gpio_0/s_axi_aclk] [get_bd_pins axi_gpio_1/s_axi_aclk] [get_bd_pins axi_gpio_2/s_axi_aclk] [get_bd_pins axi_smc/aclk] [get_bd_pins pr_decoupler_0/aclk] [get_bd_pins processing_system7_0/FCLK_CLK0] [get_bd_pins processing_system7_0/M_AXI_GP0_ACLK] [get_bd_pins processing_system7_0/S_AXI_HP0_ACLK] [get_bd_pins ps7_0_axi_periph/ACLK] [get_bd_pins ps7_0_axi_periph/M00_ACLK] [get_bd_pins ps7_0_axi_periph/M01_ACLK] [get_bd_pins ps7_0_axi_periph/M02_ACLK] [get_bd_pins ps7_0_axi_periph/M03_ACLK] [get_bd_pins ps7_0_axi_periph/M04_ACLK] [get_bd_pins ps7_0_axi_periph/M05_ACLK] [get_bd_pins ps7_0_axi_periph/M06_ACLK] [get_bd_pins ps7_0_axi_periph/M07_ACLK] [get_bd_pins ps7_0_axi_periph/S00_ACLK] [get_bd_pins rst_ps7_0_100M/slowest_sync_clk] [get_bd_pins xadc_wiz_0/s_axi_aclk]
  connect_bd_net -net processing_system7_0_FCLK_CLK0 [get_bd_ports sys_clk0] [get_bd_pins AH_CPU2PL_0/s_axi_intr_aclk] [get_bd_pins AH_CPU2PL_0/s_axi_read_aclk] [get_bd_pins AH_CPU2PL_0/s_axi_write_aclk] [get_bd_pins AH_PL2DDR_0/clk_data] [get_bd_pins AH_PL2DDR_0/m_axi_out_aclk] [get_bd_pins axi_smc/aclk] [get_bd_pins pr_decoupler_0/aclk] [get_bd_pins processing_system7_0/FCLK_CLK0] [get_bd_pins processing_system7_0/M_AXI_GP0_ACLK] [get_bd_pins processing_system7_0/S_AXI_HP0_ACLK] [get_bd_pins ps7_0_axi_periph/ACLK] [get_bd_pins ps7_0_axi_periph/M00_ACLK] [get_bd_pins ps7_0_axi_periph/M01_ACLK] [get_bd_pins ps7_0_axi_periph/M02_ACLK] [get_bd_pins ps7_0_axi_periph/M03_ACLK] [get_bd_pins ps7_0_axi_periph/M04_ACLK] [get_bd_pins ps7_0_axi_periph/M05_ACLK] [get_bd_pins ps7_0_axi_periph/M06_ACLK] [get_bd_pins ps7_0_axi_periph/M07_ACLK] [get_bd_pins ps7_0_axi_periph/S00_ACLK] [get_bd_pins rst_ps7_0_100M/slowest_sync_clk] [get_bd_pins xadc_wiz_0/s_axi_aclk]
  connect_bd_net -net processing_system7_0_FCLK_RESET0_N [get_bd_pins processing_system7_0/FCLK_RESET0_N] [get_bd_pins rst_ps7_0_100M/ext_reset_in]
  # connect_bd_net -net rst_ps7_0_100M_peripheral_aresetn [get_bd_ports sys_resetn] [get_bd_pins AH_CPU2PL_0/s_axi_intr_aresetn] [get_bd_pins AH_CPU2PL_0/s_axi_read_aresetn] [get_bd_pins AH_CPU2PL_0/s_axi_write_aresetn] [get_bd_pins AH_PL2DDR_0/m_axi_out_aresetn] [get_bd_pins axi_gpio_0/s_axi_aresetn] [get_bd_pins axi_gpio_1/s_axi_aresetn] [get_bd_pins axi_gpio_2/s_axi_aresetn] [get_bd_pins axi_smc/aresetn] [get_bd_pins pr_decoupler_0/s_axi_reg_aresetn] [get_bd_pins ps7_0_axi_periph/ARESETN] [get_bd_pins ps7_0_axi_periph/M00_ARESETN] [get_bd_pins ps7_0_axi_periph/M01_ARESETN] [get_bd_pins ps7_0_axi_periph/M02_ARESETN] [get_bd_pins ps7_0_axi_periph/M03_ARESETN] [get_bd_pins ps7_0_axi_periph/M04_ARESETN] [get_bd_pins ps7_0_axi_periph/M05_ARESETN] [get_bd_pins ps7_0_axi_periph/M06_ARESETN] [get_bd_pins ps7_0_axi_periph/M07_ARESETN] [get_bd_pins ps7_0_axi_periph/S00_ARESETN] [get_bd_pins rst_ps7_0_100M/peripheral_aresetn] [get_bd_pins xadc_wiz_0/s_axi_aresetn]
  connect_bd_net -net rst_ps7_0_100M_peripheral_aresetn [get_bd_ports sys_resetn] [get_bd_pins AH_CPU2PL_0/s_axi_intr_aresetn] [get_bd_pins AH_CPU2PL_0/s_axi_read_aresetn] [get_bd_pins AH_CPU2PL_0/s_axi_write_aresetn] [get_bd_pins AH_PL2DDR_0/m_axi_out_aresetn] [get_bd_pins axi_smc/aresetn] [get_bd_pins pr_decoupler_0/s_axi_reg_aresetn] [get_bd_pins ps7_0_axi_periph/ARESETN] [get_bd_pins ps7_0_axi_periph/M00_ARESETN] [get_bd_pins ps7_0_axi_periph/M01_ARESETN] [get_bd_pins ps7_0_axi_periph/M02_ARESETN] [get_bd_pins ps7_0_axi_periph/M03_ARESETN] [get_bd_pins ps7_0_axi_periph/M04_ARESETN] [get_bd_pins ps7_0_axi_periph/M05_ARESETN] [get_bd_pins ps7_0_axi_periph/M06_ARESETN] [get_bd_pins ps7_0_axi_periph/M07_ARESETN] [get_bd_pins ps7_0_axi_periph/S00_ARESETN] [get_bd_pins rst_ps7_0_100M/peripheral_aresetn] [get_bd_pins xadc_wiz_0/s_axi_aresetn]
  connect_bd_net -net rst_ps7_0_100M_peripheral_reset [get_bd_ports sys_reset] [get_bd_pins rst_ps7_0_100M/peripheral_reset]
  connect_bd_net -net transfer_en_1 [get_bd_ports transfer_en] [get_bd_pins AH_PL2DDR_0/transfer_en]
  connect_bd_net -net xlconcat_0_dout [get_bd_pins concat_irq/dout] [get_bd_pins processing_system7_0/IRQ_F2P]
  connect_bd_net -net xlslice_2_Dout [get_bd_pins AH_PL2DDR_0/cmd_en] [get_bd_pins slice_cmd_end/Dout]

  # Create address segments
  create_bd_addr_seg -range 0x20000000 -offset 0x00000000 [get_bd_addr_spaces AH_PL2DDR_0/M_AXI_OUT] [get_bd_addr_segs processing_system7_0/S_AXI_HP0/HP0_DDR_LOWOCM] SEG_processing_system7_0_HP0_DDR_LOWOCM
  create_bd_addr_seg -range 0x00010000 -offset 0x43C30000 [get_bd_addr_spaces processing_system7_0/Data] [get_bd_addr_segs AH_CPU2PL_0/S_AXI_INTR/S_AXI_INTR_reg] SEG_AH_CPU2PL_0_S_AXI_INTR_reg
  create_bd_addr_seg -range 0x00010000 -offset 0x43C20000 [get_bd_addr_spaces processing_system7_0/Data] [get_bd_addr_segs AH_CPU2PL_0/S_AXI_READ/S_AXI_READ_reg] SEG_AH_CPU2PL_0_S_AXI_READ_reg
  create_bd_addr_seg -range 0x00010000 -offset 0x43C10000 [get_bd_addr_spaces processing_system7_0/Data] [get_bd_addr_segs AH_CPU2PL_0/S_AXI_WRITE/S_AXI_WRITE_reg] SEG_AH_CPU2PL_0_S_AXI_WRITE_reg
  # create_bd_addr_seg -range 0x00010000 -offset 0x41200000 [get_bd_addr_spaces processing_system7_0/Data] [get_bd_addr_segs axi_gpio_0/S_AXI/Reg] SEG_axi_gpio_0_Reg
  # create_bd_addr_seg -range 0x00010000 -offset 0x41210000 [get_bd_addr_spaces processing_system7_0/Data] [get_bd_addr_segs axi_gpio_1/S_AXI/Reg] SEG_axi_gpio_1_Reg
  # create_bd_addr_seg -range 0x00010000 -offset 0x41220000 [get_bd_addr_spaces processing_system7_0/Data] [get_bd_addr_segs axi_gpio_2/S_AXI/Reg] SEG_axi_gpio_2_Reg
  create_bd_addr_seg -range 0x00010000 -offset 0x43C40000 [get_bd_addr_spaces processing_system7_0/Data] [get_bd_addr_segs pr_decoupler_0/s_axi_reg/Reg] SEG_pr_decoupler_0_Reg
  create_bd_addr_seg -range 0x00010000 -offset 0x43C00000 [get_bd_addr_spaces processing_system7_0/Data] [get_bd_addr_segs xadc_wiz_0/s_axi_lite/Reg] SEG_xadc_wiz_0_Reg


  # Restore current instance
  current_bd_instance $oldCurInst

  save_bd_design
  close_bd_design $design_name 
}
# End of cr_bd_system()