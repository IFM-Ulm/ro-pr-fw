#include "xparameters.h"

#ifdef AH_GPIO_ACTIVATED

#ifdef XPAR_XGPIO_NUM_INSTANCES
#include "xgpio.h"
#endif

#include "ah_scugic.h"
#include "ah_gpio.h"

#define CHANNEL_1 0x1

#define UNUSED(x) (void)(x)

#ifdef XPAR_XGPIO_NUM_INSTANCES
static XGpio Gpio_led;
static XGpio Gpio_btn;
static XGpio Gpio_sws;
#endif

static u8 ah_gpio_intvar_isInit = 0;
static u8 ah_gpio_intvar_isSetup = 0;
static u8 ah_gpio_intvar_isSetup_initial = 0;
static u8 ah_gpio_intvar_isEnabled = 0;
static u8 ah_gpio_intvar_isEnabled_initial = 0;

#ifdef XPAR_XGPIO_NUM_INSTANCES
static u8 ah_gpio_intvar_led_value[AH_GPIO_LED_NUM];
#endif

void (*ah_gpio_intfcn_intrBTN)(u32) = NULL;
void (*ah_gpio_intfcn_intrSWS)(u32) = NULL;

void btn_handler(void* data);
void sws_handler(void* data);
s32 ah_gpio_intfnc_readLED(u32* led_value);

#ifdef XPAR_XGPIO_NUM_INSTANCES

s32 ah_gpio_init(void){
	
	if(!ah_gpio_intvar_isInit){
		
		for (u8 ind = 0; ind < AH_GPIO_LED_NUM; ++ind){
			ah_gpio_intvar_led_value[ind] = AH_GPIO_OFF;
		}
		
		if(!ah_scugic_isInit()){
			if (ah_scugic_init() != XST_SUCCESS) {
				return XST_FAILURE;
			}
		}
		
		ah_gpio_intvar_isInit = 1;
	}
	
	return XST_SUCCESS;
}

u8 ah_gpio_isInit(void){
	return ah_gpio_intvar_isInit;
}

s32 ah_gpio_setup(u8 re_setup){
	
	if(!ah_gpio_intvar_isInit){
		return XST_FAILURE;
	}
	
	if(!ah_gpio_intvar_isSetup_initial && re_setup){
		return XST_FAILURE;
	}
	
	if(!ah_gpio_intvar_isSetup || re_setup){
		
#ifdef AH_GPIO_DEVICE_IP_LED
		if (XGpio_Initialize(&Gpio_led, AH_GPIO_DEVICE_IP_LED) != XST_SUCCESS) {
			return XST_FAILURE;
		}
		XGpio_SetDataDirection(&Gpio_led, CHANNEL_1, 0x0); // all LEDs are outputs
#endif
		
#ifdef AH_GPIO_DEVICE_IP_BTN
		if (XGpio_Initialize(&Gpio_btn, AH_GPIO_DEVICE_IP_BTN) != XST_SUCCESS) {
			return XST_FAILURE;
		}
		XGpio_SetDataDirection(&Gpio_btn, CHANNEL_1, 0xF); // all BTNs are inputs
#endif

#ifdef AH_GPIO_DEVICE_IP_SWS
		if (XGpio_Initialize(&Gpio_sws, AH_GPIO_DEVICE_IP_SWS) != XST_SUCCESS) {
			return XST_FAILURE;
		}
		XGpio_SetDataDirection(&Gpio_sws, CHANNEL_1, 0xF); // all SWs are inputs
#endif

#ifdef AH_GPIO_INTR_IP_BTN
		if(!ah_gpio_intvar_isSetup_initial){
			if (ah_scugic_setup_connectHandler(AH_GPIO_INTR_IP_BTN, btn_handler, &Gpio_btn) != XST_SUCCESS) {
				return XST_FAILURE;
			}

			if (ah_scugic_setup_enableHandler(AH_GPIO_INTR_IP_BTN) != XST_SUCCESS) {
				return XST_FAILURE;
			}
		}
#endif

#ifdef AH_GPIO_INTR_IP_SWS
		if(!ah_gpio_intvar_isSetup_initial){
			if (ah_scugic_setup_connectHandler(AH_GPIO_INTR_IP_SWS, sws_handler, &Gpio_sws) != XST_SUCCESS) {
				return XST_FAILURE;
			}

			if (ah_scugic_setup_enableHandler(AH_GPIO_INTR_IP_SWS) != XST_SUCCESS) {
				return XST_FAILURE;
			}
		}
#endif
		
		if(!ah_gpio_intvar_isSetup_initial){
			if(!ah_scugic_isSetup()){
				if (ah_scugic_setup() != XST_SUCCESS) {
					return XST_FAILURE;
				}
			}
		}

		ah_gpio_intvar_isSetup_initial = 1;
		ah_gpio_intvar_isSetup = 1;
	}
	
	return XST_SUCCESS;
}

