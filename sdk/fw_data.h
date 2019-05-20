#ifndef SRC_DATACONTROL_H_
#define SRC_DATACONTROL_H_

#include "xstatus.h"

s32 data_send_measurements(void);
s32 data_send_temperatures(u16 temp_start, u16 temp_end);

s32 data_check_sent(u8* returnVal);
s32 data_reset_sent(u8 force);

#endif
