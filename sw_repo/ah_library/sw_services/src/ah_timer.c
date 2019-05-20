#include "xparameters.h"

#ifdef AH_TIMER_ACTIVATED

#include <stdlib.h>

#include "xparameters_ps.h"
#include "xscutimer.h"

#include "ah_scugic.h"
#include "ah_timer.h"

#define UNUSED(x) (void)(x)

static XScuTimer ah_timer_intvar_instance;

static u8 ah_timer_intvar_isInit = 0;
static u8 ah_timer_intvar_isSetup = 0;
static u8 ah_timer_intvar_isEnabled = 0;
static u8 ah_timer_intvar_isStarted = 0;

static u8 ah_timer_intvar_autoreload = 0;
static u32 ah_timer_intvar_timebase = AH_TIMER_TIMEBASE_1MS;
static u8 ah_timer_intvar_counterid = 1;
static u32 ah_timer_intvar_countertime = 0;

// TODO one-shot functionality missing
// TODO check of wrong inputs

struct timer_callback {
	struct timer_callback* next;
	u32 timing_count;
	u32 timing_base;
	u32 timing_compare;
	u8 enabled;

	void (*fncptr)(void* data);
	void* data;
	u32 id;
	u8 oneshot;
};

static struct timer_callback* ah_timer_intvar_listcallbacks = NULL;

// forward declarations of internal functions

s32 ah_timer_intfcn_enable_connector(void* data);
void ah_timer_intfcn_callback(void* instance);
s32 ah_timer_intfcn_setTimebase(u32 timebase);


s32 ah_timer_init(void){

	XScuTimer_Config *ConfigPtr;

	if(!ah_timer_intvar_isInit){

		if(!ah_scugic_isInit()){
			if(ah_scugic_init() != XST_SUCCESS){
				return XST_FAILURE;
			}
		}

		ConfigPtr = XScuTimer_LookupConfig(XPAR_SCUTIMER_DEVICE_ID);
		if(ConfigPtr == NULL){
			return XST_FAILURE;
		}

		if (XScuTimer_CfgInitialize(&ah_timer_intvar_instance, ConfigPtr, ConfigPtr->BaseAddr) != XST_SUCCESS) {
			return XST_FAILURE;
		}

		if (XScuTimer_SelfTest(&ah_timer_intvar_instance) != XST_SUCCESS) {
			return XST_FAILURE;
		}

		ah_timer_intvar_isInit = 1;

	}

	return XST_SUCCESS;
}

u8 ah_timer_isInit(void){
	return ah_timer_intvar_isInit;
}

s32 ah_timer_setup(void){

	if(!ah_timer_intvar_isInit){
		return XST_FAILURE;
	}

	if(!ah_timer_intvar_isSetup){
	
		if(ah_timer_intfcn_setTimebase(ah_timer_intvar_timebase) != XST_SUCCESS){
			return XST_FAILURE;
		}

		if(ah_timer_intvar_autoreload == 1){
			XScuTimer_EnableAutoReload(&ah_timer_intvar_instance);
		}
		else{
			XScuTimer_DisableAutoReload(&ah_timer_intvar_instance);
		}

		if(ah_scugic_setup_connectHandler(XPAR_SCUTIMER_INTR, ah_timer_intfcn_callback, (void*) &ah_timer_intvar_instance) != XST_SUCCESS){
			return XST_FAILURE;
		}

		if(ah_scugic_setup_enableHandler(XPAR_SCUTIMER_INTR) != XST_SUCCESS){
			return XST_FAILURE;
		}

		if(ah_scugic_setup_connectEnable(XPAR_SCUTIMER_DEVICE_ID, ah_timer_intfcn_enable_connector, NULL) != XST_SUCCESS){
			return XST_FAILURE;
		}
		
		if(!ah_scugic_isSetup()){
			if(ah_scugic_setup() != XST_SUCCESS){
				return XST_FAILURE;
			}
		}

		ah_timer_intvar_isSetup = 1;
	}
	
	return XST_SUCCESS;
}

u8 ah_timer_isSetup(void){
	return ah_timer_intvar_isSetup;
}

s32 ah_timer_setup_reloadEnable(void){

	if(ah_timer_intvar_isInit == 0){
		return XST_FAILURE;
	}

	if(ah_timer_intvar_isStarted == 1){
		return XST_FAILURE;
	}
	
	ah_timer_intvar_autoreload = 1;

	return XST_SUCCESS;
}

