#ifndef AH_UART_DATATYPES_EXAMPLE_H
#define AH_UART_DATATYPES_EXAMPLE_H

struct data_com {
	struct data_com* next;
	void* data;
	u32 len;
};

#endif