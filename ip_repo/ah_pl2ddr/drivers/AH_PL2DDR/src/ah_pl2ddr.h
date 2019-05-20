#ifndef AH_PL2DDR_H
#define AH_PL2DDR_H

#include "xparameters.h"

// sampling modes

#define MODE_NO_SAMPLING 0x00000000
#define MODE_RUNNING 0x00000005
#define MODE_FREE_RUNNING 0x00000001
#define MODE_SAMPLED 0x00000002
#define MODE_UNDERSAMPLED 0x00000003
#define MODE_MANUAL 0x00000004

// commands
#define CMD_NONE 0x00000000
#define CMD_RST 0x00000001
#define CMD_RST_ADDR 0x00000002
#define CMD_RST_DATA 0x00000004

#define CMD_DISABLE 0x00000020
#define CMD_ENABLE 0x00000021

#define CMD_TRIGGER_TX 0x00000100
#define CMD_FORCE_TX 0x00000101
#define CMD_TRIGGER_SAMPLE 0x00000102
#define CMD_TRIGGER_FILLDATA 0x00000104

#define CMD_INTR_ONSENT_DISABLE 0x00001010
#define CMD_INTR_ONSENT_ENABLE 0x00001011
#define CMD_INTR_ONDONE_DISABLE 0x00001020
#define CMD_INTR_ONDONE_ENABLE 0x00001021
#define CMD_INTR_ONERROR_DISABLE 0x00001040
#define CMD_INTR_ONERROR_ENABLE 0x00001041
#define CMD_INTR_ONACK_DISABLE 0x00001080
#define CMD_INTR_ONACK_ENABLE 0x00001081

#define CMD_TESTMODE_DISABLE 0x00010000
#define CMD_TESTMODE_ENABLE 0x00010001

// triger types (if ah_scugic.h is not used)
#ifndef AH_SCUGIC_ACTIVATED
#define INTR_TRIGGER_ACTIVE_HIGH 0x1
#define INTR_TRIGGER_EDGE_RISING 0x3
#endif

#endif

// Help

/*	introduction
	
	The following help sections show some aspects of th IPs' programmable functionality.
	Most examples assume you are familiar with the AH_CPU2PL IP and its' programming functionality,
	in combination with the library "ah_lib".
	The given ports and instances, e.g. for ah_cpu2pl_write(), are examples only
	and have to be adapted according to your design.
	

*/ 

/* how to disable cache to prevent reading wrong values

	1. add the following line at the top of your main file
	
		#include "xil_cache.h"
		
	2. call the following function at the beginning of your main function
	
		Xil_DCacheDisable();
		
*/

/* how to register and react to interrupts by the IP
	
	1. use the scugic functionality provided with the library "ah_lib"
	
	2. look up the interrupt macro provided in xparameters.h, e.g.
	
		// Definitions for Fabric interrupts connected to ps7_scugic_0
		#define XPAR_FABRIC_AH_PL2DDR_0_INTR_SENT_INTR 61U
		#define XPAR_FABRIC_AH_PL2DDR_0_INTR_DONE_INTR 62U
		
	3. provide a callback function, e.g.
	
		void intr_count(void* data){
			u32* counter = (u32*)data;
			*counter += 1;
		}
	
	2. include the functionality of the exemplary following lines in your main function
	
		u32 intr_counter_done = 0;
		
		ah_scugic_init();
		
		ah_scugic_setup_connectHandler(XPAR_FABRIC_AH_PL2DDR_0_INTR_DONE_INTR, intr_count, (void*)&intr_counter_done);

		ah_scugic_setup_setInterruptTriggerType(XPAR_FABRIC_AH_PL2DDR_0_INTR_DONE_INTR, INTR_TRIGGER_EDGE_RISING);

		ah_scugic_setup_enableHandler(XPAR_FABRIC_AH_PL2DDR_0_INTR_DONE_INTR);
	
	
	3. enable the interrupt functionality in the IP by the corresponding command, e.g.

		ah_cpu2pl_write(0, 0, CMD_INTR_ONERROR_ENABLE);

	4. wait for the interrupt to be raised
	
		while(intr_counter_done == 0);
	
		
*/ 


