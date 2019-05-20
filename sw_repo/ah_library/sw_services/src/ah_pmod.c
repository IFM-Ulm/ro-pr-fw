#include "xparameters.h"

#ifdef AH_PMOD_ACTIVATED

#include "xgpiops.h"
#include "xgpio.h"

#include "ah_pmod.h"

#define CHANNEL_1 0x1

static XGpioPs Gpio_JF;
static XGpio Gpio_JBCDE[4];

static u8 ah_pmod_intvar_id[6] = {255, 255, 255, 255, 255, 255};
static u8 ah_pmod_intvar_mode[6][8];
static u8 ah_pmod_intvar_value[6][8];

static u8 ah_pmod_intvar_isInit = 0;
static u8 ah_pmod_intvar_isSetup = 0;
static u8 ah_pmod_intvar_isEnabled = 0;

 /* GPIOPS PMOD Header JF Pins:
	JF1: MIO-13 (upper right)
	JF2: MIO-10
	JF3: MIO-11
	JF4: MIO-12 (upper left)
	JF7: MIO-0 (lower right)
	JF8: MIO-9
	JF9: MIO-14
	JF10: MIO-15 (lower left)
 */

u8 ah_pmod_intfcn_getJFpin(u8 pin);
u8 ah_pmod_intfcn_getMaskOfID(u8 id);

s32 ah_pmod_init(void){
	
	if(!ah_pmod_intvar_isInit){
		
		for(u8 id = 1; id <= 5; ++id){
			for(u8 pin = 1; pin <= 8; ++pin){
				ah_pmod_intvar_mode[id][pin-1] = 0;
				ah_pmod_intvar_value[id][pin-1] = 0;
			}
		}
		
		ah_pmod_intvar_isInit = 1;
	}
		
	return XST_SUCCESS;
}

u8 ah_pmod_isInit(void){
	return ah_pmod_intvar_isInit;
}

s32 ah_pmod_setup(void){
	
	XGpioPs_Config *ConfigPtr = NULL;
	
	if(!ah_pmod_intvar_isInit){
		return XST_FAILURE;
	}
	
	if(!ah_pmod_intvar_isSetup){
		
		// setup PMOD JB, JC, JD and JE
		for(u8 id = 1; id <= 4; ++id){
			
			if(ah_pmod_intvar_id[id] != 255){
				if(XGpio_Initialize(&Gpio_JBCDE[id-1], ah_pmod_intvar_id[id]) != XST_SUCCESS){
					return XST_FAILURE;
				}
				XGpio_SetDataDirection(&Gpio_JBCDE[id-1], CHANNEL_1, ah_pmod_intfcn_getMaskOfID(id)); //  JB-JE: input = 1, output = 0
			}
		}
		
		
#ifdef XPAR_XGPIOPS_0_DEVICE_ID
		if(ah_pmod_intvar_id[5] != 255){
			
			// setup PMOD JF		
			ConfigPtr = XGpioPs_LookupConfig(XPAR_XGPIOPS_0_DEVICE_ID);
			if (ConfigPtr == NULL) {
				return XST_FAILURE;
			}

			if (XGpioPs_CfgInitialize(&Gpio_JF, ConfigPtr, ConfigPtr->BaseAddr) != XST_SUCCESS) {
				return XST_FAILURE;
			}

			for(u8 pin = 1; pin <= 8; ++pin){
				
				if(ah_pmod_intvar_mode[5][pin-1]){
					XGpioPs_SetDirectionPin(&Gpio_JF, ah_pmod_intfcn_getJFpin(pin), 0); // input for JF = 0
				}
				else{
					XGpioPs_SetDirectionPin(&Gpio_JF, ah_pmod_intfcn_getJFpin(pin), 1); // output for JF = 1
					XGpioPs_SetOutputEnablePin(&Gpio_JF, ah_pmod_intfcn_getJFpin(pin), 1);
				}
			}
		}
#endif
		
		ah_pmod_intvar_isSetup = 1;
	}
	
	return XST_SUCCESS;
}

u8 ah_pmod_isSetup(void){
	return ah_pmod_intvar_isSetup;
}

s32 ah_pmod_setupPMOD(u8 device){

	u8 gpio_id = 255;
	
	if(device != AH_PMOD_DEVICE_JB && device != AH_PMOD_DEVICE_JC && device != AH_PMOD_DEVICE_JD && 
		device != AH_PMOD_DEVICE_JE && device != AH_PMOD_DEVICE_JF){
		return XST_FAILURE;
	}
	
	if(ah_pmod_intvar_id[device - 1] == 255){
		
		switch(device - 1){
			case 1:
#ifdef AH_GPIO_DEVICE_IP_JB
				gpio_id = AH_GPIO_DEVICE_IP_JB;
#endif
			break;
			case 2:
#ifdef AH_GPIO_DEVICE_IP_JC
				gpio_id = AH_GPIO_DEVICE_IP_JC;
#endif
			break;
			case 3:
#ifdef AH_GPIO_DEVICE_IP_JD
				gpio_id = AH_GPIO_DEVICE_IP_JD;
#endif
			break;
			case 4:
#ifdef AH_GPIO_DEVICE_IP_JE
				gpio_id = AH_GPIO_DEVICE_IP_JE;
#endif
			break;
			case 5:
#ifdef XPAR_XGPIOPS_0_DEVICE_ID
				gpio_id = XPAR_XGPIOPS_0_DEVICE_ID;
#endif
			break;
		}

		if(gpio_id == 255){
			return XST_FAILURE;
		}
		
		ah_pmod_intvar_id[device - 1] = gpio_id;
	}

	return XST_SUCCESS;
}

