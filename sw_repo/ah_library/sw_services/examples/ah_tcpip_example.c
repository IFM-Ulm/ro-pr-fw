#include <stdlib.h>
#include <string.h>

#include "xil_types.h"
#include "xstatus.h"

#include "ah_tcpip.h"
#include "ah_tcpip_example.h"

#define TCPIP_EXAMPLE_SEND_BUFFSIZE 4194304UL

/* recommended settings for lwip:
	
	see ah_tcpip.h
	
*/

// forward declarations
u8 tcpip_custom_insert_data(void);
struct data_com* tcpip_custom_get_data_tcpip(void);

struct tpcip_packet {

	struct tpcip_packet* next;

	u8* data;
	u16 data_offset;
	u16 len;
	u16 orig_len;

#ifdef AH_TCPIP_MANUAL_MEMORY
	struct pbuf* pbuf_data;
#endif

};

static struct tpcip_packet* packet_queue = NULL;
static struct tpcip_packet* packet_queue_pending = NULL;
static struct data_com* tcpip_data_queue = NULL;
static volatile u8 list_order = 0;
static u32 refuse_data_threshold = 0;
static u32 accept_data_threshold = 0;
static u8 data_threshold_override = 0;
static u8 receive_active = 0;

static u8 error_ip = 0;
static u8 error_data = 0;

// forward declarations
void tcpip_custom_insert_packet(void* data, u16 data_len);
void tcpip_custom_receive(u16 connection_index, struct pbuf* buffer, void* data, u16 data_len);
u8 tcpip_custom_insert_data(void);
struct data_com* tcpip_custom_get_data_tcpip(void);

static volatile u32 data_added = 0;
static volatile u32 data_removed = 0;
static volatile u32 data_counted = 0;

u8 buff[TCPIP_EXAMPLE_SEND_BUFFSIZE];

int main(void){

	u32 send_bytes = 0;
	struct data_com* next = NULL;
	
	// init and setup other ah_lib devices here	
	
	tcpip_custom_initsetup();

	while (1) {

			if(ah_tcpip_pull(NULL) != XST_SUCCESS){
				break;
			}
			
			next = tcpip_custom_pop();

			if(next != NULL){

				u8* data = (u8*)next->data;

				if(data[0] == 3){
					send_bytes = ((u32)data[1]) + (((u32)data[2]) << 8) + (((u32)data[3]) << 16) + (((u32)data[4]) << 24);
				}

				tcpip_custom_free(next);
			}

			if(send_bytes > 0){

				if(tcpip_custom_push((void*)buff, send_bytes) == XST_SUCCESS){
					send_bytes = 0;
				}
				
			}
			
	}
	
	return 0;
}


s32 tcpip_custom_initsetup(void){

	if(ah_tcpip_init() != XST_SUCCESS){
		return XST_FAILURE;
	}

	if(ah_tcpip_setup_mac(0x00, 0x0a, 0x35, 0x00, 0x01, 0x02) != XST_SUCCESS){
		return XST_FAILURE;
	}

	if(ah_tcpip_setup_ip(134, 60, 26, 167) != XST_SUCCESS){
		return XST_FAILURE;
	}

	if(ah_tcpip_setup_netmask(255, 255, 255, 0) != XST_SUCCESS){
		return XST_FAILURE;
	}

	if(ah_tcpip_setup_gateway(134, 60, 26, 1) != XST_SUCCESS){
		return XST_FAILURE;
	}

	if(ah_tcpip_setup_pollingmode(0) != XST_SUCCESS){
		return XST_FAILURE;
	}

	// send a maximum of 100kbyte dangling (waiting for ack) at a time
	if(ah_tcpip_setup_max_send_size(49164) != XST_SUCCESS){
		return XST_FAILURE;
	}
	
	// set threshold for maximum amount of concurrent data to be received
	tcpip_custom_setThresholds(20480, 10240);
	
	if(ah_tcpip_setup_callbackReceived(tcpip_custom_receive) != XST_SUCCESS){
		return XST_FAILURE;
	}

	if(ah_tcpip_setup() != XST_SUCCESS){
		return XST_FAILURE;
	}

	if(ah_tcpip_enable() != XST_SUCCESS){
		return XST_FAILURE;
	}

	if(ah_tcpip_open(7) != XST_SUCCESS){
		return XST_FAILURE;
	}

	return XST_SUCCESS;
}

