#include "fw_com.h"

#include <stdlib.h>
#include <string.h>
#include <stdio.h>

#include "xil_types.h"
#include "xstatus.h"

#include "ah_tcpip.h"
#include "ah_sd.h"

#include "fw_datatypes.h"
#include "fw_hw.h"
#include "fw_meas.h"
#include "tcpip_custom.h"

s32 com_init(void){

	if(ah_tcpip_init() != XST_SUCCESS){
		return XST_FAILURE;
	}

	return XST_SUCCESS;
}

s32 com_setup(void){

	u8 id_ip_csv;
	char buff[40];
	u32 temp;

	unsigned int mac_address[6];
	int ip_address[4];
	int ip_netmask[4];
	int ip_gateway[4];
	int ip_port;

	if(ah_sd_openFile("ip.csv", AH_SD_FLAG_READ, &id_ip_csv) != XST_SUCCESS){
		return XST_FAILURE;
	}

	if(ah_sd_readLine(id_ip_csv, buff, &temp) != XST_SUCCESS){
		return XST_FAILURE;
	}
	if(sscanf(buff, "%X,%X,%X,%X,%X,%X", &(mac_address[0]), &(mac_address[1]), &(mac_address[2]),
			&(mac_address[3]), &(mac_address[4]), &(mac_address[5])) != 6){
		return XST_FAILURE;
	}

	if(ah_sd_readLine(id_ip_csv, buff, &temp) != XST_SUCCESS){
		return XST_FAILURE;
	}
	if(sscanf(buff, "%d,%d,%d,%d", &(ip_address[0]), &(ip_address[1]), &(ip_address[2]), &(ip_address[3])) != 4){
		return XST_FAILURE;
	}

	if(ah_sd_readLine(id_ip_csv, buff, &temp) != XST_SUCCESS){
		return XST_FAILURE;
	}
	if(sscanf(buff, "%d,%d,%d,%d", &(ip_netmask[0]), &(ip_netmask[1]), &(ip_netmask[2]), &(ip_netmask[3])) != 4){
		return XST_FAILURE;
	}

	if(ah_sd_readLine(id_ip_csv, buff, &temp) != XST_SUCCESS){
		return XST_FAILURE;
	}
	if(sscanf(buff, "%d,%d,%d,%d", &(ip_gateway[0]), &(ip_gateway[1]), &(ip_gateway[2]), &(ip_gateway[3])) != 4){
		return XST_FAILURE;
	}

	if(ah_sd_readLine(id_ip_csv, buff, &temp) != XST_SUCCESS){
		return XST_FAILURE;
	}
	if(sscanf(buff, "%d", &ip_port) != 1){
		return XST_FAILURE;
	}

	if(ah_sd_closeFile(id_ip_csv) != XST_SUCCESS){
		return XST_FAILURE;
	}

	if(ah_tcpip_setup_mac((u8)mac_address[0], (u8)mac_address[1], (u8)mac_address[2],
			(u8)mac_address[3], (u8)mac_address[4], (u8)mac_address[5]) != XST_SUCCESS){
		return XST_FAILURE;
	}

	if(ah_tcpip_setup_ip((u8)ip_address[0], (u8)ip_address[1], (u8)ip_address[2], (u8)ip_address[3]) != XST_SUCCESS){
		return XST_FAILURE;
	}

	if(ah_tcpip_setup_netmask((u8)ip_netmask[0], (u8)ip_netmask[1], (u8)ip_netmask[2], (u8)ip_netmask[3]) != XST_SUCCESS){
		return XST_FAILURE;
	}

	if(ah_tcpip_setup_gateway((u8)ip_gateway[0], (u8)ip_gateway[1], (u8)ip_gateway[2], (u8)ip_gateway[3]) != XST_SUCCESS){
		return XST_FAILURE;
	}

	if(ah_tcpip_setup_timerIntervalMS(10) != XST_SUCCESS){
		return XST_FAILURE;
	}

	if(ah_tcpip_setup_pollingmode(0) != XST_SUCCESS){
		return XST_FAILURE;
	}

	if(ah_tcpip_setup_callbackReceived(tcpip_custom_receive) != XST_SUCCESS){
		return XST_FAILURE;
	}

	if(ah_tcpip_setup_callbackError(tcpip_custom_error) != XST_SUCCESS){
		return XST_FAILURE;
	}

	if(ah_tcpip_setup_callbackSent(tcpip_custom_sent) != XST_SUCCESS){
		return XST_FAILURE;
	}

	if(ah_tcpip_setup_port(ip_port) != XST_SUCCESS){
		return XST_FAILURE;
	}

	/*if(ah_tcpip_setup_max_send_size(49164) != XST_SUCCESS){
		return XST_FAILURE;
	}*/

	ah_tcpip_setup_max_send_size(0);

	//tcpip_custom_setThresholds(2048000, 1024000);
	tcpip_custom_setThresholds(20480, 10240);

	if(ah_tcpip_setup() != XST_SUCCESS){
		return XST_FAILURE;
	}

	return XST_SUCCESS;
}