/* how to read values from a given address
	
	1. assuming the following settings
		
		u32 param_ddr_low = 0x01000000;
		u32 param_number_samples = 0x000000FF;
		ah_cpu2pl_write(0, 1, param_number_samples);
		ah_cpu2pl_write(0, 3, param_ddr_low);
		
	2. get byte-wise pointer to the address space
	
		u8* data = (u8*)param_ddr_low;
		
	3. iterate over data for processing
	
		u8 readData;
		for(u32 t = 0; t < param_number_samples; ++t){
			readData = data[t]; // alternative: readData = *(data+t);
			// process data[t]
		}
*/

/*	how to transmit data to matlab (e.g. with ah_uart)

	1. calculate byte factor from DATA_WIDTH (the parameter DATA_WIDTH from the IP instance)
	
		byte_factor = (param_number_samples * DATA_WIDTH) / 8;
		
		pre-calculated:
			1-bit:		byte_factor = param_number_samples / 8;
			2-bit:		byte_factor = param_number_samples / 4;
			4-bit:		byte_factor = param_number_samples / 2;
			8-bit:		byte_factor = param_number_samples;
			16-bit:		byte_factor = param_number_samples * 2;
			32-bit:		byte_factor = param_number_samples * 4;
	
	2. provide the number of bytes and the address of the data to send to the sending function
	
		send_bytes = param_number_samples / byte_factor;

		uart_custom_push((void*)data, send_bytes);
	
	3. read the data into matlab (see ah_uart_example.c for more in-depth details)
	
		bytes_av = sObj.BytesAvailable;
		byte_data = fread(sObj, bytes_av, 'uint8');
		
	4. use the function bytes2values (see 5.) to format the data
		
		data = bytes2values(byte_data, DATA_WIDTH);
	
	5. write the following function to a file called bytes2values.m in the same folder as your readout script
	
		function values = bytes2values(bytes, data_width)

			byte_len = size(bytes,1) * size(bytes,2);

			switch data_width
				case 1
					values = zeros(byte_len * 8, 1);
					offset = 1;
					for b = 1 : byte_len
						value = bytes(b);
						bin_byte = de2bi(value,8);
						for t = 1 : 8
							values(offset,1) = bin_byte(t);
							offset = offset + 1;
						end
					end
					
				case 2
					values = zeros(byte_len * 4, 1);
					offset = 1;
					for b = 1 : byte_len
						value = bytes(b);
						bin_byte = de2bi(value,8);
						for t = 1 : 2 : 8
							values(offset,1) = bin_byte(t) + bin_byte(t+1)*2^1;
							offset = offset + 1;
						end
					end
				case 4
					values = zeros(byte_len * 2, 1);
					offset = 1;
					for b = 1 : byte_len
						value = bytes(b);
						bin_byte = de2bi(value,8);
						for t = 1 : 4 : 8
							values(offset,1) = bin_byte(t) + bin_byte(t+1)*2^1 + bin_byte(t+2)*2^2 + bin_byte(t+3)*2^3;
							offset = offset + 1;
						end
					end
				case 8
					values = double(bytes);
				case 16
					values = zeros(byte_len / 2, 1);
					offset = 1;
					for b = 1 : 2 : byte_len
						values(offset,1) = bytes(b) + bytes(b+1)*2^8;
						offset = offset + 1;
					end
				case 32
					values = zeros(byte_len / 4, 1);
					offset = 1;
					for b = 1 : 4 : byte_len
						values(offset,1) = bytes(b) + bytes(b+1)*2^8 + bytes(b+2)*2^16 + bytes(b+3)*2^24;
						offset = offset + 1;
					end
				otherwise
					error('invalid data_width')
			end
		end
	
*/