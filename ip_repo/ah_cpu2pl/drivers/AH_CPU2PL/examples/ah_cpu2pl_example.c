// #define AH_CPU2PL_IGNORE_CONNECTED_INPUT
// #define AH_CPU2PL_IGNORE_CONNECTED_OUTPUT

#include "xil_types.h"
#include "xstatus.h"

#include "ah_cpu2pl.h"
#include "ah_cpu2pl_example.h"

int interrupt_counter = 0;
u8 interrupt_flag[XPAR_AH_CPU2PL_NUM_INSTANCES][XPAR_AH_CPU2PL_0_USED_OUTPUTS];

void exampleHandler(AH_CPU2PL_inst *InstancePtr, u32 port);

int main(void){
	
	u32 read = 0;
	u32 write = 0;
	
	if(cpu2pl_custom_initsetup() != XST_SUCCESS){
		return XST_FAILURE;
	}
	
	// init and setup other ah_lib devices here	
	
	if(ah_cpu2pl_enable() != XST_SUCCESS){
		return XST_FAILURE;
	}
	
	while(1){
		
		// check for interrupt on port 2 of device 0
		if(interrupt_flag[0][2] == TRUE){
		
			// read value
			if(ah_cpu2pl_read(0, 2, &read) != XST_SUCCESS){
				return XST_FAILURE;
			}
			
			//write value of "2" to port 5
			write = 2;
			if(ah_cpu2pl_write(0, 5, write) != XST_SUCCESS){
				return XST_FAILURE;
			}
			
		}
		
		// check for interrupt on port 5 of device 0
		if(interrupt_flag[0][5] == TRUE){
			
			// read value
			if(ah_cpu2pl_read(0, 5, &read) != XST_SUCCESS){
				return XST_FAILURE;
			}
			
			//write value of "5" to port 2
			write = 5;
			if(ah_cpu2pl_write(0, 2, write) != XST_SUCCESS){
				return XST_FAILURE;
			}
			
		}
	}
	
	return 0;
}

void exampleHandler(AH_CPU2PL_inst *InstancePtr, u32 port){
	++interrupt_counter;
	interrupt_flag[InstancePtr->deviceID][port] = TRUE;
}

s32 cpu2pl_custom_initsetup(void){
	
	if(ah_cpu2pl_init() != XST_SUCCESS){
		return XST_FAILURE;
	}
	
	// setup device 0 (AH_CPU2PL_0)
	if(ah_cpu2pl_setup_interruptFunction(0, exampleHandler) != XST_SUCCESS){
		return XST_FAILURE;
	}
	
	// setup port 5 on device 0 to be able of interrupting
	if(ah_cpu2pl_setup_interruptPort(0, 5, 1) != XST_SUCCESS){
		return XST_FAILURE;
	}
	
	// setup port 2 on device 0 to be able of interrupting
	if(ah_cpu2pl_setup_interruptPort(0, 2, 1) != XST_SUCCESS){
		return XST_FAILURE;
	}
	
	// mark device to be activated in the scugic
	if(ah_cpu2pl_setup() != XST_SUCCESS){
		return XST_FAILURE;
	}

	return XST_SUCCESS;
}