s32 ah_timer_setup_reloadDisable(void){

	if(ah_timer_intvar_isInit == 0){
		return XST_FAILURE;
	}

	ah_timer_intvar_autoreload = 0;
	
	return XST_SUCCESS;
}

s32 ah_timer_setup_setTimebase(u32 timebase){

	if(timebase != AH_TIMER_TIMEBASE_1US &&
			timebase != AH_TIMER_TIMEBASE_10US &&
			timebase != AH_TIMER_TIMEBASE_100US &&
			timebase != AH_TIMER_TIMEBASE_1MS &&
			timebase != AH_TIMER_TIMEBASE_10MS &&
			timebase != AH_TIMER_TIMEBASE_100MS &&
			timebase != AH_TIMER_TIMEBASE_1S){
		return XST_FAILURE;
	}

	ah_timer_intvar_timebase = timebase;

	return XST_SUCCESS;
}

s32 ah_timer_setup_callbackConnect(void (*fcnptr)(void* data), void* data, u32 count, u32 timebase, u8 oneshot, u32* id){

	struct timer_callback* temp = NULL;
	u32 compare = 0;

	if(ah_timer_intvar_isInit == 0){
		return XST_FAILURE;
	}

	if(ah_timer_intvar_isStarted == 1){
		return XST_FAILURE;
	}

	if(timebase != AH_TIMER_TIMEBASE_1US &&
			timebase != AH_TIMER_TIMEBASE_10US &&
			timebase != AH_TIMER_TIMEBASE_100US &&
			timebase != AH_TIMER_TIMEBASE_1MS &&
			timebase != AH_TIMER_TIMEBASE_10MS &&
			timebase != AH_TIMER_TIMEBASE_100MS &&
			timebase != AH_TIMER_TIMEBASE_1S){
		return XST_FAILURE;
	}

	if(timebase < ah_timer_intvar_timebase){
		compare = count / (ah_timer_intvar_timebase / timebase);
		compare = compare * (ah_timer_intvar_timebase / timebase);
		if(compare != count){
			return XST_FAILURE;
		}
	}

	compare = (count * timebase) / ah_timer_intvar_timebase;

	if(ah_timer_intvar_listcallbacks != NULL){
		temp = ah_timer_intvar_listcallbacks;
		while(temp->next != NULL){
			temp = temp->next;
		}
		temp->next = malloc(sizeof(struct timer_callback));
		temp = temp->next;
	}
	else{
		ah_timer_intvar_listcallbacks = malloc(sizeof(struct timer_callback));
		temp = ah_timer_intvar_listcallbacks;
	}

	temp->next = NULL;
	temp->id = ah_timer_intvar_counterid++;
	temp->fncptr = fcnptr;
	temp->timing_base = timebase;
	temp->timing_count = count;
	temp->timing_compare = compare;
	temp->data = data;
	temp->enabled = 0;
	temp->oneshot = oneshot;

	if(id != NULL){
		*id = temp->id;
	}

	return XST_SUCCESS;
}

s32 ah_timer_setup_callbackEnable(u32 id){

	struct timer_callback* temp = ah_timer_intvar_listcallbacks;

	if(ah_timer_intvar_isInit == 0){
		return XST_FAILURE;
	}

	if(temp == NULL){
		return XST_FAILURE;
	}

	if(temp->id == id){
		temp->enabled = 1;
		return XST_SUCCESS;
	}

	while(temp->next != NULL){
		temp = temp->next;
		if(temp->id == id){
			temp->enabled = 1;
			return XST_SUCCESS;
		}
	}

	return XST_FAILURE;
}

s32 ah_timer_setup_callbackDisable(u32 id){

	struct timer_callback* temp = ah_timer_intvar_listcallbacks;

	if(ah_timer_intvar_isInit == 0){
		return XST_FAILURE;
	}

	if(temp == NULL){
		return XST_FAILURE;
	}

	if(temp->id == id){
		temp->enabled = 1;
		return XST_SUCCESS;
	}

	while(temp->next != NULL){
		temp = temp->next;
		if(temp->id == id){
			temp->enabled = 0;
			return XST_SUCCESS;
		}
	}

	return XST_FAILURE;
}

s32 ah_timer_enable(void){

	if(!ah_timer_intvar_isSetup){
		return XST_FAILURE;
	}

	if(!ah_timer_intvar_isEnabled){
		if(ah_scugic_enable() != XST_SUCCESS){
			return XST_FAILURE;
		}
		ah_timer_intvar_isEnabled = 1;
	}

	return XST_SUCCESS;
}

u8 ah_timer_isEnabled(void){
	return ah_timer_intvar_isEnabled;
}