u8 ah_gpio_isSetup(void){
	return ah_gpio_intvar_isSetup;
}

s32 ah_gpio_setup_callbackBTN(void (*fcnptr)(u32)){
#ifdef AH_GPIO_INTR_IP_BTN
	ah_gpio_intfcn_intrBTN = fcnptr;
	return XST_SUCCESS;
#else
	UNUSED(fcnptr);
	return XST_FAILURE;
#endif
}

s32 ah_gpio_setup_callbackSWS(void (*fcnptr)(u32)){
#ifdef AH_GPIO_INTR_IP_SWS
	ah_gpio_intfcn_intrSWS = fcnptr;
	return XST_SUCCESS;
#else
	UNUSED(fcnptr);
	return XST_FAILURE;
#endif	
}

s32 ah_gpio_enable(u8 re_enable){
	
	u8 ind;
	
	if(!ah_gpio_intvar_isEnabled_initial && re_enable){
		return XST_FAILURE;
	}
	
	if(!ah_gpio_intvar_isEnabled || re_enable){
	
		if(!ah_gpio_intvar_isSetup){
			return XST_FAILURE;
		}
	
#ifdef AH_GPIO_INTR_IP_BTN
		XGpio_InterruptEnable(&Gpio_btn, CHANNEL_1);
		XGpio_InterruptGlobalEnable(&Gpio_btn);
#endif
	
#ifdef AH_GPIO_INTR_IP_SWS
		XGpio_InterruptEnable(&Gpio_sws, CHANNEL_1);
		XGpio_InterruptGlobalEnable(&Gpio_sws);
#endif

#ifdef AH_GPIO_DEVICE_IP_LED
		XGpio_DiscreteWrite(&Gpio_led, CHANNEL_1, AH_GPIO_OFF);
#endif
		if(re_enable){
			for(ind = 0; ind < AH_GPIO_LED_NUM; ++ ind){
				ah_gpio_setLED(ind, ah_gpio_intvar_led_value[ind]);
			}
		}
		
		if(!ah_gpio_intvar_isEnabled_initial){
			if(!ah_scugic_isEnabled()){
				if (ah_scugic_enable() != XST_SUCCESS) {
					return XST_FAILURE;
				}
			}
		}
		
		ah_gpio_intvar_isEnabled_initial = 1;
		ah_gpio_intvar_isEnabled = 1;
	}
	
	return XST_SUCCESS;
}

u8 ah_gpio_isEnabled(void){
	return ah_gpio_intvar_isEnabled;
}

s32 ah_gpio_setLED_raw(u32 led_value){
	
#ifdef AH_GPIO_DEVICE_IP_LED
	
	u32 mask;
	u8 ind;
	
	if(!ah_gpio_intvar_isEnabled){
		return XST_FAILURE;
	}
	
	XGpio_DiscreteWrite(&Gpio_led, CHANNEL_1, led_value);

	mask = 0;
	
	for(ind = 0; ind < AH_GPIO_LED_NUM; ++ind){
		mask = 0x1 << ind;
		ah_gpio_intvar_led_value[ind] = (led_value & mask) ? AH_GPIO_ON : AH_GPIO_OFF;
	}

	return XST_SUCCESS;
#else

	UNUSED(led_value);
	
	return XST_FAILURE;
#endif
}

