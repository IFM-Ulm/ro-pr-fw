#include "fw_hw.h"

#include <stdio.h>

#include "ah_scugic.h"
#include "ah_pcap.h"
#include "ah_gpio.h"
#include "ah_sd.h"

#include "ah_cpu2pl.h"
#include "ah_pl2ddr.h"

#include "fw_settings.h"

#define MAX_BUFFER_BYTES 469762048

#define INTERRUPT_MEASUREMENT_DONE (0)
#define INTERRUPT_TRANSFER_DONE (1)
#define INTERRUPT_CNT (2)

#define PORT_CPU2PL_INTR_MEAS (0)
#define PORT_CPU2PL_CMD (5)
#define PORT_CPU2PL_MODE (6)
#define PORT_CPU2PL_TIME (7)
#define PORT_CPU2PL_READOUTS (8)
#define PORT_CPU2PL_HEATUP (9)
#define PORT_CPU2PL_COOLDOWN (10)

#define CPU2PL_CMD_START (1)
#define CPU2PL_CMD_STOP (0)

#define PORT_PL2DDR_CMD (0)
#define PORT_PL2DDR_MODE (1)
#define PORT_PL2DDR_SAMPLES (2)
#define PORT_PL2DDR_ADDR_LOW (3)
#define PORT_PL2DDR_ADDR_HIGH (4)

struct binfile* binfile_list = NULL;
struct binfile* binfile_current = NULL;

u8 data_buffer[MAX_BUFFER_BYTES];
u32 number_samples = 0;
u32 buffer_start = 0;
u32 buffer_end = 0;

u32 data_received = 0;

// array for storing the interrupts occured
volatile u8 interrupts[INTERRUPT_CNT];

u8 file_bytes[4194304]; // maximum file size = 4MB

void interrupt_cpu2pl(AH_CPU2PL_inst* inst, u32 id){
	if(id == PORT_CPU2PL_INTR_MEAS){
		interrupts[INTERRUPT_MEASUREMENT_DONE] = TRUE;
	}
}

void interrupt_pl2ddr(void* inst){
	interrupts[INTERRUPT_TRANSFER_DONE] = TRUE;
}

s32 hardware_init(void){

	if(ah_pcap_init() != XST_SUCCESS){
		return XST_FAILURE;
	}

	if(ah_cpu2pl_init() != XST_SUCCESS){
		return XST_FAILURE;
	}

	return XST_SUCCESS;
}

s32 hardware_setup(void){

	if(ah_cpu2pl_setup(0) != XST_SUCCESS){
		return XST_FAILURE;
	}

	if(ah_cpu2pl_setup_interruptFunction(XPAR_AH_CPU2PL_0_DEVICE_ID, interrupt_cpu2pl)!= XST_SUCCESS){
		return XST_FAILURE;
	}

	if(ah_cpu2pl_setup_interruptPort(XPAR_AH_CPU2PL_0_DEVICE_ID, PORT_CPU2PL_INTR_MEAS, TRUE)!= XST_SUCCESS){
		return XST_FAILURE;
	}

	if(ah_scugic_setup_connectHandler(XPAR_FABRIC_AH_PL2DDR_0_INTR_DONE_INTR, interrupt_pl2ddr, NULL) != XST_SUCCESS){
		return XST_FAILURE;
	}

	if(ah_scugic_setup_setInterruptTriggerType(XPAR_FABRIC_AH_PL2DDR_0_INTR_DONE_INTR, INTR_TRIGGER_EDGE_RISING) != XST_SUCCESS){
		return XST_FAILURE;
	}
	
	if(ah_scugic_setup_enableHandler(XPAR_FABRIC_AH_PL2DDR_0_INTR_DONE_INTR)!= XST_SUCCESS){
		return XST_FAILURE;
	}
	
	if(ah_cpu2pl_write(XPAR_AH_CPU2PL_0_DEVICE_ID, PORT_PL2DDR_MODE, MODE_SAMPLED)!= XST_SUCCESS){
		return XST_FAILURE;
	}

	if(ah_cpu2pl_write(XPAR_AH_CPU2PL_0_DEVICE_ID, PORT_PL2DDR_CMD, CMD_INTR_ONDONE_ENABLE)!= XST_SUCCESS){
		return XST_FAILURE;
	}

	return XST_SUCCESS;
}



s32 hardware_reset(void){
	
	interrupts[INTERRUPT_MEASUREMENT_DONE] = FALSE;
	interrupts[INTERRUPT_TRANSFER_DONE] = FALSE;

	data_received = 0;

	if(ah_cpu2pl_write(XPAR_AH_CPU2PL_0_DEVICE_ID, PORT_CPU2PL_CMD, CPU2PL_CMD_STOP) != XST_SUCCESS){
		return XST_FAILURE;
	}

	if(ah_cpu2pl_write(XPAR_AH_CPU2PL_0_DEVICE_ID, PORT_PL2DDR_CMD, CMD_DISABLE) != XST_SUCCESS){
		return XST_FAILURE;
	}

	if(ah_cpu2pl_write(XPAR_AH_CPU2PL_0_DEVICE_ID, PORT_PL2DDR_CMD, CMD_RST_DATA) != XST_SUCCESS){
		return XST_FAILURE;
	}

	if(ah_cpu2pl_write(XPAR_AH_CPU2PL_0_DEVICE_ID, PORT_PL2DDR_CMD, CMD_RST_ADDR) != XST_SUCCESS){
		return XST_FAILURE;
	}

	return XST_SUCCESS;
}