struct data_com* tcpip_custom_pop(void){

	struct data_com* ret = NULL;

	if(tcpip_data_queue == NULL){
		tcpip_custom_insert_data();
	}

	if(tcpip_data_queue != NULL){
		ret = tcpip_data_queue;

		if(tcpip_data_queue->next != NULL){
			tcpip_data_queue = tcpip_data_queue->next;
		}
		else{
			tcpip_data_queue = NULL;
		}

		ret->next = NULL;

	}

	if(accept_data_threshold > 0 && (data_added - data_removed) <= (u32)accept_data_threshold){
		tcpip_custom_dataflow_request_accept(0);
	}

	if(error_data > 0){
		error_data = 0;
	}

	return ret;
}

s32 tcpip_custom_free(struct data_com* packet){

	if(packet != NULL){
		if(packet->data != NULL){

			data_removed += packet->len + 4;

			free(packet->data);
			packet->data = NULL;
			free(packet);

			return XST_SUCCESS;
		}
		else{
			free(packet);
			packet = NULL;
			return XST_FAILURE;
		}
	}
	else{
		return XST_FAILURE;
	}

}

s32 tcpip_custom_push(void* data, u32 len){

	u16 rem;
	u16 send_len;
	u32 total_len;
	u32 total_len_max = 65070;
	u16 transmit_len = 1446;

	void* temp;
	
	u8 checkbuffer;

	if(!ah_tcpip_checkConnection()){
		return XST_FAILURE;
	}
	
	rem = len;
	temp = data;
	total_len = len;
	
	if(len > 12800){
		ah_tcip_setflag_copy(0);
	}
	
	while(total_len > 0){

		if(total_len > total_len_max){
			send_len = total_len_max;
		}
		else{
			send_len = (u16)total_len;
		}

		rem = send_len;

		while(rem > transmit_len){

			checkbuffer = ah_tcpip_checkBuffer(transmit_len);

			while(!checkbuffer){

				if(!ah_tcpip_checkConnection()){
					return XST_FAILURE;
				}

				ah_tcpip_send_output();

				checkbuffer = ah_tcpip_checkBuffer(transmit_len);

			}

			if(ah_tcpip_send(temp, transmit_len, 0) == XST_SUCCESS){
				temp += transmit_len;
				rem -= transmit_len;
			}

		}

		if(rem > 0){

			checkbuffer = ah_tcpip_checkBuffer(rem);

			while(!checkbuffer){

				if(!ah_tcpip_checkConnection()){
					return XST_FAILURE;
				}

				ah_tcpip_send_output();

				checkbuffer = ah_tcpip_checkBuffer(rem);

			}

			if(ah_tcpip_send_blocking(temp, rem, 1)!= XST_SUCCESS){
				return XST_FAILURE;
			}

			temp += rem;
			rem = 0;			
		}

		total_len -= (u32)send_len;
	}
	
	ah_tcip_setflag_copy(1);
	
	return XST_SUCCESS;
}

