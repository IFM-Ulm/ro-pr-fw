#include "fw_data.h"
#include "fw_hw.h"
#include "fw_com.h"

u32 data_received = 0;

s32 data_send_measurements(void){
	
	u32 data;
	u32 len;

	if(data_get_measurements(&data, &len) != XST_SUCCESS){
		return XST_FAILURE;
	}
	
	if(com_push((void*) data, (u32)(len + 4)) != XST_SUCCESS){
		return XST_FAILURE;
	}

	data_received = 0;

	return XST_SUCCESS;
}

s32 data_send_temperatures(u16 temp_start, u16 temp_end){

	if(hardware_insert_temperature_data(temp_start, temp_end) != XST_SUCCESS){
		return XST_FAILURE;
	}

	return XST_SUCCESS;
}

s32 data_check_sent(u8* returnVal){


	if(com_check_sent(returnVal) != XST_SUCCESS){
		return XST_FAILURE;
	}

	return XST_SUCCESS;
}

s32 data_reset_sent(u8 force){


	if(com_reset_sent(force) != XST_SUCCESS){
		return XST_FAILURE;
	}

	return XST_SUCCESS;
}


s32 data_get_measurements(u32* data, u32* len){

	if(data == NULL || len == NULL){
		return XST_FAILURE;
	}

	if(hardware_get_data(data, len) != XST_SUCCESS){
		return XST_FAILURE;
	}

	if(data_received == 0){
		data_received = *len;
	}

	return XST_SUCCESS;
}

s32 data_get_received(u32* returnVal){

	u32 data;
	u32 len;

	if(data_received == 0){
		if(data_get_measurements(&data, &len) != XST_SUCCESS){
			return XST_FAILURE;
		}
		data_received = len;
	}

	if(returnVal != NULL){
		*returnVal = data_received;
	}

	return XST_SUCCESS;
}

s32 data_process_measurements(u8* returnVal){

	u32 data;
	u32 len;

	if(data_get_measurements(&data, &len) != XST_SUCCESS){
		return XST_FAILURE;
	}

	return XST_SUCCESS;

	if(data != 0 && len != 0){
		
		// do processing here

		// signal a result of the processing
		if(returnVal != NULL){
			*returnVal = 1;
		}

	}


	return XST_SUCCESS;
}



