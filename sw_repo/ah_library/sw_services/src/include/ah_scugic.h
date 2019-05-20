#include "xparameters.h"

#ifndef AH_SCUGIC_H
#define AH_SCUGIC_H

#ifdef AH_SCUGIC_ACTIVATED

#include "xstatus.h"
#include "xil_types.h"

#include "xscugic.h"

s32 ah_scugic_init(void);
u8 ah_scugic_isInit(void);

s32 ah_scugic_setup(void);
u8 ah_scugic_isSetup(void);

s32 ah_scugic_setup_connectHandler(u32 XPS_INT_ID, void (*fcnptr)(void* data), void* fcndata);
s32 ah_scugic_setup_enableHandler(u32 XPS_INT_ID);
s32 ah_scugic_setup_disableHandler(u32 XPS_INT_ID);

// priority can range from 0 to 31, with 0 being the highest priority
s32 ah_scugic_setup_setInterruptPriority(u32 XPS_INT_ID, u8 priority);

#define INTR_TRIGGER_ACTIVE_HIGH 0x1
#define INTR_TRIGGER_EDGE_RISING 0x3
s32 ah_scugic_setup_setInterruptTriggerType(u32 XPS_INT_ID, u8 trigger);

s32 ah_scugic_setup_connectEnable(u32 XPS_INT_ID, s32 (*fcnptr)(void* data), void* fcndata);

s32 ah_scugic_enable(void);
u8 ah_scugic_isEnabled(void);

XScuGic* ah_scugic_getInstance(void);

s32 ah_scugic_generateSoftwareIntr(u32 interrupt_ID, u32 cpu_Id);


#endif

#endif
