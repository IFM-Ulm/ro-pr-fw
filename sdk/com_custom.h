#ifndef SRC_COM_CUSTOM_H_
#define SRC_COM_CUSTOM_H_

#include "xstatus.h"

#include "fw_datatypes.h"

s32 com_custom_init(void);
s32 com_custom_setup(void);
s32 com_custom_enable(void);
s32 com_custom_disable(void);

s32 com_custom_isConnected(u8* returnVal);
s32 com_custom_handleErrors(u8* returnVal);
s32 com_custom_handleDisconnect(u8* returnVal);
s32 com_custom_handleInactivity(u8* returnVal);

s32 com_custom_pull(u8* retVal);

struct data_com* com_custom_pop(void);
s32 com_custom_free(struct data_com* packet);
s32 com_custom_push(void* data, u32 len);
s32 com_custom_check_sent(u8* returnVal);
s32 com_custom_reset_sent(u8 force);


#endif
