#include "xparameters.h"

#ifndef AH_TIMER_H
#define AH_TIMER_H

#ifdef AH_TIMER_ACTIVATED

#ifndef AH_SCUGIC_ACTIVATED
#error AH_SCUGIC needs to be activated in order to use AH_TIMER
#endif

#include "xstatus.h"
#include "xil_types.h"

#define AH_TIMER_TIMEBASE_1US 	(1)
#define AH_TIMER_TIMEBASE_10US 	(10)
#define AH_TIMER_TIMEBASE_100US (100)
#define AH_TIMER_TIMEBASE_1MS 	(1000)
#define AH_TIMER_TIMEBASE_10MS 	(10000)
#define AH_TIMER_TIMEBASE_100MS (100000)
#define AH_TIMER_TIMEBASE_1S 	(1000000)


s32 ah_timer_init(void);
u8 ah_timer_isInit(void);

s32 ah_timer_setup(void);
u8 ah_timer_isSetup(void);

s32 ah_timer_setup_reloadEnable(void);
s32 ah_timer_setup_reloadDisable(void);
s32 ah_timer_setup_setTimebase(u32 timebase);
s32 ah_timer_setup_callbackConnect(void (*fcnptr)(void* data), void* data, u32 count, u32 timebase, u8 oneshot, u32* id);
s32 ah_timer_setup_callbackEnable(u32 id);
s32 ah_timer_setup_callbackDisable(u32 id);

s32 ah_timer_enable(void);
u8 ah_timer_isEnabled(void);

#endif

#endif
