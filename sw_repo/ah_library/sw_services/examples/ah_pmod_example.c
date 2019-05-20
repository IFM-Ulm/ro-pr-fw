#include "xil_types.h"
#include "xstatus.h"

#include "ah_pmod.h"

int main(void){
	
	if(ah_pmod_init() != XST_SUCCESS){
		return XST_FAILURE;
	}
	
	// assume IP axi_gpio_0 was connected to ports jb
	if(ah_pmod_setupPMOD(AH_PMOD_DEVICE_JB, 0) != XST_SUCCESS){
		return XST_FAILURE;
	}

	if(ah_pmod_setupPin(AH_PMOD_DEVICE_JB, AH_PMOD_PIN_1, AH_PMOD_PIN_IN) != XST_SUCCESS){
		return XST_FAILURE;
	}
	
	// assume IP axi_gpio_1 was connected to ports jc
	if(ah_pmod_setupPMOD(AH_PMOD_DEVICE_JC, 1) != XST_SUCCESS){
		return XST_FAILURE;
	}
	
	if(ah_pmod_setupPin(AH_PMOD_DEVICE_JC, AH_PMOD_PIN_1, AH_PMOD_PIN_OUT) != XST_SUCCESS){
		return XST_FAILURE;
	}
	
	if(ah_pmod_setupPin(AH_PMOD_DEVICE_JC, AH_PMOD_PIN_2, AH_PMOD_PIN_OUT) != XST_SUCCESS){
		return XST_FAILURE;
	}
	
	if(ah_pmod_setup() != XST_SUCCESS){
		return XST_FAILURE;
	}
	
	if(ah_pmod_enable() != XST_SUCCESS){
		return XST_FAILURE;
	}
	
	
	u32 counter = 0;
	u8 clock = 0;
	u8 data = 0;
	
	while(1){
		
		// read value (VDD or GND) from pin 1 on PMOD jb
		if(ah_pmod_readPin(AH_PMOD_DEVICE_JB, AH_PMOD_PIN_1, &data) != XST_SUCCESS){
			return XST_FAILURE;
		}
		
		// copy value (VDD or GND) to pin 1 on PMOD jc
		if(ah_pmod_writePin(AH_PMOD_DEVICE_JC, AH_PMOD_PIN_1, data) != XST_SUCCESS){
			return XST_FAILURE;
		}
		
		// very basic (and not very precise) implementation of a clock signal
		if(counter < 100000){
			++counter;
		}
		else{
			if(clock == 1){
				clock = 0;
			}
			else{
				clock = 1;
			}
			
			if(ah_pmod_writePin(AH_PMOD_DEVICE_JC, AH_PMOD_PIN_2, clock) != XST_SUCCESS){
				return XST_FAILURE;
			}
			
			counter = 0;
		}
		
	}
	
		
	return XST_SUCCESS;
}