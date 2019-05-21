#include <stdlib.h>

#include "fw_hw.h"
#include "fw_meas.h"

#include "fw_settings.h"

struct meas* meas_list = NULL;
struct meas* meas_current = NULL;



s32 measurement_setup_current(void){

	if(meas_current == NULL){
		return XST_FAILURE;
	}

	if(hardware_measurement_setup(meas_current->mode, meas_current->readouts, meas_current->time, meas_current->heatup, meas_current->cooldown) != XST_SUCCESS){
		return XST_FAILURE;
	}

	return XST_SUCCESS;
}

s32 measurement_setup(void){
	return measurement_setup_current();
}

s32 measurement_check_next(u8* returnVal){

	if(meas_current == NULL){
		return XST_FAILURE;
	}

	if(meas_current->next != NULL){
		*returnVal = 1;
	}
	else{
		*returnVal = 0;
	}

	return XST_SUCCESS;
}

s32 measurement_set_next(u8 reset){

	if(reset){
		if(meas_list != NULL){
			meas_current = meas_list;
		}
		else{
			return XST_FAILURE;
		}
	}
	else{
		if(meas_current == NULL){
			return XST_FAILURE;
		}
		else{
			if(meas_current->next != NULL){
				meas_current = meas_current->next;
			}
			else{
				return XST_FAILURE;
			}
		}
	}

	return XST_SUCCESS;
}

s32 measurement_start(void){
	return hardware_start();
}

s32 measurement_check_data(u8* returnVal){
	return hardware_check_data(returnVal);
}

s32 measurement_check_missing(u8* returnVal){

	u32 hw_data_received = 0;
	u32 expected_data = 0;

	if(hardware_get_received(&hw_data_received) != XST_SUCCESS){
		return XST_FAILURE;
	}

	if(meas_current->mode == READOUT_MASK_PAR){
		expected_data = meas_current->readouts * (IMPL_NUMBER_DUT + IMPL_NUMBER_REF) * DATA_BYTES;
	}
	else{
		expected_data = meas_current->readouts * (IMPL_NUMBER_REF + 1) * IMPL_NUMBER_DUT * DATA_BYTES;
	}

	if(expected_data > hw_data_received){
		*returnVal = 1;
	}
	else{
		*returnVal = 0;
	}

	return XST_SUCCESS;
}

s32 measurement_check_finished(u8* returnVal){

	if(hardware_check_finished(returnVal) != XST_SUCCESS){
		return XST_FAILURE;
	}

	return XST_SUCCESS;
}

s32 measurement_insert(u16 id, u8 mode, u32 readouts, u32 time, u32 heatup, u32 cooldown){

	struct meas* meas_insert = (struct meas*)calloc(1,sizeof(struct meas));

	if(meas_insert == NULL){
		return XST_FAILURE;
	}

	meas_insert->id = id;
	meas_insert->next = NULL;
	meas_insert->mode = mode;
	meas_insert->readouts = readouts;
	meas_insert->time = time;
	meas_insert->heatup = heatup;
	meas_insert->cooldown = cooldown;

	if(meas_list == NULL){
		meas_list = meas_insert;
	}
	else{

		struct meas* meas_temp = meas_list;

		if(meas_insert->id < meas_temp->id){
			meas_insert->next = meas_temp;
			meas_list = meas_insert;
		}
		else{
			struct meas* meas_temp_next = meas_temp->next;
			while(meas_temp_next != NULL){
				if(meas_temp_next->id > meas_insert->id){
					break;
				}
				meas_temp = meas_temp_next;
				meas_temp_next = meas_temp->next;
			}
			meas_temp->next = meas_insert;
			meas_insert->next = meas_temp_next;
		}

	}

	return XST_SUCCESS;
}

s32 measurement_delete(u16 id){

	struct meas* meas_temp = meas_list;
	struct meas* meas_todelete = NULL;

	if(meas_temp != NULL){

		if(meas_temp->id == id){

			meas_todelete = meas_list;
			meas_list = meas_list->next;

			free(meas_todelete);

			return XST_SUCCESS;
		}
		else{
			while(meas_temp != NULL){

				if(meas_temp->next != NULL){

					if(meas_temp->next->id == id){

						meas_todelete = meas_temp->next;
						meas_temp->next = meas_temp->next->next;

						free(meas_todelete);

						return XST_SUCCESS;
					}
				}

				meas_temp = meas_temp->next;
			}
		}
	}

	return XST_FAILURE;
}

s32 measurement_delete_all(void){

	struct meas* meas_temp = meas_list;

	while(meas_list != NULL){
		meas_temp = meas_list;
		while(meas_temp->next != NULL){
			meas_temp = meas_temp->next;
		}
		if(measurement_delete(meas_temp->id) != XST_SUCCESS){
			return XST_FAILURE;
		}
	}

	return XST_SUCCESS;
}