s32 hardware_measurement_setup(u8 meas_mode, u32 meas_readouts, u32 meas_time, u32 meas_heatup, u32 meas_cooldown){
	
	u32 ddr_addr_low = (u32)data_buffer;
	u32 ddr_addr_high = (u32)data_buffer + (u32)MAX_BUFFER_BYTES;

	if(meas_mode != READOUT_MASK_SEQ && meas_mode != READOUT_MASK_PAR){
		return XST_FAILURE;
	}

	if(hardware_reset() != XST_SUCCESS){
		return XST_FAILURE;
	}

	// program timer
	if(ah_cpu2pl_write(XPAR_AH_CPU2PL_0_DEVICE_ID, PORT_CPU2PL_TIME, meas_time) != XST_SUCCESS){
		return XST_FAILURE;
	}

	// program number of oszillations
	if(ah_cpu2pl_write(XPAR_AH_CPU2PL_0_DEVICE_ID, PORT_CPU2PL_READOUTS, meas_readouts) != XST_SUCCESS){
		return XST_FAILURE;
	}

	// program readout mode
	if(ah_cpu2pl_write(XPAR_AH_CPU2PL_0_DEVICE_ID, PORT_CPU2PL_MODE, meas_mode) != XST_SUCCESS){
		return XST_FAILURE;
	}
	
	// program heatup count
	if(ah_cpu2pl_write(XPAR_AH_CPU2PL_0_DEVICE_ID, PORT_CPU2PL_HEATUP, meas_heatup) != XST_SUCCESS){
		return XST_FAILURE;
	}

	// program cooldown count
	if(ah_cpu2pl_write(XPAR_AH_CPU2PL_0_DEVICE_ID, PORT_CPU2PL_COOLDOWN, meas_cooldown) != XST_SUCCESS){
		return XST_FAILURE;
	}	
	// program measurement mode
	if(meas_mode == READOUT_MASK_PAR){
		number_samples = (IMPL_NUMBER_DUT + IMPL_NUMBER_REF) * meas_readouts;
	}
	else{
		number_samples = (IMPL_NUMBER_REF + 1) * IMPL_NUMBER_DUT * meas_readouts;
	}

	if(ah_cpu2pl_write(XPAR_AH_CPU2PL_0_DEVICE_ID, PORT_PL2DDR_MODE, MODE_SAMPLED)!= XST_SUCCESS){
		return XST_FAILURE;
	}

	if(ah_cpu2pl_write(XPAR_AH_CPU2PL_0_DEVICE_ID, PORT_PL2DDR_CMD, CMD_INTR_ONDONE_ENABLE)!= XST_SUCCESS){
		return XST_FAILURE;
	}

	// write expected number of samples
	if(ah_cpu2pl_write(XPAR_AH_CPU2PL_0_DEVICE_ID, PORT_PL2DDR_SAMPLES, number_samples) != XST_SUCCESS){
		return XST_FAILURE;
	}

	// write ddr addresses
	if(ah_cpu2pl_write(XPAR_AH_CPU2PL_0_DEVICE_ID, PORT_PL2DDR_ADDR_LOW, ddr_addr_low) != XST_SUCCESS){
		return XST_FAILURE;
	}

	if(ah_cpu2pl_write(XPAR_AH_CPU2PL_0_DEVICE_ID, PORT_PL2DDR_ADDR_HIGH, ddr_addr_high) != XST_SUCCESS){
		return XST_FAILURE;
	}


	return XST_SUCCESS;
}


s32 hardware_start(void){
	
	if(ah_cpu2pl_write(XPAR_AH_CPU2PL_0_DEVICE_ID, PORT_PL2DDR_CMD, CMD_ENABLE) != XST_SUCCESS){
		return XST_FAILURE;
	}

	if(ah_cpu2pl_write(XPAR_AH_CPU2PL_0_DEVICE_ID, PORT_CPU2PL_CMD, CPU2PL_CMD_START) != XST_SUCCESS){
		return XST_FAILURE;
	}

	return XST_SUCCESS;
}


s32 hardware_check_data(u8* returnVal){

	if(interrupts[INTERRUPT_TRANSFER_DONE] == TRUE){
		*returnVal = 1;
	}
	else{
		*returnVal = 0;
	}

	return XST_SUCCESS;
}

s32 hardware_get_data(u32* addr, u32* len){

	*addr = (u32)data_buffer;
	*len = number_samples * DATA_BYTES;
	
	data_received += *len;

	return XST_SUCCESS;	
}

s32 hardware_get_received(u32* returnVal){

	*returnVal = data_received;

	return XST_SUCCESS;
}

