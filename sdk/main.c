#include <stdio.h>
#include <string.h>
#include <stdlib.h>

#include "xil_cache.h"
#include "xil_printf.h"
#include "xparameters.h"
#include "xstatus.h"
#include "xtime_l.h"

#include "xadcps.h"

#include "fw_settings.h"

// lib functions
#include "ah_scugic.h"
#include "ah_pcap.h"
#include "ah_sd.h"
#include "ah_gpio.h"
#include "ah_xadc.h"
#include "ah_cpu2pl.h"

// framework functions
#include "fw_datatypes.h"
#include "fw_com.h"
#include "fw_data.h"
#include "fw_hw.h"
#include "fw_meas.h"

// macros
#ifdef IGNORE_PRINTF
#if (IGNORE_PRINTF == 1)
//#pragma GCC diagnostic ignored "-Wunused-value"
#define printf(fmt, ...) (0)
#endif
#endif

// compression enabled by default
//#define COMPRESSION_EN 1

// check macros to be defined and having valid values
/*
#ifndef DATA_WIDTH
#error "Macro DATA_WIDTH undefined"
#elif (DATA_WIDTH != 16 && DATA_WIDTH != 32)
#error "Macro DATA_WIDTH invalid "
#endif
*/

/*
#ifndef MAX_BUFFER_SIZE
#error "Macro MAX_BUFFER_SIZE undefined"
#elif (MAX_BUFFER_SIZE == 0)
#error "Macro MAX_BUFFER_SIZE invalid "
#endif
*/

// static variables

// global parameters as replacement for macros, loaded from params.csv
/*char param_impl_ro[MAX_BUFFER_SIZE];
u8 strlen_impl_ro;
u32 param_ro_per_bin = 0;
u32 param_t1_size = 0;
u32 param_t2_size = 0;
u32 param_t1b_size = 0;
u32 param_t2b_size = 0;*/

#include "xil_types.h"
#include "xil_assert.h"
#include "xil_exception.h"
#include "xpseudo_asm.h"
#include "xdebug.h"

extern unsigned int _heap_start;
extern unsigned int _heap_end;

unsigned int my_heap_start = (unsigned int)&_heap_start;
unsigned int my_heap_end = (unsigned int)&_heap_end;