void tcpip_custom_receive(u16 connection_index, struct pbuf* buffer, void* data, u16 data_len){

	struct tpcip_packet* new_packet = NULL;
	struct tpcip_packet* temp = NULL;

	receive_active = 1;

	if(refuse_data_threshold > 0 && (data_added - data_removed) >= refuse_data_threshold){
		tcpip_custom_dataflow_request_refuse(0);
	}

	if(data_len > 0){

		new_packet = (struct tpcip_packet*)calloc(1, sizeof(struct tpcip_packet));
		if(new_packet != NULL){

			new_packet->next = NULL;
			new_packet->data_offset = 0;
			new_packet->len = data_len;
			new_packet->orig_len = data_len;

#ifdef AH_TCPIP_MANUAL_MEMORY
			new_packet->pbuf_data = buffer;
			new_packet->data = (u8*)buffer->payload;
#else
			new_packet->data = (u8*)calloc(data_len, sizeof(u8));
			if(new_packet->data == NULL){
				error_ip = 2;
				free(new_packet);
				new_packet = NULL;
				return;
			}

			memcpy((void*)(new_packet->data), buffer->payload, data_len);
#endif

		}
		else{
			receive_active = 0;
			error_ip = 1;
			return;
		}
	}
	else{
		receive_active = 0;
		return;
	}

	if(packet_queue_pending == NULL){

		packet_queue_pending = new_packet;

	}
	else{

		temp = packet_queue_pending;

		while(temp->next != NULL){
			temp = temp->next;
		}

		temp->next = new_packet;
	}

	data_added += (u32)data_len;

	tcpip_custom_update_list(0);

	receive_active = 0;

}

s32 tcpip_custom_setThresholds(u32 refuse_data, u32 accept_data){

	refuse_data_threshold = refuse_data;
	accept_data_threshold = accept_data;

	return XST_SUCCESS;
}

s32 tcpip_custom_dataflow_getActive(u8* returnVal){

	*returnVal = receive_active;

	return XST_SUCCESS;
}

// used to control who can refuse/accept data
// override == 0: everyone (for automatic use in receiving data)
// override > 0 : only the caller with the same validation number, manual control
s32 tcpip_custom_dataflow_control(u8 override){

	data_threshold_override = override;

	return XST_SUCCESS;
}

s32 tcpip_custom_dataflow_request_refuse(u8 validation){

	if(data_threshold_override){
		if(data_threshold_override == validation){
			ah_tcpip_refuse_data();
			return XST_SUCCESS;
		}
		else{
			return XST_FAILURE;
		}
	}
	else{
		if(refuse_data_threshold > 0){
			if((data_added - data_removed) >= refuse_data_threshold){
				ah_tcpip_refuse_data();
				return XST_SUCCESS;
			}
			else{
				return XST_FAILURE;
			}
		}
		else{
			ah_tcpip_refuse_data();
			return XST_SUCCESS;
		}
	}
}

s32 tcpip_custom_dataflow_request_accept(u8 validation){

	if(data_threshold_override){
		if(data_threshold_override == validation){
			ah_tcpip_refuse_data();
			return XST_SUCCESS;
		}
		else{
			return XST_FAILURE;
		}
	}
	else{
		if(accept_data_threshold > 0){
			if((data_added - data_removed) <= (u32)accept_data_threshold){
				ah_tcpip_accept_data();
				return XST_SUCCESS;
			}
			else{
				return XST_FAILURE;
			}
		}
		else{
			ah_tcpip_accept_data();
			return XST_SUCCESS;

		}
	}
}

s32 tcpip_custom_dataflow_getStatus(u8* returnVal){

	if(error_ip > 0){
		*returnVal = 1;
	}
	else if(error_data > 0){
		*returnVal = 2;
	}
	else{
		*returnVal = 0;
	}
	return XST_SUCCESS;
}

u32 tcpip_custom_getDataAvailable(void){

	if(data_added > data_removed){
		if(data_added - data_removed > data_counted){
			return data_added - data_removed;
		}
		else{
			return data_counted;
		}
	}
	else{
		return data_counted;
	}

}


s32 tcpip_custom_update_list(u8 force){

	struct tpcip_packet* temp;

	if(force || list_order == 1){

		if(packet_queue == NULL){
			packet_queue = packet_queue_pending;
			packet_queue_pending = NULL;
		}
		else{
			temp = packet_queue;
			while(temp->next != NULL){
				temp = temp->next;
			}
			temp->next = packet_queue_pending;
			packet_queue_pending = NULL;
		}
		list_order = 2;

		return XST_SUCCESS;
	}

	return XST_FAILURE;
}