s32 com_enable(void){

	if(ah_tcpip_enable() != XST_SUCCESS){
		return XST_FAILURE;
	}

	if(ah_tcpip_open() != XST_SUCCESS){
		return XST_FAILURE;
	}

	return XST_SUCCESS;

}

s32 com_disable(void){

	if(ah_tcpip_close(1) != XST_SUCCESS){
		return XST_FAILURE;
	}

	return XST_SUCCESS;
}

s32 com_pull(u8* retVal){

	return ah_tcpip_pull(retVal);

}

s32 com_isConnected(u8* returnVal){
	*returnVal = ah_tcpip_checkConnection();
	return XST_SUCCESS;
}

s32 com_handleErrors(u8* returnVal){

	u8 retVal = 0;

	tcpip_custom_dataflow_getStatus(&retVal);

	if(returnVal != NULL){
		*returnVal  = retVal;
	}

	return XST_SUCCESS;
}

s32 com_handleDisconnect(u8* returnVal){

	u8 retVal = 0;

	if(tcpip_custom_flushpackets_ip() != XST_SUCCESS){
		return XST_FAILURE;
	}
	if(tcpip_custom_flushpackets_data() != XST_SUCCESS){
		return XST_FAILURE;
	}

	if(returnVal != NULL){
		*returnVal  = retVal;
	}

	return XST_SUCCESS;
}

s32 com_handleInactivity(u8* returnVal){

	u8 retVal = 0;

	u8 checkVal;

	if(tcpip_custom_getDataAvailable() > 0){

		if(tcpip_custom_dataflow_control(1) != XST_SUCCESS){
			return XST_FAILURE;
		}

		if(tcpip_custom_dataflow_request_refuse(1) != XST_SUCCESS){
			return XST_FAILURE;
		}

		if(tcpip_custom_dataflow_getActive(&checkVal) != XST_SUCCESS){
			return XST_FAILURE;
		}

		if(!checkVal){
			tcpip_custom_update_list(1);
		}

		if(tcpip_custom_dataflow_control(0) != XST_SUCCESS){
			return XST_FAILURE;
		}
		
	if(tcpip_custom_dataflow_request_accept(0) != XST_SUCCESS){
		return XST_FAILURE;
	}

	}

	if(returnVal != NULL){
		*returnVal  = retVal;
	}

	return XST_SUCCESS;
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

	readCommand = tcpip_custom_pop();
	if(readCommand == NULL){

		*returnVal = 0;
		*nextState = st_check_commands;

		return XST_SUCCESS;
	}

	*returnVal = 1;
	*nextState = st_check_commands; // default next state

	datap = readCommand->data;

	switch(datap[0]){

		case 0x00:

			//returnValue = XST_FAILURE;
			returnValue = XST_FAILURE;

			break;

		case 0x01:	// ack for testing

				/*if(tcpip_custom_push(&ack, 1) != XST_SUCCESS){
					returnValue = XST_FAILURE;
				}*/

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

	if(tcpip_custom_push(answer, 3) != XST_SUCCESS){
		returnValue = XST_FAILURE;
	}


	if(filename != NULL){
		free(filename);
		filename = NULL;
	}

	if(tcpip_custom_free(readCommand) != XST_SUCCESS){
		returnValue = XST_FAILURE;
	}

	return returnValue;
}




