#ifndef AH_CPU2PL_H
#define AH_CPU2PL_H

#include "xil_types.h"
#include "xstatus.h"
#include "xil_exception.h"

#include "ah_cpu2pl_datatypes.h"

s32 ah_cpu2pl_init(void);
u8 ah_cpu2pl_isInit(void);

s32 ah_cpu2pl_setup(u8 re_setup);
u8 ah_cpu2pl_isSetup(void);

s32 ah_cpu2pl_setup_interruptFunction(u8 id, void *irq_handleFunction);
s32 ah_cpu2pl_setup_interruptPort(u8 id, u8 port, u8 state);
s32 ah_cpu2pl_setup_connection(u8 id, u8 ignoreInputsStatus, u8 ignoreOutputsStatus);

s32 ah_cpu2pl_enable(u8 re_enable);
u8 ah_cpu2pl_isEnabled(void);

s32 ah_cpu2pl_get_numberInputs(u8 id, u32* value);
s32 ah_cpu2pl_get_numberOutputs(u8 id, u32* value);

s32 ah_cpu2pl_write(u8 id, u8 port, u32 value);
s32 ah_cpu2pl_read(u8 id, u8 port, u32* value);

#endif