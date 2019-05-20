#include "xil_types.h"
#include "xstatus.h"

#include "ah_gpio.h"

u8 last_button_pushed = 0;
u8 switches_value = 0;
u8 switches_changed = 0;

void callback_btn(u8 btn_index){
	last_button_pushed = btn_index;
}

void callback_sws(u8 value){
	switches_value = value;
	switches_changed = 1;
}

int main(void){
	
	if(ah_gpio_init() != XST_SUCCESS){
			return XST_FAILURE;
	}
	
	// register callbacks for button pressed and switches changed
	if(ah_gpio_setup_callbackBTN(callback_btn) != XST_SUCCESS){
		return XST_FAILURE;
	}
	
	if(ah_gpio_setup_callbackSWS(callback_sws) != XST_SUCCESS){
		return XST_FAILURE;
	}
	
	if(ah_gpio_setup(0) != XST_SUCCESS){
			return XST_FAILURE;
	}
	
	if(ah_gpio_enable(0) != XST_SUCCESS){
			return XST_FAILURE;
	}
	
	// initially switch off all leds
	if(ah_gpio_setLED(AH_GPIO_LED0, AH_GPIO_OFF) != XST_SUCCESS){
			return XST_FAILURE;
	}
	if(ah_gpio_setLED(AH_GPIO_LED1, AH_GPIO_OFF) != XST_SUCCESS){
			return XST_FAILURE;
	}
	if(ah_gpio_setLED(AH_GPIO_LED2, AH_GPIO_OFF) != XST_SUCCESS){
			return XST_FAILURE;
	}
	if(ah_gpio_setLED(AH_GPIO_LED3, AH_GPIO_OFF) != XST_SUCCESS){
			return XST_FAILURE;
	}
	
	while(1){
		
		// if switches have changed (interrupt triggered), change the led values to the switch values
		if(switches_changed){
			
			if(switches_value & AH_GPIO_SWS0){
				if(ah_gpio_setLED(AH_GPIO_LED0, AH_GPIO_ON) != XST_SUCCESS){
						return XST_FAILURE;
				}
			}
			else{
				if(ah_gpio_setLED(AH_GPIO_LED0, AH_GPIO_OFF) != XST_SUCCESS){
						return XST_FAILURE;
				}
			}
			if(switches_value & AH_GPIO_SWS1){
				if(ah_gpio_setLED(AH_GPIO_LED1, AH_GPIO_ON) != XST_SUCCESS){
						return XST_FAILURE;
				}
			}
			else{
				if(ah_gpio_setLED(AH_GPIO_LED1, AH_GPIO_OFF) != XST_SUCCESS){
						return XST_FAILURE;
				}
			}
			if(switches_value & AH_GPIO_SWS2){
				if(ah_gpio_setLED(AH_GPIO_LED2, AH_GPIO_ON) != XST_SUCCESS){
						return XST_FAILURE;
				}
			}
			else{
				if(ah_gpio_setLED(AH_GPIO_LED2, AH_GPIO_OFF) != XST_SUCCESS){
						return XST_FAILURE;
				}
			}
			if(switches_value & AH_GPIO_SWS3){
				if(ah_gpio_setLED(AH_GPIO_LED3, AH_GPIO_ON) != XST_SUCCESS){
						return XST_FAILURE;
				}
			}
			else{
				if(ah_gpio_setLED(AH_GPIO_LED3, AH_GPIO_OFF) != XST_SUCCESS){
						return XST_FAILURE;
				}
			}
			
			switches_changed = 0;
		}
		
		// if button was pushed, switch off the corresponding led
		if(last_button_pushed != 0){
			
			switch(last_button_pushed){
				case AH_GPIO_BTN0:
					if(ah_gpio_setLED(AH_GPIO_LED0, AH_GPIO_OFF) != XST_SUCCESS){
							return XST_FAILURE;
					}
				break;
				case AH_GPIO_BTN1:
					if(ah_gpio_setLED(AH_GPIO_LED1, AH_GPIO_OFF) != XST_SUCCESS){
							return XST_FAILURE;
					}
				break;
				case AH_GPIO_BTN2:
					if(ah_gpio_setLED(AH_GPIO_LED2, AH_GPIO_OFF) != XST_SUCCESS){
							return XST_FAILURE;
					}
				break;
				case AH_GPIO_BTN3:
					if(ah_gpio_setLED(AH_GPIO_LED3, AH_GPIO_OFF) != XST_SUCCESS){
							return XST_FAILURE;
					}
				break;
			}
			

			last_button_pushed = 0;
		}
		
		
	}
	
}