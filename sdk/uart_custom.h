#ifndef SRC_UART_CUSTOM_H_
#define SRC_UART_CUSTOM_H_

#include "xstatus.h"

#include "ah_uart.h"
#include "fw_datatypes.h"

s32 uart_custom_enable(void);

void uart_custom_callback_rx(u32 event, u32 data);
void uart_custom_callback_tx(u32 event, u32 data);

struct data_com* uart_custom_pop(void);
s32 uart_custom_free(struct data_com* packet);
s32 uart_custom_push(void* data, u32 len);

s32 uart_custom_checkDataSent(u8* returnVal);

#endif