s32 ah_gpio_setLED(u8 led_index, u8 led_value){
	
#ifdef AH_GPIO_DEVICE_IP_LED
	
	u32 reg;
	u32 mask;

	if(!ah_gpio_intvar_isEnabled){
		return XST_FAILURE;
	}
	
	if(led_index >= AH_GPIO_LED_NUM){
		return XST_FAILURE;
	}
	
	if(led_value != AH_GPIO_ON && led_value != AH_GPIO_OFF){
		return XST_FAILURE;
	}

	if(ah_gpio_intfnc_readLED(&reg) != XST_SUCCESS){
		return XST_FAILURE;
	}
	mask = (u32)(0x1 << led_index);
	
	if(led_value == AH_GPIO_ON){
		reg |= mask;
		ah_gpio_intvar_led_value[led_index] = AH_GPIO_ON;
	}
	else{
		reg &= ~mask;
		ah_gpio_intvar_led_value[led_index] = AH_GPIO_OFF;
	}
		
	XGpio_DiscreteWrite(&Gpio_led, CHANNEL_1, reg);
	
	return XST_SUCCESS;
	
#else
	
	UNUSED(led_index);
	UNUSED(led_value);
	
	return XST_FAILURE;
#endif
}

s32 ah_gpio_intfnc_readLED(u32* led_value){
	
	if(!ah_gpio_intvar_isEnabled){
		return XST_FAILURE;
	}
	
	if(led_value == NULL){
		return XST_FAILURE;
	}
	
	*led_value = XGpio_DiscreteRead(&Gpio_led, CHANNEL_1);
	
	return XST_SUCCESS;
}

s32 ah_gpio_getLED(u8 led_index, u8* led_value){
	
#ifdef AH_GPIO_DEVICE_IP_LED
	
	u32 readLED = 0;
	u32 compare = (u32)(0x1 << led_index);
	
	if(!ah_gpio_intvar_isEnabled){
		return XST_FAILURE;
	}
	
	if(led_index >= AH_GPIO_LED_NUM){
		return XST_FAILURE;
	}
	
	if(led_value == NULL){
		return XST_FAILURE;
	}


	if(ah_gpio_intfnc_readLED(&readLED) != XST_SUCCESS){
		return XST_FAILURE;
	}
	
	if(readLED & compare){
		*led_value = AH_GPIO_ON;
	}
	else{
		*led_value = AH_GPIO_OFF;
	}

	return XST_SUCCESS;
#else

	UNUSED(led_index);		
	UNUSED(led_value);		

	return XST_FAILURE;
#endif
}

s32 ah_gpio_getSWS(u8 sws_index, u8* value){
	
#ifdef AH_GPIO_DEVICE_IP_SWS
	
	u32 bits;
	u32 compare;
	
	if(!ah_gpio_intvar_isEnabled){
		return XST_FAILURE;
	}
	
	if(sws_index >= AH_GPIO_SWS_NUM){
		return XST_FAILURE;
	}
	
	if(value == NULL){
		return XST_FAILURE;
	}
	
	compare = (u32)(0x1 << sws_index);
	bits = XGpio_DiscreteRead(&Gpio_sws, CHANNEL_1);

	if(bits & (u32)compare){
		*value = AH_GPIO_ON;
	}
	else{
		*value = AH_GPIO_OFF;
	}

	return XST_SUCCESS;
#else

	UNUSED(sws_index);
	UNUSED(value);

	return XST_FAILURE;
#endif
}

void btn_handler(void* data){

	UNUSED(data);
	
#ifdef AH_GPIO_DEVICE_IP_BTN
	
	u32 bits = XGpio_DiscreteRead(&Gpio_btn, CHANNEL_1);
	XGpio_InterruptClear(&Gpio_btn, CHANNEL_1);
	
	if(ah_gpio_intfcn_intrBTN != NULL){
		if(bits != AH_GPIO_BTNR){ // prevent bouncing effects and callback for "button released"
			ah_gpio_intfcn_intrBTN(bits);
		}
	}
#else
	UNUSED(&Gpio_btn);
#endif
}

