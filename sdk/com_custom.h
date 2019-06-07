#ifndef SRC_TCPIP_CUSTOM_H_
#define SRC_TCPIP_CUSTOM_H_

#include "xstatus.h"

#include "ah_tcpip.h"
#include "fw_datatypes.h"

// send / receive functions
struct data_com* tcpip_custom_pop(void);
s32 tcpip_custom_free(struct data_com* packet);
s32 tcpip_custom_push(void* data, u32 len);

s32 tcpip_custom_checkDataSent(u8* returnVal);
s32 tcpip_custom_resetDataSent(u8 force);

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
void tcpip_custom_sent(u16 connection_index, u16 len);
void tcpip_custom_error(u16 connection_index, u8 status);

// flushing
s32 tcpip_custom_flushpackets_ip(void);
s32 tcpip_custom_flushpackets_data(void);

#endif
