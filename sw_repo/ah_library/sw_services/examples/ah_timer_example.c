#include "xil_types.h"
#include "xstatus.h"

#include "ah_timer.h"

u8 timer_flag = 0;

void callback_custom(void* instance){
	u32* val = (u32*)instance;
	
	*val += 1;
	timer_flag = 1;
}

int main(void){

	u32 timer_counter = 0;
	u32 timer_id = 0;
	
	if(ah_timer_init() != XST_SUCCESS){
		return XST_FAILURE;
	}
	
	// not needed for the default timebase of 1MS but just in case...
	if(ah_timer_setup_setTimebase(AH_TIMER_TIMEBASE_1MS) != XST_SUCCESS){
		return XST_FAILURE;
	}
	
	if(ah_timer_setup_reloadEnable() != XST_SUCCESS){
		return XST_FAILURE;
	}

	if(ah_timer_setup_callbackConnect(callback_custom, &timer_counter, 250, AH_TIMER_TIMEBASE_1MS, 0, &timer_id) != XST_SUCCESS){
		return XST_FAILURE;
	}

	if(ah_timer_setup_callbackEnable(timer_id) != XST_SUCCESS){
		return XST_FAILURE;
	}

	if(ah_timer_enable() != XST_SUCCESS){
		return XST_FAILURE;
	}

	
	while(1){
		if(timer_flag){
			timer_flag = 0;
			
			// ...
		}
	}
	
}