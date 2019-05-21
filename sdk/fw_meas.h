#ifndef SRC_FW_MEAS_H_
#define SRC_FW_MEAS_H_

#include "xstatus.h"

struct meas {
	
	struct meas* next;
	
	u16 id;

	u8 mode; // MEASURMENT_MODE_SEQ or MEASURMENT_MODE_PAR
	u32 readouts; // number of measurement points
	u32 time;
	u32 heatup;
	u32 cooldown;
	
};

s32 measurement_check_next(u8* returnVal);
s32 measurement_set_next(u8 reset);
s32 measurement_setup(void);

s32 measurement_start(void);

s32 measurement_check_data(u8* returnVal);
s32 measurement_check_finished(u8* returnVal);
s32 measurement_check_missing(u8* returnVal);

s32 measurement_insert(u16 id, u8 mode, u32 readouts, u32 time, u32 heatup, u32 cooldown);
s32 measurement_delete(u16 id);
s32 measurement_delete_all(void);

#endif