int main(){

	u32 return_value = XST_SUCCESS; // return value of main()
	u32 error_value = 0;

	u32 led_value = 0;

	u16 readTemp_start = 0;
	u16 readTemp_end = 0;
	
	u32 repetition_counter = 0;
	u32 repetitions = 0;

	XTime t_blink_last, t_blink_current, t_blink_diff;
	XTime t_activity_last, t_activity_current, t_activity_diff;
	u64 time_div = 0;
	u8 checkVal = 0;

	Xil_DCacheDisable();

	time_div = (u64)(COUNTS_PER_SECOND/1000000);

	// init library 
	if(ah_scugic_init() != XST_SUCCESS){
		goto MAIN_EXIT;
	}

	if(ah_pcap_init() != XST_SUCCESS){
		goto MAIN_EXIT;
	}

	if(ah_sd_init() != XST_SUCCESS){
		goto MAIN_EXIT;
	}
	
	if(ah_gpio_init() != XST_SUCCESS){
		goto MAIN_EXIT;
	}

	if(ah_xadc_init() != XST_SUCCESS){
		goto MAIN_EXIT;
	}

	if(hardware_init() != XST_SUCCESS){
		goto MAIN_EXIT;
	}


	if(ah_sd_mount() != XST_SUCCESS){
		goto MAIN_EXIT;
	}
	
	if(com_init() != XST_SUCCESS){
		goto MAIN_EXIT;
	}
	
	// dirty workaround for problems with the Pynq-Z1
	// somehow needs a pause between com_init() and com_setup()
	usleep(3000000);
	
	// setup library
	if(ah_scugic_setup() != XST_SUCCESS){
		goto MAIN_EXIT;
	}
	
	if(ah_gpio_setup(0) != XST_SUCCESS){
		goto MAIN_EXIT;
	}
	
	if(ah_xadc_setup(0) != XST_SUCCESS){
		goto MAIN_EXIT;
	}

	// setup framework
	if(com_setup() != XST_SUCCESS){
		goto MAIN_EXIT;
	}
	
	if(hardware_setup() != XST_SUCCESS){
		goto MAIN_EXIT;
	}
	
	// enable library	
	if(ah_gpio_enable(0) != XST_SUCCESS){
		goto MAIN_EXIT;
	}
	
	if(com_enable() != XST_SUCCESS){
		goto MAIN_EXIT;
	}

	states state = st_idle;
	states stuck_state = st_wait_connection;
	states next_state = st_idle;
	u8 send_state = st_idle;
	
	ah_gpio_setLED_raw(0);

	checkVal = 0;

	XTime_GetTime(&t_blink_last);

	while(1){

		if(com_pull(NULL) != XST_SUCCESS){
			error_value = 1;
			goto MAIN_EXIT;
		}

		XTime_GetTime(&t_activity_current);
		t_activity_diff = (t_activity_current - t_activity_last) / time_div;

		XTime_GetTime(&t_blink_current);
		t_blink_diff = (t_blink_current - t_blink_last) / time_div;

		if(t_blink_diff > 250000){
			if(led_value){
				led_value = 0;
			}
			else{
				led_value = 1;
			}
			XTime_GetTime(&t_blink_last);

			ah_gpio_setLED(AH_GPIO_LED0, led_value ? AH_GPIO_ON : AH_GPIO_OFF);
		}

		if(com_isConnected(&checkVal) != XST_SUCCESS){
			error_value = 2;
			goto MAIN_EXIT;
		}

		if(!checkVal && state != st_wait_connection && state != st_check_commands){
			ah_gpio_setLED(AH_GPIO_LED1, AH_GPIO_OFF);
			state = st_wait_connection;

			if(com_handleDisconnect(&checkVal) != XST_SUCCESS){
				error_value = 3;
				goto MAIN_EXIT;
			}

			if(data_reset_sent(1) != XST_SUCCESS){
				error_value = 4;
				goto MAIN_EXIT;
			}
		}

		if(stuck_state == st_idle){
			stuck_state = state;
		}

		switch(state){
			
			case st_idle:
					
					// start status, nothing to do?
					state = st_wait_connection;

				break;

			case st_wait_connection:

					if(com_isConnected(&checkVal) != XST_SUCCESS){
						error_value = 100;
						goto MAIN_EXIT;
					}

					if(checkVal){

						if(data_reset_sent(1) != XST_SUCCESS){
							error_value = 101;
							goto MAIN_EXIT;
						}

						ah_gpio_setLED(AH_GPIO_LED1, AH_GPIO_ON);
						state = st_check_commands;
					}
					else{
						ah_gpio_setLED(AH_GPIO_LED1, AH_GPIO_OFF);
						state = st_wait_connection;
					}

				break;

			case st_check_commands:

					if(com_handleErrors(&checkVal) != XST_SUCCESS){
						error_value = 200;
						goto MAIN_EXIT;
					}
					if(checkVal == 1){
						ah_gpio_setLED(AH_GPIO_LED0, AH_GPIO_ON);
						goto MAIN_EXIT;
					}

					if(com_isConnected(&checkVal) != XST_SUCCESS){
						error_value = 201;
						goto MAIN_EXIT;
					}

					if(checkVal){

						if(com_checkCommands(&checkVal, &next_state) != XST_SUCCESS){
							error_value = 202;
							goto MAIN_EXIT;
						}

						if(checkVal == 1){
							XTime_GetTime(&t_activity_last);
							state = next_state;
						}
						else{

							if(t_activity_diff > 250000){

								if(com_handleInactivity(&checkVal) != XST_SUCCESS){
									error_value = 203;
									goto MAIN_EXIT;
								}

								XTime_GetTime(&t_activity_last);

							}

							state = st_check_commands;
						}

					}
					else {

						if(com_handleDisconnect(&checkVal) != XST_SUCCESS){
							error_value = 204;
							goto MAIN_EXIT;
						}

						state = st_wait_connection;

					}
					
				break;

			case st_run_init:

					if(measurement_set_next(1) != XST_SUCCESS){
						error_value = 300;
						goto MAIN_EXIT;
					}

					if(bin_set_next(1) != XST_SUCCESS){
						error_value = 301;
						goto MAIN_EXIT;
					}

					if(measurement_get_repetitions(&repetitions) != XST_SUCCESS){
						error_value = 302;
						goto MAIN_EXIT;
					}

					state = st_bin_load;
					stuck_state = st_idle;

				break;

			case st_bin_load:

					if(bin_load() != XST_SUCCESS){
						error_value = 400;
						goto MAIN_EXIT;
					}
					
					if(ah_gpio_setup(1) != XST_SUCCESS){
						error_value = 404;
						goto MAIN_EXIT;
					}

					if(ah_gpio_enable(1) != XST_SUCCESS){
						error_value = 404;
						goto MAIN_EXIT;
					}

					if(ah_xadc_setup(1) != XST_SUCCESS){
						error_value = 405;
						goto MAIN_EXIT;
					}

					if(ah_cpu2pl_setup(1) != XST_SUCCESS){
						error_value = 405;
						goto MAIN_EXIT;
					}

					if(ah_cpu2pl_enable(1) != XST_SUCCESS){
						error_value = 405;
						goto MAIN_EXIT;
					}

					repetition_counter = 0;

					state = st_setup_meas;
					stuck_state = st_idle;
					
				break;
				
			case st_setup_meas:

					if(measurement_setup() != XST_SUCCESS){
						error_value = 500;
						goto MAIN_EXIT;
					}

					state = st_start_meas;
					stuck_state = st_idle;
					
				break;
			
			case st_start_meas:
					
					readTemp_start = ah_xadc_readTemperature_raw();

					if(measurement_start() != XST_SUCCESS){
						error_value = 600;
						goto MAIN_EXIT;
					}

					ah_gpio_setLED(AH_GPIO_LED2, AH_GPIO_ON);

					state = st_check_meas;
					stuck_state = st_idle;
					
				break;
				
			case st_check_data:

					if(measurement_check_missing(&checkVal) != XST_SUCCESS){
						error_value = 801;
						goto MAIN_EXIT;
					}

					if(checkVal){
						state = st_check_data;
						stuck_state = st_check_data;
					}
					else{
						ah_gpio_setLED(AH_GPIO_LED3, AH_GPIO_ON);
						state = st_process_data;
						stuck_state = st_idle;
					}

				break;

			case st_process_data:

					if(data_process_measurements(&checkVal) != XST_SUCCESS){
						error_value = 1200;
						goto MAIN_EXIT;
					}

					state = st_transfer_data;
					stuck_state = st_process_data;

				break;

			case st_transfer_data:
					
					if(data_send_measurements() != XST_SUCCESS){

						if(com_isConnected(&checkVal) != XST_SUCCESS){
							error_value = 700;
							goto MAIN_EXIT;
						}

						if(checkVal){
							error_value = 701;
							goto MAIN_EXIT;
						}
						else{
							state = st_wait_connection;
						}
					}
					else{
						state = st_wait_transferred;
						stuck_state = st_idle;
					}
					
					ah_gpio_setLED(AH_GPIO_LED3, AH_GPIO_OFF);

				break;
			
			case st_wait_transferred:

				if(data_check_sent(&checkVal) != XST_SUCCESS){
					error_value = 803;
					goto MAIN_EXIT;
				}

				if(checkVal){

					if(repetition_counter < repetitions){
						++repetition_counter;
						state = st_setup_meas;
					}
					else{
						repetition_counter = 0;
						state = st_check_bin;
					}

					stuck_state = st_idle;
				}
				else{
					state = st_wait_transferred;
					stuck_state = st_wait_transferred;
				}

				break;
			
			case st_check_meas:

					if(measurement_check_finished(&checkVal) != XST_SUCCESS){
						error_value = 800;
						goto MAIN_EXIT;
					}

					if(checkVal){

						readTemp_end = ah_xadc_readTemperature_raw();

						data_send_temperatures(readTemp_start, readTemp_end);

						ah_gpio_setLED(AH_GPIO_LED2, AH_GPIO_OFF);

						state = st_check_data;
						stuck_state = st_idle;
					}
					else{
						state = st_check_meas;
					}
					
				break;
				
			case st_check_bin:

					if(bin_check_next(&checkVal) != XST_SUCCESS){
						error_value = 900;
						goto MAIN_EXIT;
					}
					
					if(checkVal){
						if(bin_set_next(0) != XST_SUCCESS){
							error_value = 901;
							goto MAIN_EXIT;
						}
						state = st_bin_load;
					}
					else{
						state = st_check_run;
					}
					
					stuck_state = st_idle;

				break;
				
			case st_check_run:

					if(measurement_check_next(&checkVal) != XST_SUCCESS){
						error_value = 1000;
						goto MAIN_EXIT;
					}

					if(checkVal){

						if(bin_set_next(1) != XST_SUCCESS){
							error_value = 1001;
							goto MAIN_EXIT;
						}

						if(measurement_set_next(0) != XST_SUCCESS){
							error_value = 1002;
							goto MAIN_EXIT;
						}

						if(data_reset_sent(1) != XST_SUCCESS){
							error_value = 1003;
							goto MAIN_EXIT;
						}
						
						if(measurement_get_repetitions(&repetitions) != XST_SUCCESS){
							error_value = 1004;
							goto MAIN_EXIT;
						}

						state = st_bin_load;
					}
					else{
						state = st_check_commands;
					}
					
					stuck_state = st_idle;
										
				break;
				
			case st_send_stuck:

					switch(stuck_state){
						case st_idle : 				send_state = 0; break;
						case st_wait_connection : 	send_state = 1; break;
						case st_check_commands : 	send_state = 2; break;
						case st_check_data : 		send_state = 3; break;
						case st_process_data : 		send_state = 4; break;
						case st_transfer_data : 	send_state = 5; break;
						case st_cont_data : 		send_state = 6; break;
						case st_check_errors : 		send_state = 7; break;
						default : 					send_state = 15; break;
					}

					if(com_push(&send_state, 1) != XST_SUCCESS){
							error_value = 1100;
							goto MAIN_EXIT;
					}

					state = st_check_commands;
					stuck_state = st_idle;

				break;
			
			case st_cont_data:
					
					if(data_reset_sent(1) != XST_SUCCESS){
						error_value = 1101;
						goto MAIN_EXIT;
					}
						
					state = st_transfer_data;
					stuck_state = st_idle;
						
				break;
				
			case st_check_errors:

					//ERROR_HANDLING:

					// state for checking and resolving errors (if possible), for now just leave the main loop
					goto MAIN_EXIT;

				break;

			default:

				state = st_idle;

				break;

		}
		
		
	}
	
MAIN_EXIT:

	if(error_value > 0){
		ah_gpio_setLED(AH_GPIO_LED0, AH_GPIO_ON);
		ah_gpio_setLED(AH_GPIO_LED1, AH_GPIO_OFF);
		ah_gpio_setLED(AH_GPIO_LED2, AH_GPIO_OFF);
		ah_gpio_setLED(AH_GPIO_LED3, AH_GPIO_OFF);
		return_value = XST_FAILURE;
	}
	else{
		ah_gpio_setLED(AH_GPIO_LED0, AH_GPIO_OFF);
		ah_gpio_setLED(AH_GPIO_LED1, AH_GPIO_ON);
		ah_gpio_setLED(AH_GPIO_LED2, AH_GPIO_ON);
		ah_gpio_setLED(AH_GPIO_LED3, AH_GPIO_ON);
	}

	ah_sd_umount(); // ignore return value in order to not overwrite the true return value

	XTime_GetTime(&t_blink_last);
	ah_gpio_setLED(AH_GPIO_LED1, AH_GPIO_OFF);
	ah_gpio_setLED(AH_GPIO_LED2, AH_GPIO_OFF);
	ah_gpio_setLED(AH_GPIO_LED3, AH_GPIO_OFF);

	com_handleDisconnect(&checkVal);

	while(1){

		ah_gpio_setLED(AH_GPIO_LED0, AH_GPIO_ON);

		// ToDo: Check for button press to restart? Or do it on your own?

	}

	return return_value;

}
