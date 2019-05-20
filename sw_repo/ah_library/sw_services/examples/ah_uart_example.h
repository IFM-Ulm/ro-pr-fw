#ifndef AH_UART_EXAMPLE_H
#define AH_UART_EXAMPLE_H

#include "xil_types.h"
#include "xstatus.h"

#include "ah_datatypes_example.h"


s32 uart_custom_initsetup(void);

struct data_com* uart_custom_pop(void);

s32 uart_custom_free(struct data_com* packet);

s32 uart_custom_push(void* data, u32 len);

#endif