s32 ah_pmod_setupPin(u8 device, u8 pin, u8 mode){
	
	u8 int_id = 0;
	
	if(device != AH_PMOD_DEVICE_JB && device != AH_PMOD_DEVICE_JC && device != AH_PMOD_DEVICE_JD && 
		device != AH_PMOD_DEVICE_JE && device != AH_PMOD_DEVICE_JF){
		return XST_FAILURE;
	}
	
	if(pin != AH_PMOD_PIN_1 && pin != AH_PMOD_PIN_2 && pin != AH_PMOD_PIN_3 && pin != AH_PMOD_PIN_4 &&
		pin != AH_PMOD_PIN_5 && pin != AH_PMOD_PIN_6 && pin != AH_PMOD_PIN_7 && pin != AH_PMOD_PIN_8){
		return XST_FAILURE;
	}
	
	if(mode != AH_PMOD_PIN_IN && mode != AH_PMOD_PIN_OUT){
		return XST_FAILURE;
	}
	
	int_id = device - 1;
		
	if(ah_pmod_intvar_id[int_id] == 255){
		ah_pmod_intvar_id[int_id] = 254;
	}
	
	if(mode == AH_PMOD_PIN_IN){
		ah_pmod_intvar_mode[int_id][pin-1] = 1;
	}
	else{
		ah_pmod_intvar_mode[int_id][pin-1] = 0;
	}
	
	return XST_SUCCESS;
}

s32 ah_pmod_enable(void){
	ah_pmod_intvar_isEnabled = 1;
	return XST_SUCCESS;
}

u8 ah_pmod_isEnabled(void){
	return ah_pmod_intvar_isEnabled;
}


s32 ah_pmod_writePin(u8 device, u8 pin, u8 value){

	if(device != AH_PMOD_DEVICE_JB && device != AH_PMOD_DEVICE_JC && device != AH_PMOD_DEVICE_JD && 
		device != AH_PMOD_DEVICE_JE && device != AH_PMOD_DEVICE_JF){
		return XST_FAILURE;
	}
	
	if(pin != AH_PMOD_PIN_1 && pin != AH_PMOD_PIN_2 && pin != AH_PMOD_PIN_3 && pin != AH_PMOD_PIN_4 &&
		pin != AH_PMOD_PIN_5 && pin != AH_PMOD_PIN_6 && pin != AH_PMOD_PIN_7 && pin != AH_PMOD_PIN_8){
		return XST_FAILURE;
	}
	
	if(value != AH_PMOD_VDD && value != AH_PMOD_GND){
			return XST_FAILURE;
	}
	
	// check if pin is set up as output and return otherwise
	if(ah_pmod_intvar_mode[device - 1][pin - 1]){
		return XST_FAILURE;
	}
		
	ah_pmod_intvar_value[device - 1][pin - 1] = value;
	
	if(device == AH_PMOD_DEVICE_JF){
		XGpioPs_WritePin(&Gpio_JF, ah_pmod_intfcn_getJFpin(pin), value);
	}
	else{
		ah_pmod_intvar_value[device - 1][pin - 1]= value;
		XGpio_DiscreteWrite(&Gpio_JBCDE[device - 2], CHANNEL_1, ah_pmod_intfcn_getMaskOfID(device - 1));
	}
	
	return XST_SUCCESS;
}

s32 ah_pmod_readPin(u8 device, u8 pin, u8* value){

	u32 readData = 0;
	
	if(device != AH_PMOD_DEVICE_JB && device != AH_PMOD_DEVICE_JC && device != AH_PMOD_DEVICE_JD && 
		device != AH_PMOD_DEVICE_JE && device != AH_PMOD_DEVICE_JF){
		return XST_FAILURE;
	}

	if(pin != AH_PMOD_PIN_1 && pin != AH_PMOD_PIN_2 && pin != AH_PMOD_PIN_3 && pin != AH_PMOD_PIN_4 &&
		pin != AH_PMOD_PIN_5 && pin != AH_PMOD_PIN_6 && pin != AH_PMOD_PIN_7 && pin != AH_PMOD_PIN_8){
		return XST_FAILURE;
	}
	
	if(!ah_pmod_intvar_mode[device - 1][pin - 1]){
		return XST_FAILURE;
	}
	
	if(device == AH_PMOD_DEVICE_JF){
		readData = XGpioPs_ReadPin(&Gpio_JF, ah_pmod_intfcn_getJFpin(pin));
	}
	else{
		readData = XGpio_DiscreteRead(&Gpio_JBCDE[device - 2], CHANNEL_1);
	}
	
	if(readData){
		*value = AH_PMOD_VDD;
	}
	else{
		*value = AH_PMOD_GND;
	}
	
	return XST_SUCCESS;
}

u8 ah_pmod_intfcn_getJFpin(u8 pin){
		
	u8 jf_pin = 255;

	switch(pin){
		case(AH_PMOD_PIN_1):
			jf_pin = 13;
		break;
		case(AH_PMOD_PIN_2):
			jf_pin = 10;
		break;
		case(AH_PMOD_PIN_3):
			jf_pin = 11;
		break;
		case(AH_PMOD_PIN_4):
			jf_pin = 12;
		break;
		case(AH_PMOD_PIN_5):
			jf_pin = 0;
		break;
		case(AH_PMOD_PIN_6):
			jf_pin = 9;
		break;
		case(AH_PMOD_PIN_7):
			jf_pin = 14;
		break;
		case(AH_PMOD_PIN_8):
			jf_pin = 15;
		break;
	}
	
	return jf_pin;
}

u8 ah_pmod_intfcn_getMaskOfID(u8 id){
	
	u8 ret = 0;
	
	for(u8 ind = 0; ind < 8; ++ind){
		if(ah_pmod_intvar_mode[id][ind]){
			ret |= 1 << ind;
		}
	}
	
	return ret;
}



#endif