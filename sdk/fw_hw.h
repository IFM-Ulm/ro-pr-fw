#ifndef SRC_HARDWARE_H
#define SRC_HARDWARE_H

#include <stdlib.h>

#include "xstatus.h"

struct binfile {
	
	struct binfile* next;
	
	u16 id;

	char filename[60];
	u8* mem;
	u8 isPartial;
	
};


s32 hardware_init(void);
s32 hardware_reset(void);
s32 hardware_setup(void);
s32 hardware_measurement_setup(u8 meas_mode, u32 meas_readouts, u32 meas_time, u32 meas_heatup, , u32 meas_cooldown);

s32 hardware_start(void);
s32 hardware_check_finished(u8* returnVal);
	
s32 hardware_check_data(u8* returnVal);
s32 hardware_get_data(u32* addr, u32* len);
s32 hardware_get_received(u32* returnVal);

s32 bin_insert(u16 id, char* filename, u8* mem, u8 isPartial);
s32 bin_delete(u16 id);
s32 bin_delete_all(void);

s32 bin_check_next(u8* returnVal);
s32 bin_set_next(u8 reset);
s32 bin_load(void);



#endif