u8 tcpip_custom_insert_data(void){

	struct data_com* next_packet = NULL;
	struct data_com* temp;
	u8 retVal = 0;

	next_packet = tcpip_custom_get_data_tcpip();

	if(next_packet != NULL){

		if(tcpip_data_queue == NULL){
			tcpip_data_queue = next_packet;
		}
		else{
			temp = tcpip_data_queue;
			while(temp->next != NULL){
				temp = temp->next;
			}
			temp->next = next_packet;
		}

		retVal = 1;
	}

	return retVal;
}

struct data_com* tcpip_custom_get_data_tcpip(void){

	struct data_com* newDataPacket = NULL;
	struct tpcip_packet* pkt_current = packet_queue;
	struct tpcip_packet* pkt_previous = NULL;
	struct tpcip_packet* pkt_cleanup = NULL;
	struct tpcip_packet* pkt_cleanup_last = NULL;

	u32 packet_length = 0;
	u32 data_length = 0;
	u8 len_counter = 0;
	u8 byte_index = 0;
	u32 missing_data = 0;

	data_counted = 0;

	if(list_order == 1 || list_order > 2){
		return NULL;
	}
	else if(list_order == 2){
		list_order = 0;
	}

	if(packet_queue == NULL){
		if(list_order == 0){
			list_order = 1;
		}
		return NULL;
	}

	pkt_current = packet_queue;
	len_counter = 0;
	byte_index = 0;
	packet_length = 0;

	while(len_counter < 4){

		if(pkt_current != NULL){ // prevent reading NULL-packets
			if(pkt_current->len != 0){ // prevent reading 0-byte packets
				byte_index = 0;
				while(byte_index < pkt_current->len && len_counter < 4){
					packet_length += ((u32)pkt_current->data[pkt_current->data_offset + byte_index]) << (8 * len_counter);
					++len_counter;
					++byte_index;
				}
				pkt_current = pkt_current->next;
			}
			else{
				// prevent reading empty packets
				pkt_current = pkt_current->next;
			}
		}
		else{
			break;
		}
	}

	if(len_counter < 4){
		if(list_order == 0){
			list_order = 1;
		}
		return NULL;
	}

	data_length = 0;
	pkt_current = packet_queue;

	while(pkt_current != NULL){
		data_length += pkt_current->len;
		pkt_current = pkt_current->next;
	}

	data_counted = data_length;

	if(data_length < (packet_length + 4)){
		if(list_order == 0){
			list_order = 1;
		}
		return NULL;
	}

	// create new packet
	newDataPacket = (struct data_com*)calloc(1, sizeof(struct data_com)); // data abort?
	if(newDataPacket == NULL){
		error_data = 2;
		return NULL;
	}

	newDataPacket->len = packet_length;
	newDataPacket->next = NULL;

	newDataPacket->data = (u8*)calloc(packet_length, sizeof(u8));
	if(newDataPacket->data == NULL){
		error_data = 3;
		free(newDataPacket);
		return NULL;
	}

	pkt_current = packet_queue;
	missing_data = packet_length;
	len_counter = 4;
	byte_index = 0;

	u8* src_ptr = NULL;
	u8* dat_ptr = newDataPacket->data;
	u32 bytes_to_copy = 0;

