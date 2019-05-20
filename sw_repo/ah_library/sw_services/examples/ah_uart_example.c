#include <stdlib.h>
#include <string.h>

#include "xil_types.h"
#include "xstatus.h"
#include "xuartps.h"

#include "ah_uart.h"
#include "ah_uart_example.h"

// 4MB for send/receive
#define UART_CUSTOM_RECEIVE_BUFFSIZE (4194304UL)
#define UART_CUSTOM_SEND_BUFFSIZE (4194304UL)


static u8 receive_buff[UART_CUSTOM_RECEIVE_BUFFSIZE];
static u8 received_length = 0;
static u32 expected_length = 0;
static u8 send_free = 0;

static struct data_com* uart_data_queue = NULL;

void uart_custom_callback_rx(u32 event, u32 data);
void uart_custom_callback_tx(u32 event, u32 data);


int main(){
	
	u32 send_bytes = 0;
	struct data_com* next = NULL;
	u8 buff[UART_CUSTOM_SEND_BUFFSIZE];
	u8* data_ptr;
	
	uart_custom_initsetup();
	
	// if present, place other init / setup functions here
	
	uart_custom_enable();

	while (1) {

			next = uart_custom_pop();

			if(next != NULL){
				u8* data = (u8*)next->data;

				if(data[0] == 3){
					send_bytes = ((u32)data[1]) + (((u32)data[2]) << 8) + (((u32)data[3]) << 16) + (((u32)data[4]) << 24);
					data_ptr = buff;
				}

				uart_custom_free(next);
			}

			while(send_bytes > 0){

				if(send_bytes < UART_CUSTOM_SEND_BUFFSIZE ){
					if(uart_custom_push((void*)data_ptr, send_bytes) == XST_SUCCESS){
						send_bytes = 0;
					}
				}
				else{
					if(uart_custom_push((void*)data_ptr, UART_CUSTOM_SEND_BUFFSIZE) == XST_SUCCESS){
						send_bytes -= UART_CUSTOM_SEND_BUFFSIZE;
						data_ptr += send_bytes;
					}
				}

			}
	}
	
	return 0;
}



s32 uart_custom_initsetup(void){

	if(ah_uart_init() != XST_SUCCESS){
		return XST_FAILURE;
	}

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

s32 uart_custom_enable(void){
	
	if(ah_uart_enable() != XST_SUCCESS){
		return XST_FAILURE;
	}
	
	send_free = 1;
	received_length = 0;
	ah_uart_receive(receive_buff, 4);
	
	return XST_SUCCESS;
}

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

struct data_com* uart_custom_pop(void){

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

s32 uart_custom_free(struct data_com* packet){

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

s32 uart_custom_push(void* data, u32 len){

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


/* corresponding matlab code, see file value2byte.m for the function function byte_out = value2byte( value, format )

clc

try
	fclose(sObj);
	delete(sObj);
catch
	warning('could not close serial port, attempting to close all connections...');
	try
		if(~isempty(instrfind))
			fclose(instrfind);
			delete(instrfind);
		end
	catch
		error('error while closing connections');
	end
end


sObj = serial('COM4');
sObj.BaudRate = 115200;
sObj.Parity = 'none';
sObj.DataBits = 8;
sObj.FlowControl = 'none';
sObj.ReadAsyncMode = 'continuous';
sObj.InputBufferSize = 157286400;
sObj.BytesAvailableFcnMode = 'terminator'; % terminator | byte

fopen(sObj);

byte_test = 1048576; % 1 MB
b = 1;

byte_counter = b*byte_test;
flushinput(sObj);

fprintf('functionality test started\n');
fprintf('data total size: %fMB\n', (b*byte_test)/1024^2);

send_packet = [uint8(3) value2byte(b*byte_test, 'u32')];	
fwrite(sObj, [value2byte(length(send_packet), 'u32') send_packet], 'aysnc');

while(sObj.BytesAvailable == 0)
	pause(0.1)
end

tic_counter = 0;

tic;

while(sObj.BytesAvailable < byte_counter)
	pause(0.1);
	t_end = toc;
	tic_counter = tic_counter + 1;
	if(mod(tic_counter*10,100) == 0)
		fprintf('%.1f: %.1fKB\n', t_end, sObj.BytesAvailable / 1024);
	end
end

t_end = toc;

% read data as u8
% test_data = fread(sObj, sObj.BytesAvailable, 'uint8');

% read data as u32
% test_data = fread(sObj, sObj.BytesAvailable / 4, 'uint32');

% clear rest of input buffer
flushinput(sObj);

fprintf('functionality test stopped\n');
fprintf('%.1f bytes (%.1f KB) transferred in %.1fs = %.1f KB/s\n', byte_counter, byte_counter/1024, t_end, byte_counter / (t_end * 1024));

fprintf('closing connection... ');
fclose(sObj);
delete(sObj);
fprintf('closed\n');
fprintf('functionality test successfull\n');

*/