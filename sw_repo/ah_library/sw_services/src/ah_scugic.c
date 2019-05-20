#include "xparameters.h"

#ifdef AH_SCUGIC_ACTIVATED

#include <stdlib.h>

#include "xparameters_ps.h"
#include "xil_exception.h"

#include "ah_scugic.h"

static XScuGic ah_scugic_intvar_instance;
static u8 ah_scugic_intvar_isInit = 0;
static u8 ah_scugic_intvar_isSetup = 0;
static u8 ah_scugic_intvar_isEnabled = 0;

struct enableFcn {
	struct enableFcn* next;
	s32 (*fcnptr)(void* data);
	void* data;
	u32 id;
	s32 status;
};

static struct enableFcn* ah_scugic_intvar_listenables = NULL;

// forward declarations of internal functions
s32 ah_scugic_intfcn_enableconnected(void);
s32 ah_scugic_intfcn_enableinterrupts(void);
s32 ah_scugic_intfcn_disableinterrupts(void);
s32 ah_scugic_intfcn_getInterruptPriority(u32 XPS_INT_ID, u8* priority);


s32 ah_scugic_init(void){

	XScuGic_Config* XScuGic_Config_p = NULL;

	if(ah_scugic_intvar_isInit == 0){

		XScuGic_Config_p = XScuGic_LookupConfig(XPAR_SCUGIC_SINGLE_DEVICE_ID);
		if(XScuGic_Config_p == NULL){
			return XST_FAILURE;
		}

		if(XScuGic_CfgInitialize(&ah_scugic_intvar_instance, XScuGic_Config_p, XScuGic_Config_p->CpuBaseAddress) != XST_SUCCESS){
			return XST_FAILURE;
		}

		Xil_ExceptionInit();

		Xil_ExceptionRegisterHandler(XIL_EXCEPTION_ID_INT, (Xil_ExceptionHandler) XScuGic_InterruptHandler,	&ah_scugic_intvar_instance);

		ah_scugic_intvar_isInit = 1;

	}

	return XST_SUCCESS;
}

u8 ah_scugic_isInit(void){
	return ah_scugic_intvar_isInit;
}

s32 ah_scugic_setup(void){
	ah_scugic_intvar_isSetup = 1;
	return XST_SUCCESS;
}

u8 ah_scugic_isSetup(void){
	return ah_scugic_intvar_isSetup;
}

s32 ah_scugic_setup_connectHandler(u32 XPS_INT_ID, void (*fcnptr)(void* data), void* fcndata){

	if(ah_scugic_intvar_isInit == 0){
		return XST_FAILURE;
	}

	if(XScuGic_Connect(&ah_scugic_intvar_instance, XPS_INT_ID, (Xil_InterruptHandler) fcnptr, (void *) fcndata) != XST_SUCCESS){
		return XST_FAILURE;
	}

	return XST_SUCCESS;
}

s32 ah_scugic_setup_enableHandler(u32 XPS_INT_ID){

	if(ah_scugic_intvar_isInit == 0){
		return XST_FAILURE;
	}

	XScuGic_Enable(&ah_scugic_intvar_instance, XPS_INT_ID);

	return XST_SUCCESS;
}

s32 ah_scugic_setup_disableHandler(u32 XPS_INT_ID){

	if(ah_scugic_intvar_isInit == 0){
		return XST_FAILURE;
	}

	XScuGic_Disable(&ah_scugic_intvar_instance, XPS_INT_ID);

	return XST_SUCCESS;
}

s32 ah_scugic_setup_setInterruptPriority(u32 XPS_INT_ID, u8 priority){

	u8 trigger;
	u8 local_priority;
	u8 read_priority;

	if(ah_scugic_intvar_isInit == 0 || ah_scugic_intvar_isEnabled == 1){
		return XST_FAILURE;
	}

	if(priority > 31){
		return XST_FAILURE;
	}

	local_priority = priority << 3;

	XScuGic_GetPriorityTriggerType(&ah_scugic_intvar_instance, XPS_INT_ID, &read_priority, &trigger);

	XScuGic_SetPriorityTriggerType(&ah_scugic_intvar_instance, XPS_INT_ID, local_priority, trigger);

	return XST_SUCCESS;
}