s32 hardware_check_finished(u8* returnVal){
	
	if (interrupts[INTERRUPT_MEASUREMENT_DONE] == TRUE){
		*returnVal = 1;
	}
	else{
		*returnVal = 0;
	}
	
	return XST_SUCCESS;	
}

s32 program_toplevel(struct binfile* bin){

	u32 length = 0;
	u32 addr = (u32)bin->mem;

	if(ah_sd_loadFile(bin->filename, addr, &length) != XST_SUCCESS){
		return XST_FAILURE;
	}

	if(ah_pcap_transferBitstream(addr, length >> 2, PCAP_RECONFIG_FULL) != XST_SUCCESS){
		return XST_FAILURE;
	}

	return XST_SUCCESS;
}

void decouple(u32 set){
	Xil_Out32(XPAR_PR_DECOUPLER_0_BASEADDR, set);
}

s32 program_partial(struct binfile* bin){

	u32 length = 0;
	u32 addr = (u32)bin->mem;

	if(ah_sd_loadFile(bin->filename, addr, &length) != XST_SUCCESS){
		return XST_FAILURE;
	}

	decouple(1);

	if(ah_pcap_transferBitstream(addr, length >> 2, PCAP_RECONFIG_PARTIAL) != XST_SUCCESS){
		return XST_FAILURE;
	}

	decouple(0);

	return XST_SUCCESS;
}

s32 bin_load_current(void){


	if(binfile_current == NULL){
		return XST_FAILURE;
	}

	if(!binfile_current->isPartial){

		if(binfile_current->next == NULL){
			return XST_FAILURE;
		}
		
		if(!binfile_current->next->isPartial){
			return XST_FAILURE;
		}

		program_toplevel(binfile_current);

		binfile_current = binfile_current->next;
	}

	data_received = 0;

	program_partial(binfile_current);

	return XST_SUCCESS;
}

s32 bin_load(void){
	return bin_load_current();
}

s32 bin_check_next(u8* returnVal){
	
	if(binfile_current == NULL){
		return XST_FAILURE;
	}

	if(binfile_current->next != NULL){
		*returnVal = 1;
	}
	else{
		*returnVal = 0;
	}

	return XST_SUCCESS;
	
}

s32 bin_set_next(u8 reset){
	
	if(reset){
		if(binfile_list != NULL){
			binfile_current = binfile_list;
		}
		else{
			return XST_FAILURE;
		}
	}
	else{
		if(binfile_current == NULL){
			return XST_FAILURE;
		}
		else{
			if(binfile_current->next != NULL){
				binfile_current = binfile_current->next;
			}
			else{
				return XST_FAILURE;
			}
		}
	}
	
	return XST_SUCCESS;
}

s32 bin_insert(u16 id, char* filename, u8* mem, u8 isPartial){

	struct binfile* bin_insert = (struct binfile*)calloc(1,sizeof(struct binfile));

	bin_insert->id = id;
	bin_insert->next = NULL;

	if(sprintf(bin_insert->filename, "%s", filename) <= 0){
		return XST_FAILURE;
	}

	if(mem != NULL){
		bin_insert->mem = mem;
	}
	else{
		bin_insert->mem = file_bytes;
	}

	bin_insert->isPartial = isPartial;

	if(binfile_list == NULL){
		binfile_list = bin_insert;
	}
	else{

		struct binfile* bin_temp = binfile_list;

		if(bin_insert->id < bin_temp->id){
			bin_insert->next = bin_temp;
			binfile_list = bin_insert;
		}
		else{
			struct binfile* bin_temp_next = bin_temp->next;
			while(bin_temp_next != NULL){
				if(bin_temp_next->id > bin_insert->id){
					break;
				}
				bin_temp = bin_temp_next;
				bin_temp_next = bin_temp->next;
			}
			bin_temp->next = bin_insert;
			bin_insert->next = bin_temp_next;
		}

	}

	return XST_SUCCESS;
}




s32 bin_delete(u16 id){

	struct binfile* binfile_temp = binfile_list;
	struct binfile* binfile_todelete = NULL;

	if(binfile_temp != NULL){

		if(binfile_temp->id == id){

			binfile_todelete = binfile_list;
			binfile_list = binfile_list->next;

			free(binfile_todelete);

			return XST_SUCCESS;
		}
		else{
			while(binfile_temp != NULL){

				if(binfile_temp->next != NULL){

					if(binfile_temp->next->id == id){

						binfile_todelete = binfile_temp->next;
						binfile_temp->next = binfile_temp->next->next;

						free(binfile_todelete);

						return XST_SUCCESS;
					}
				}

				binfile_temp = binfile_temp->next;
			}
		}
	}

	return XST_FAILURE;
}

s32 bin_delete_all(void){

	struct binfile* binfile_temp = binfile_list;

	while(binfile_list != NULL){
		binfile_temp = binfile_list;
		while(binfile_temp->next != NULL){
			binfile_temp = binfile_temp->next;
		}
		if(bin_delete(binfile_temp->id) != XST_SUCCESS){
			return XST_FAILURE;
		}
	}

	return XST_SUCCESS;
}

