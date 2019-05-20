#include "xparameters.h"

#ifndef AH_UART_H
#define AH_UART_H

/*	active usage of UART1 in the hardware:
		- open "Block Properties" of the IP "ZYNQ7 Processing System"
		- go to "MIO Configuration"
		- open "I/O Peripherials"
		- activate "UART 1" and assign "MIO 48 ... 49"
*/

#ifdef AH_UART_ACTIVATED

#ifndef AH_SCUGIC_ACTIVATED
#error AH_SCUGIC needs to be activated in order to use AH_UART
#endif

#include "xil_types.h"
#include "xstatus.h"

s32 ah_uart_init(void);
u8 ah_uart_isInit(void);

s32 ah_uart_setup(void);
u8 ah_uart_isSetup(void);

s32 ah_uart_setup_baudrate(u32 baudrate);
s32 ah_uart_setup_callbackConnect_rx(void (*fcnptr)(u32 event, u32 data));
s32 ah_uart_setup_callbackConnect_tx(void (*fcnptr)(u32 event, u32 data));


s32 ah_uart_enable(void);
u8 ah_uart_isEnabled(void);

s32 ah_uart_send(u8* bufferPtr, u32 numBytes);
s32 ah_uart_receive(u8* bufferPtr, u32 numBytes);

u8 ah_uart_checkReceived(void);

#endif

#endif