s32 ah_scugic_setup_setInterruptTriggerType(u32 XPS_INT_ID, u8 trigger){

	u8 read_trigger;
	u8 read_priority;

	if(ah_scugic_intvar_isInit == 0 || ah_scugic_intvar_isEnabled == 1){
		return XST_FAILURE;
	}

	if(trigger != 0x1 && trigger != 0x3){
		return XST_FAILURE;
	}

	XScuGic_GetPriorityTriggerType(&ah_scugic_intvar_instance, XPS_INT_ID, &read_priority, &read_trigger);

	XScuGic_SetPriorityTriggerType(&ah_scugic_intvar_instance, XPS_INT_ID, read_priority, trigger);

	return XST_SUCCESS;
}



s32 ah_scugic_setup_connectEnable(u32 XPS_INT_ID, s32 (*fcnptr)(void* data), void* fcndata){

	struct enableFcn* temp = ah_scugic_intvar_listenables;

	if(ah_scugic_intvar_isInit == 0){
		return XST_FAILURE;
	}

	if(ah_scugic_intvar_listenables == NULL){
		ah_scugic_intvar_listenables = (struct enableFcn*)malloc(sizeof(struct enableFcn));
		temp = ah_scugic_intvar_listenables;
	}
	else{
		while(temp->next != NULL){
			temp = temp->next;
		}
		temp->next = (struct enableFcn*)malloc(sizeof(struct enableFcn));
		temp = temp->next;
	}

	temp->next = NULL;
	temp->fcnptr = fcnptr;
	temp->data = fcndata;
	temp->id = XPS_INT_ID;
	temp->status = XST_DEVICE_IS_STOPPED;

	return XST_SUCCESS;
}

s32 ah_scugic_enable(void){

	if(!ah_scugic_intvar_isInit){
		return XST_FAILURE;
	}

	if(!ah_scugic_intvar_isSetup){
		return XST_FAILURE;
	}

	if(!ah_scugic_intvar_isEnabled){
		if(ah_scugic_intfcn_enableconnected() != XST_SUCCESS){
			return XST_FAILURE;
		}

		if(ah_scugic_intfcn_enableinterrupts() != XST_SUCCESS){
			return XST_FAILURE;
		}

		ah_scugic_intvar_isEnabled = 1;
	}

	return XST_SUCCESS;
}

u8 ah_scugic_isEnabled(void){
	return ah_scugic_intvar_isEnabled;
}

XScuGic* ah_scugic_getInstance(void){

	if(ah_scugic_intvar_isInit == 1){
		return &ah_scugic_intvar_instance;
	}
	else{
		return NULL;
	}

}


s32 ah_scugic_generateSoftwareIntr(u32 interrupt_ID, u32 cpu_Id){

	if(interrupt_ID >= 16){
		return XST_FAILURE;
	}
		
	return XScuGic_SoftwareIntr(&ah_scugic_intvar_instance, interrupt_ID, cpu_Id);
}



// internal, not propagated functions

s32 ah_scugic_intfcn_enableconnected(void){

	struct enableFcn* temp;

	if(ah_scugic_intvar_isInit == 0){
		return XST_FAILURE;
	}

	temp = ah_scugic_intvar_listenables;

	if(temp != NULL){
		while(temp != NULL){
			if(temp->fcnptr(temp->data) != XST_SUCCESS){
				temp->status = XST_FAILURE;
				return XST_FAILURE;
			}
			temp = temp->next;
		}
	}

	return XST_SUCCESS;
}

s32 ah_scugic_intfcn_enableinterrupts(void){

	if(ah_scugic_intvar_isInit == 0){
		return XST_FAILURE;
	}

	if(ah_scugic_intvar_isEnabled == 0){
		Xil_ExceptionEnable();
		ah_scugic_intvar_isEnabled = 1;
	}

	return XST_SUCCESS;
}

s32 ah_scugic_intfcn_disableinterrupts(void){

	if(ah_scugic_intvar_isInit == 0){
		return XST_FAILURE;
	}

	if(ah_scugic_intvar_isEnabled == 1){
		Xil_ExceptionDisableMask(XIL_EXCEPTION_IRQ);
		ah_scugic_intvar_isEnabled = 0;
	}

	return XST_SUCCESS;
}

s32 ah_scugic_intfcn_getInterruptPriority(u32 XPS_INT_ID, u8* priority){

	u8 trigger;

	if(ah_scugic_intvar_isInit == 0 || ah_scugic_intvar_isEnabled == 1){
		return XST_FAILURE;
	}

	XScuGic_GetPriorityTriggerType(&ah_scugic_intvar_instance, XPS_INT_ID, priority, &trigger);

	return XST_SUCCESS;
}

#endif