void sws_handler(void* data){
	
	UNUSED(data);
	
#ifdef AH_GPIO_DEVICE_IP_SWS
	
	u32 bits = XGpio_DiscreteRead(&Gpio_sws, CHANNEL_1);
	XGpio_InterruptClear(&Gpio_sws, CHANNEL_1);
	
	if(ah_gpio_intfcn_intrSWS != NULL){
		ah_gpio_intfcn_intrSWS(bits);
	}
#else
	UNUSED(&Gpio_sws);
#endif
}

#else


s32 ah_gpio_init(void){
	
	if(!ah_gpio_intvar_isInit){
				
		if(!ah_scugic_isInit()){
			if (ah_scugic_init() != XST_SUCCESS) {
				return XST_FAILURE;
			}
		}
		
		ah_gpio_intvar_isInit = 1;
	}
	
	return XST_SUCCESS;
}

u8 ah_gpio_isInit(void){
	return ah_gpio_intvar_isInit;
}

s32 ah_gpio_setup(u8 re_setup){
	
	if(!ah_gpio_intvar_isInit){
		return XST_FAILURE;
	}
	
	if(!ah_gpio_intvar_isSetup_initial && re_setup){
		return XST_FAILURE;
	}
	
	if(!ah_gpio_intvar_isSetup || re_setup){
		
		if(!ah_gpio_intvar_isSetup_initial){
			if(!ah_scugic_isSetup()){
				if (ah_scugic_setup() != XST_SUCCESS) {
					return XST_FAILURE;
				}
			}
		}
		
		ah_gpio_intvar_isSetup_initial = 1;
		ah_gpio_intvar_isSetup = 1;
	}
	
	return XST_SUCCESS;
}

u8 ah_gpio_isSetup(void){
	return ah_gpio_intvar_isSetup;
}

s32 ah_gpio_setup_callbackBTN(void (*fcnptr)(u32)){
	UNUSED(fcnptr);
	return XST_SUCCESS;
}

s32 ah_gpio_setup_callbackSWS(void (*fcnptr)(u32)){
	UNUSED(fcnptr);
	return XST_SUCCESS;
}

s32 ah_gpio_enable(u8 re_enable){
	
	if(!ah_gpio_intvar_isEnabled_initial && re_enable){
		return XST_FAILURE;
	}
	
	if(!ah_gpio_intvar_isEnabled || re_enable){
	
		if(!ah_gpio_intvar_isSetup){
			return XST_FAILURE;
		}
			
		if(!ah_gpio_intvar_isEnabled_initial){
			if(!ah_scugic_isEnabled()){
				if (ah_scugic_enable() != XST_SUCCESS) {
					return XST_FAILURE;
				}
			}
		}
		
		ah_gpio_intvar_isEnabled_initial = 1;
		ah_gpio_intvar_isEnabled = 1;
	}
	
	return XST_SUCCESS;
}

u8 ah_gpio_isEnabled(void){
	return ah_gpio_intvar_isEnabled;
}

s32 ah_gpio_setLED_raw(u32 led_value){
	
	UNUSED(led_value);
	return XST_FAILURE;
}

s32 ah_gpio_intfnc_readLED(u32* led_value){
	
	UNUSED(led_value);
	return XST_FAILURE;
}

s32 ah_gpio_setLED(u8 led_index, u8 led_value){

	UNUSED(led_index);
	UNUSED(led_value);
	
	return XST_FAILURE;
}

s32 ah_gpio_getLED(u8 led_index, u8* led_value){

	UNUSED(led_index);		
	UNUSED(led_value);		

	return XST_FAILURE;
}

s32 ah_gpio_getSWS(u8 sws_index, u8* value){

	UNUSED(sws_index);
	UNUSED(value);

	return XST_FAILURE;
}

void btn_handler(void* data){
	UNUSED(data);
}

void sws_handler(void* data){
	UNUSED(data);
}

#endif


#endif