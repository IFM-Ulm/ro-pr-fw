#include "fw_com.h"

#include <stdlib.h>
#include <string.h>
#include <stdio.h>

#include "xil_types.h"
#include "xstatus.h"

#include "ah_sd.h"

#include "fw_datatypes.h"
#include "fw_hw.h"
#include "fw_meas.h"
#include "com_custom.h"

s32 com_init(void){
	return com_custom_init();
}

s32 com_setup(void){
	return com_custom_setup();
}

s32 com_enable(void){
	return com_custom_enable();
}

s32 com_disable(void){
	return com_custom_disable();
}


s32 com_isConnected(u8* returnVal){
	return com_custom_isConnected(returnVal);
}

s32 com_pull(u8* retVal){
	return com_custom_pull(retVal);
}


struct data_com* com_pop(void){
	return com_custom_pop();
}

s32 com_free(struct data_com* packet){
	return com_custom_free(packet);
}

s32 com_push(void* data, u32 len){
	return com_custom_push(data, len);
}


s32 com_handleErrors(u8* returnVal){
	return com_custom_handleErrors(returnVal);
}

s32 com_handleDisconnect(u8* returnVal){
	return com_custom_handleDisconnect(returnVal);
}

s32 com_handleInactivity(u8* returnVal){
	return com_custom_handleInactivity(returnVal);
}

s32 com_check_sent(u8* returnVal){
	return com_custom_check_sent(returnVal);
}

s32 com_reset_sent(u8 force){
	return com_custom_reset_sent(force);
}

s32 com_checkCommands(u8* returnVal, states* nextState){

	struct data_com* readCommand;
	u8* datap = NULL;

	s32 returnValue = XST_SUCCESS;

	u16 length_filename;
	u32 length_file;
	u16 id;
	u8 isPartial;
	char* filename = NULL;
	u8 mode;
	u32 readouts;
	u32 time;
	u32 heatup;
	u32 cooldown;

	u8 answer[3];

	if(nextState == NULL){
		return XST_FAILURE;
	}

	readCommand = com_custom_pop();
	if(readCommand == NULL){
		
		if(returnVal != NULL){
			*returnVal = 0;
		}
		
		*nextState = st_check_commands;

		return XST_SUCCESS;
	}
	
	if(returnVal != NULL){
		*returnVal = 1;
	}
	
	*nextState = st_check_commands; // default next state

	datap = readCommand->data;

	switch(datap[0]){

		case 0x00:

			returnValue = XST_FAILURE;

			break;

		case 0x01:	// ack for testing

				*nextState = st_check_commands;

			break;

		case 0x02: 	// receive file command

				switch(datap[1]){

					case 0x00: break; // nop

					case 0x01: 	// store received file

							length_filename = ((u16)datap[2]) | (((u16)datap[3]) << 8);
							length_file = ((u32)datap[4]) | (((u32)datap[5]) << 8) | (((u32)datap[6]) << 16) | (((u32)datap[7]) << 24);

							filename = (char*)calloc(length_filename+1, sizeof(char));
							memcpy((void*)filename, (void*)(datap + 8), length_filename);
							filename[length_filename] = '\0';

							u8* filedata = datap + 8 + length_filename;

							if(ah_sd_writeFile(filename, filedata, length_file) != XST_SUCCESS){
								returnValue = XST_FAILURE;
							}

						break;

					case 0xF1: 	// delete file by filename

						break;

					default:	// invalid file command

						break;
				}

				*nextState = st_check_commands;

			break;

		case 0x03:	// receive bin command

			switch(datap[1]){

				case 0x00: break; // nop

				case 0x01: // insert bin info

						id = ((u16)datap[2]) | (((u16)datap[3]) << 8);
						isPartial = datap[4];
						length_filename = ((u16)datap[5]) | (((u16)datap[6]) << 8);

						filename = (char*)calloc(length_filename+1, sizeof(char));
						memcpy((void*)filename, (void*)(datap + 7), length_filename);
						filename[length_filename] = '\0';

						if(bin_insert(id, filename, NULL, isPartial) != XST_SUCCESS){
							returnValue = XST_FAILURE;
						}

					break;

				case 0xF0: // delete all bin info

						if(bin_delete_all() != XST_SUCCESS){
							returnValue = XST_FAILURE;
						}

					break;

				case 0xF1: // delete bin info by id

					break;

				default:

					break;
			}



			break;

		case 0x04:	// receive measurement command

			switch(datap[1]){

				case 0x00: break;

				case 0x01:	// insert measurement

						id = ((u16)datap[2]) | (((u16)datap[3]) << 8);
						mode = datap[4];
						readouts = ((u32)datap[5]) | (((u32)datap[6]) << 8) | (((u32)datap[7]) << 16) | (((u32)datap[8]) << 24);
						time = ((u32)datap[9]) | (((u32)datap[10]) << 8) | (((u32)datap[11]) << 16) | (((u32)datap[12]) << 24);
						heatup = ((u32)datap[13]) | (((u32)datap[14]) << 8) | (((u32)datap[15]) << 16) | (((u32)datap[16]) << 24);
						cooldown = ((u32)datap[17]) | (((u32)datap[18]) << 8) | (((u32)datap[19]) << 16) | (((u32)datap[20]) << 24);

						if(measurement_insert(id, mode, readouts, time, heatup, cooldown) != XST_SUCCESS){
							returnValue = XST_FAILURE;
						}

					break;

				case 0x02:	// start single measurement identified by id


					break;

				case 0x03:	// start all measurements

						*nextState = st_run_init;

					break;

				case 0xF0:	// delete all measurements

						if(measurement_delete_all() != XST_SUCCESS){
							returnValue = XST_FAILURE;
						}

					break;

				case 0xF1:	// delete measurement by id

					break;


				default:

					break;
			}

			break;

		default:	// invalid command

			break;
	}

	answer[0] = datap[0];
	answer[1] = datap[1];
	if(returnValue == XST_SUCCESS){
		answer[2] = 0x6; // ACK
	}
	else{
		answer[2] = 0x15; // NACK
	}

	if(com_custom_push(answer, 3) != XST_SUCCESS){
		returnValue = XST_FAILURE;
	}


	if(filename != NULL){
		free(filename);
		filename = NULL;
	}

	if(com_custom_free(readCommand) != XST_SUCCESS){
		returnValue = XST_FAILURE;
	}

	return returnValue;
}

