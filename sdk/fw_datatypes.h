#ifndef SRC_FW_DATATYPES_H_
#define SRC_FW_DATATYPES_H_

#include "xstatus.h"

struct data_com {
	struct data_com* next;
	u8* data;
	u32 len;
};

typedef enum { st_idle = 0, st_wait_connection, st_check_commands, st_run_init, st_bin_load, st_check_bin, st_setup_meas, st_start_meas, st_check_data, st_transfer_data, st_check_meas, st_check_run, st_check_errors } states;


#endif