	while(missing_data > 0){

		if(len_counter > 0){

			if(pkt_current == NULL){
				// ERROR
				error_data = 4;
				break;
			}
			else if(pkt_current->len == 0){
				pkt_current = pkt_current->next;
			}
			else if(pkt_current->len > len_counter){
				byte_index = len_counter;
				len_counter = 0;
			}
			else if(pkt_current->len == len_counter){
				len_counter = 0;
				pkt_current = pkt_current->next;
			}
			else{ // packet->len == 0 || packet->len > 0 && packet->len < len_counter
				len_counter -= pkt_current->len;
				pkt_current = pkt_current->next;
			}

		}
		else{

			// byte_index == 0 || byte_index > 0 && pkt_current->len > byte_index

			if(pkt_current == NULL){
				break;
			}
			else if(pkt_current->len == 0){

				bytes_to_copy = 0;

				pkt_current = pkt_current->next;

			}
			else if(missing_data + byte_index > pkt_current->len){ // pkt_current->len - byte_index < missing_data

				bytes_to_copy = pkt_current->len - byte_index;
				missing_data -= bytes_to_copy;

				src_ptr = (pkt_current->data + pkt_current->data_offset + byte_index);

				pkt_current->len = 0;
				pkt_current = pkt_current->next;
				byte_index = 0;
			}
			else if(missing_data + byte_index == pkt_current->len){ // pkt_current->len - byte_index == missing_data

				bytes_to_copy = missing_data;
				missing_data = 0;

				src_ptr = (pkt_current->data + pkt_current->data_offset + byte_index);

				pkt_current->len = 0;
				pkt_current = NULL;
				byte_index = 0;
			}
			else{ //  pkt_current->len - byte_index > missing_data

				bytes_to_copy = missing_data;
				missing_data = 0;

				src_ptr = (pkt_current->data + pkt_current->data_offset + byte_index);

				pkt_current->len -= bytes_to_copy + byte_index;
				pkt_current->data_offset += bytes_to_copy + byte_index;

				pkt_current = NULL;
				byte_index = 0;
			}

			if(bytes_to_copy > 0){
				memcpy((void*)dat_ptr, (void*)src_ptr, bytes_to_copy);
				dat_ptr += bytes_to_copy;
			}

		}

	}

	if(!error_data){

		// clean up 0-len packets

			while(packet_queue != NULL){
				if(packet_queue->len == 0){

					if(pkt_cleanup == NULL){
						pkt_cleanup = packet_queue;
						packet_queue = packet_queue->next;
						pkt_cleanup->next = NULL;
					}
					else{
						pkt_current = pkt_cleanup;
						while(pkt_current->next != NULL){
							pkt_current = pkt_current->next;
						}
						pkt_current->next = packet_queue;
						packet_queue = packet_queue->next;
						pkt_current = pkt_current->next;
						pkt_current->next = NULL;
					}

				}
				else{
					break;
				}
			}

			pkt_previous = packet_queue;
			while(pkt_previous != NULL){

				if(pkt_previous->next != NULL){

					pkt_current = pkt_previous->next;

					if(pkt_current->len == 0){

						pkt_previous->next = pkt_current->next;

						if(pkt_cleanup == NULL){
							pkt_cleanup = pkt_current;
							pkt_current->next = NULL;
						}
						else{

							pkt_cleanup_last = pkt_cleanup;
							while(pkt_cleanup_last->next != NULL){
								pkt_cleanup_last = pkt_cleanup_last->next;
							}
							pkt_cleanup_last->next = pkt_current;
							pkt_current->next = NULL;
						}

					}

				}

				pkt_previous = pkt_previous->next;
			}

			pkt_current = pkt_cleanup;
			while(pkt_current != NULL){
				pkt_cleanup = pkt_current;
				pkt_current = pkt_current->next;

#ifdef AH_TCPIP_MANUAL_MEMORY
				if(pkt_cleanup->pbuf_data != NULL){

					if(pkt_cleanup->pbuf_data->next != NULL){
						error_ip = 3;
					}

					pbuf_free(pkt_cleanup->pbuf_data);
				}
#else
				if(pkt_cleanup->data != NULL){
					freee(pkt_cleanup->data);
				}
#endif

				free(pkt_cleanup);
				pkt_cleanup = NULL;
			}

	}
	else{

		if(newDataPacket != NULL){
			if(newDataPacket->data != NULL){
				free(newDataPacket->data);
				newDataPacket->data = NULL;
			}
			free(newDataPacket);
			newDataPacket = NULL;
		}
	}

	return newDataPacket;
}

