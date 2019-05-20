#ifndef AH_TCPIP_EXAMPLE_H
#define AH_TCPIP_EXAMPLE_H

#include "datatypes.h"
#include "xstatus.h"

#include "ah_tcpip.h"

// send / receive functions
struct data_com* tcpip_custom_pop(void);
s32 tcpip_custom_free(struct data_com* packet);
s32 tcpip_custom_push(void* data, u16 len);

// functions for controlling the dataflow
s32 tcpip_custom_dataflow_getActive(u8* returnVal);
s32 tcpip_custom_dataflow_control(u8 override);
s32 tcpip_custom_dataflow_request_refuse(u8 validation);
s32 tcpip_custom_dataflow_request_accept(u8 validation);
s32 tcpip_custom_setThresholds(u32 refuse_data, u32 accept_data);
s32 tcpip_custom_dataflow_getStatus(u8* returnVal);

u32 tcpip_custom_getDataAvailable(void);
s32 tcpip_custom_update_list(u8 force);

// callbacks
void tcpip_custom_receive(u16 connection_index, struct pbuf* buffer, void* data, u16 data_len);
void tcpip_custom_error(u16 connection_index, u8 status);

// flushing
s32 tcpip_custom_flushpackets_ip(void);
s32 tcpip_custom_flushpackets_data(void);


#endif