s32 ah_timer_start(void){

	if(!ah_timer_intvar_isInit){
		return XST_FAILURE;
	}

	if(!ah_timer_intvar_isStarted){
		XScuTimer_Start(&ah_timer_intvar_instance);
		ah_timer_intvar_isStarted = 1;
	}

	return XST_SUCCESS;
}

s32 ah_timer_stop(void){

	if(!ah_timer_intvar_isInit){
		return XST_FAILURE;
	}

	if(ah_timer_intvar_isStarted){
		XScuTimer_Stop(&ah_timer_intvar_instance);
		ah_timer_intvar_isStarted = 0;
	}

	return XST_SUCCESS;
}


// internal, not propagated functions

s32 ah_timer_intfcn_setTimebase(u32 timebase){

	u32 div_factor = 0;
	struct timer_callback* callback_inst = NULL;
	u32 prev_val = 0;
	u32 new_val = 0;

	if(ah_timer_intvar_isInit == 0){
		return XST_FAILURE;
	}

	if(ah_timer_intvar_isStarted == 1){
		return XST_FAILURE;
	}

	if(timebase != AH_TIMER_TIMEBASE_1US &&
			timebase != AH_TIMER_TIMEBASE_10US &&
			timebase != AH_TIMER_TIMEBASE_100US &&
			timebase != AH_TIMER_TIMEBASE_1MS &&
			timebase != AH_TIMER_TIMEBASE_10MS &&
			timebase != AH_TIMER_TIMEBASE_100MS &&
			timebase != AH_TIMER_TIMEBASE_1S){
		return XST_FAILURE;
	}

	switch(timebase){
		case AH_TIMER_TIMEBASE_1US:
			div_factor = 1000000;
			break;
		case AH_TIMER_TIMEBASE_10US:
			div_factor = 100000;
			break;
		case AH_TIMER_TIMEBASE_100US:
			div_factor = 10000;
			break;
		case AH_TIMER_TIMEBASE_1MS:
			div_factor = 1000;
			break;
		case AH_TIMER_TIMEBASE_10MS:
			div_factor = 100;
			break;
		case AH_TIMER_TIMEBASE_100MS:
			div_factor = 10;
			break;
		case AH_TIMER_TIMEBASE_1S:
					div_factor = 1;
					break;
		default:
			return XST_FAILURE;
	}

	if(ah_timer_intvar_listcallbacks != NULL){

		// check if any of the saved timer callbacks would fail with a new timebase
		callback_inst = ah_timer_intvar_listcallbacks;
		while(callback_inst != NULL){

			prev_val = callback_inst->timing_count * callback_inst->timing_base;
			new_val = callback_inst->timing_count * (timebase / callback_inst->timing_base);

			if(new_val * timebase != prev_val){
				return XST_FAILURE;
			}

			callback_inst = callback_inst->next;
		}

		// no fails to be expected (new timebase can be used), calculate new comparison values
		callback_inst = ah_timer_intvar_listcallbacks;
		while(callback_inst != NULL){

			callback_inst->timing_compare = callback_inst->timing_count * (timebase / callback_inst->timing_base);

			callback_inst = callback_inst->next;
		}

	}

	ah_timer_intvar_timebase = timebase;

	XScuTimer_LoadTimer(&ah_timer_intvar_instance, (XPAR_CPU_CORTEXA9_0_CPU_CLK_FREQ_HZ / 2) / div_factor);

	return XST_SUCCESS;
}

s32 ah_timer_intfcn_enable_connector(void* data){
	
	UNUSED(data);
	
	if(!ah_timer_intvar_isInit){
		return XST_FAILURE;
	}

	if(!ah_timer_intvar_isSetup){
		return XST_FAILURE;
	}

	if(!ah_timer_intvar_isEnabled){
		
		XScuTimer_EnableInterrupt(&ah_timer_intvar_instance);

		if(ah_timer_start() != XST_SUCCESS){
			return XST_FAILURE;
		}
		
		ah_timer_intvar_isEnabled = 1;
	}

	return XST_SUCCESS;
}

void ah_timer_intfcn_callback(void* instance){
	
	UNUSED(instance);
	
	++ah_timer_intvar_countertime;

	struct timer_callback* temp = ah_timer_intvar_listcallbacks;

	while(temp != NULL){

		if(temp->enabled){
			if((ah_timer_intvar_countertime % temp->timing_compare) == 0){
				temp->fncptr(temp->data);
			}
		}

		temp = temp->next;
	}

	XScuTimer_ClearInterruptStatus(&ah_timer_intvar_instance);
}

#endif