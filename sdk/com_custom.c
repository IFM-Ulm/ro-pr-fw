#include "com_custom.h"

#include "xuartps.h"
#include <stdlib.h>

#include "ah_uart.h"

#define UART_CUSTOM_RECEIVE_BUFFSIZE (10485760UL)
#define UART_CUSTOM_SEND_BUFFSIZE (10485760UL)

// forward declarations
void uart_custom_callback_rx(u32 event, u32 data);
void uart_custom_callback_tx(u32 event, u32 data);

static u8 receive_buff[UART_CUSTOM_RECEIVE_BUFFSIZE];
static u8 received_length = 0;
static u32 expected_length = 0;
static u8 send_free = 0;

static struct data_com* uart_data_queue = NULL;

s32 com_custom_init(void){
	
	if(ah_uart_init() != XST_SUCCESS){
		return XST_FAILURE;
	}
	
	return XST_SUCCESS;	
}

s32 com_custom_setup(void){

	if(ah_uart_setup_baudrate(115200) != XST_SUCCESS){
		return XST_FAILURE;
	}

	if(ah_uart_setup_callbackConnect_rx(uart_custom_callback_rx) != XST_SUCCESS){
		return XST_FAILURE;
	}

	if(ah_uart_setup_callbackConnect_tx(uart_custom_callback_tx) != XST_SUCCESS){
		return XST_FAILURE;
	}

	if(ah_uart_setup() != XST_SUCCESS){
		return XST_FAILURE;
	}

	return XST_SUCCESS;
}

s32 com_custom_enable(void){

	if(ah_uart_enable() != XST_SUCCESS){
		return XST_FAILURE;
	}
	
	send_free = 1;
	received_length = 0;
	ah_uart_receive(receive_buff, 4);

	return XST_SUCCESS;

}

s32 com_custom_disable(void){
	// ToDo: implement uart disabling?
	return XST_SUCCESS;
}

s32 com_custom_isConnected(u8* returnVal){

	*returnVal = 1;

	return XST_SUCCESS;
}

s32 com_custom_pull(u8* retVal){

	if(retVal != NULL){
		*retVal = 0;
	}

	return XST_SUCCESS;
}

s32 com_custom_handleErrors(u8* returnVal){

	u8 retVal = 0;

	if(returnVal != NULL){
		*returnVal = retVal;
	}

	return XST_SUCCESS;
}

s32 com_custom_handleDisconnect(u8* returnVal){

	u8 retVal = 0;

	if(returnVal != NULL){
		*returnVal  = retVal;
	}

	return XST_SUCCESS;
}

s32 com_custom_handleInactivity(u8* returnVal){

	u8 retVal = 0;

	if(returnVal != NULL){
		*returnVal  = retVal;
	}

	return XST_SUCCESS;
}

struct data_com* com_custom_pop(void){
	
	struct data_com* ret = NULL;

	if(uart_data_queue != NULL){
		ret = uart_data_queue;

		if(uart_data_queue->next != NULL){
			uart_data_queue = uart_data_queue->next;
		}
		else{
			uart_data_queue = NULL;
		}

		ret->next = NULL;
	}

	return ret;
}

s32 com_custom_free(struct data_com* packet){
	
	if(packet != NULL){
		if(packet->data != NULL){
			free(packet->data);
			free(packet);
			return XST_SUCCESS;
		}
		else{
			free(packet);
			return XST_FAILURE;
		}
	}
	else{
		return XST_FAILURE;
	}
}

s32 com_custom_push(void* data, u32 len){
	
	if(send_free == 0){
		return XST_FAILURE;
	}

	if(len > UART_CUSTOM_SEND_BUFFSIZE){
		return XST_FAILURE;
	}

	if(ah_uart_send((u8*) data, len) != XST_SUCCESS){
		return XST_FAILURE;
	}

	return XST_SUCCESS;
}

s32 com_custom_check_sent(u8* returnVal){
	
	if(send_free){
		*returnVal = 1;
	}
	else{
		*returnVal = 0;
	}

	return XST_SUCCESS;
}
	
s32 com_custom_reset_sent(u8 force){
	return XST_SUCCESS;
}

// uart specific functions

void uart_custom_callback_rx(u32 event, u32 data){

	struct data_com* temp = NULL;
	struct data_com* new_packet = NULL;

	// All of the expected data has been received
	if (event == XUARTPS_EVENT_RECV_DATA) {

		if(received_length == 0){
			received_length = 1;
			expected_length = ((u32)receive_buff[0]) + (((u32)receive_buff[1]) << 8) + (((u32)receive_buff[2]) << 16) + (((u32)receive_buff[3]) << 24);
			ah_uart_receive(receive_buff, expected_length);
		}
		else{

			new_packet = malloc(sizeof(struct data_com));

			if(new_packet == NULL){
				return;
			}

			new_packet->next = NULL;
			new_packet->len = expected_length;
			new_packet->data = malloc(expected_length);

			if(new_packet->data == NULL){
				free(new_packet);
				return;
			}

			memcpy(new_packet->data, receive_buff, expected_length);

			if(uart_data_queue == NULL){
				uart_data_queue = new_packet;
			}
			else{
				temp = uart_data_queue;
				while(temp->next != NULL){
					temp = temp->next;
				}
				temp->next = new_packet;
			}

			received_length = 0;
			ah_uart_receive(receive_buff, 4);
		}

	}

	// Data was received, but not the expected number of bytes, a timeout just indicates the data stopped for ... character times
	if (event == XUARTPS_EVENT_RECV_TOUT) {

	}

	// Data was received with an error, keep the data but determine what kind of errors occurred
	if (event == XUARTPS_EVENT_RECV_ERROR) {

	}
}

void uart_custom_callback_tx(u32 event, u32 data){
	send_free = 1;
}

