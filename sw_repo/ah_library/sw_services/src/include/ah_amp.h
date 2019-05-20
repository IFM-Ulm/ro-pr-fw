#include "xparameters.h"

#ifndef AH_AMP_H
#define AH_AMP_H

#ifdef AH_AMP_ACTIVATED


s32 ah_amp_init(void);
u8 ah_amp_isInit(void);

s32 ah_amp_setup(void);
u8 ah_amp_isSetup(void);

s32 ah_amp_setup_callbackIPI(void (*fcnptr)(u8));

u8 ah_amp_enable(void);
u8 ah_amp_isEnabled(void);

/*
	The address supplied to this function MUST match with the parameter ps7_ddr_0 of the linker script
	in the project of the application for CPU1.
	Both base address and size of both applications must NOT overlap!
	Example:
		CPU0 - ps7_ddr_0 : base address = 0x00100000, size = 0x00100000
		CPU1 - ps7_ddr_0 : base address = 0x00200000, size = 0x00100000
		code to call in the application of CPU0: ah_amp_start_cpu1(0x00200000);
*/
s32 ah_amp_start_cpu1(u32 startAddress);

s32 ah_amp_set_DCache(u8 enable);
s32 ah_amp_get_DCache(u8* enabled);

s32 ah_amp_set_ICache(u8 enable);
s32 ah_amp_get_ICache(u8* enabled);


u8 ah_amp_isJTAG(void);
u8 ah_amp_isNotJTAG(void);

u8 ah_amp_synchronizeCPUs(void);
s32 ah_amp_interruptSiblingCPU(u8 value);

s32 ah_amp_acquireSemaphore(u8 index);
s32 ah_amp_acquireSemaphore_nonblocking(u8 index);
s32 ah_amp_releaseSemaphore(u8 index);
s32 ah_amp_deleteSemaphore(u8 index);

#endif

#endif