s32 tcpip_custom_flushpackets_ip(void){

	struct tpcip_packet* pkt_current;
	struct tpcip_packet* pkt_next;

	list_order = 3;

	if(packet_queue != NULL){
		pkt_current = packet_queue;
		pkt_next = pkt_current->next;

		while(pkt_current != NULL){

#ifdef AH_TCPIP_MANUAL_MEMORY
				if(pkt_current->pbuf_data != NULL){

					if(pkt_current->pbuf_data->next != NULL){
						error_ip = 3;
					}

					pbuf_free(pkt_current->pbuf_data);
				}
#else
				if(pkt_current->data != NULL){
					freee(pkt_current->data);
				}
#endif

			free(pkt_current);

			pkt_current = pkt_next;
			pkt_next = pkt_current->next;
		}
	}

	if(packet_queue_pending != NULL){
		pkt_current = packet_queue_pending;
		pkt_next = pkt_current->next;

		while(pkt_current != NULL){

#ifdef AH_TCPIP_MANUAL_MEMORY
				if(pkt_current->pbuf_data != NULL){

					if(pkt_current->pbuf_data->next != NULL){
						error_ip = 3;
					}

					pbuf_free(pkt_current->pbuf_data);
				}
#else
				if(pkt_current->data != NULL){
					freee(pkt_current->data);
				}
#endif

			free(pkt_current);

			pkt_current = pkt_next;
			pkt_next = pkt_current->next;
		}
	}

	list_order = 0;

	return XST_SUCCESS;
}

s32 tcpip_custom_flushpackets_data(void){

	struct data_com* data_current;
	struct data_com* data_next;

	if(tcpip_data_queue != NULL){
		data_current = tcpip_data_queue;
		data_next = data_current->next;

		while(data_current != NULL){

			if(data_current->data != NULL){
				free(data_current->data);
			}
			free(data_current);

			data_current = data_next;
			data_next = data_current->next;
		}
	}

	return XST_SUCCESS;
}

/* corresponding matlab code, see file value2byte.m for the function function byte_out = value2byte( value, format )

% for large data transfers, increase heap space available for tcpip: MATLAB Preferences > General > Java Heap Memory

if(exist('tcpip_obj', 'var'))
	if(isa(tcpip_obj, 'tcpip'))
		if(strcmp(tcpip_obj.Status, 'open'))
			try
				fclose(tcpip_obj);
			end
		end
		flushinput(tcpip_obj);
	end
end

clc

tcpip_obj = tcpip('134.60.26.167', 7, 'NetworkRole', 'client', 'InputBufferSize', 157286400);

byte_test = 1048576; % 1 MB

tcpip_connected = false;

try
	fprintf('testing connection... ');
	test_tcpip = tcpclient('134.60.26.167', 7, 'Timeout', 5, 'ConnectTimeout', 1);
	fprintf('success\n');
	clear test_tcpip
	fprintf('opening connection... ');
	fopen(tcpip_obj);
	fprintf('succcess\n');
	tcpip_connected = true;
catch e
	fprintf('failed\n');
	display(e)
end


if(tcpip_connected)

	p = 1460;
	b = 1;

	byte_counter = b*byte_test;
	flushinput(tcpip_obj);

	fprintf('functionality test started\n');
	fprintf('data total size: %fMB\n', (b*byte_test)/1024^2);
	fprintf('packet size: %d\n', p);

	send_packet = [uint8(3) value2byte(b*byte_test, 'u32')];	
	fwrite(tcpip_obj, [value2byte(length(send_packet), 'u32') send_packet]);

	while(tcpip_obj.BytesAvailable == 0)
		pause(0.1)
	end

	tic;

	while(tcpip_obj.BytesAvailable < byte_counter)
		pause(0.1);
	end

	t_end = toc;

	flushinput(tcpip_obj);

	fprintf('functionality test stopped\n');
	fprintf('%.1f bytes (%.1f MB) transferred in %.1fs = %.1f MB/s\n', byte_counter, byte_counter/1024^2, t_end, byte_counter / (t_end * 1024^2));

	fprintf('closing connection... ');
	fclose(tcpip_obj);
	fprintf('closed\n');
	
	fprintf('functionality test successfull\n');
	
end




*/
