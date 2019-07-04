#include "fw_data.h"
#include "fw_hw.h"
#include "com_custom.h"

s32 data_send_measurements(void){
	
	u32 data;
	u32 len;

	if(hardware_get_data(&data, &len) != XST_SUCCESS){
		return XST_FAILURE;
	}

	if(com_custom_push((void*) data, (u32)(len + 4)) != XST_SUCCESS){
		return XST_FAILURE;
	}

	return XST_SUCCESS;
}

s32 data_send_temperatures(u16 temp_start, u16 temp_end){

	if(hardware_insert_temperature_data(temp_start, temp_end) != XST_SUCCESS){
		return XST_FAILURE;
	}

	return XST_SUCCESS;
}

s32 data_check_sent(u8* returnVal){

	if(com_custom_check_sent(returnVal) != XST_SUCCESS){
		return XST_FAILURE;
	}

	return XST_SUCCESS;
}

s32 data_reset_sent(u8 force){

	if(com_custom_reset_sent(force) != XST_SUCCESS){
		return XST_FAILURE;
	}

	return XST_SUCCESS;
}

