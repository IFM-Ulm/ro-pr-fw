#include "xparameters.h"

#ifndef AH_GPIO_H
#define AH_GPIO_H

#ifdef AH_GPIO_ACTIVATED

#ifndef AH_SCUGIC_ACTIVATED
#error AH_SCUGIC needs to be activated in order to use AH_GPIO
#endif

#include "xil_types.h"
#include "xstatus.h"

#define AH_GPIO_BTN0 0x0
#define AH_GPIO_BTN1 0x1
#define AH_GPIO_BTN2 0x2
#define AH_GPIO_BTN3 0x3
#define AH_GPIO_BTN4 0x3
#define AH_GPIO_BTNR 0x0

#define AH_GPIO_SWS0 0x0
#define AH_GPIO_SWS1 0x1
#define AH_GPIO_SWS2 0x2
#define AH_GPIO_SWS3 0x3
#define AH_GPIO_SWS4 0x4
#define AH_GPIO_SWS5 0x5
#define AH_GPIO_SWS6 0x6
#define AH_GPIO_SWS7 0x7

#define AH_GPIO_LED0 0x0
#define AH_GPIO_LED1 0x1
#define AH_GPIO_LED2 0x2
#define AH_GPIO_LED3 0x3
#define AH_GPIO_LED4 0x4
#define AH_GPIO_LED5 0x5
#define AH_GPIO_LED6 0x6
#define AH_GPIO_LED7 0x7

#define AH_GPIO_ON 0x1
#define AH_GPIO_OFF 0x0

#ifdef AH_BOARD_ZYBO
#define AH_BOARD_KNOWN
#define AH_GPIO_BTN_NUM 4
#define AH_GPIO_SWS_NUM 4
#define AH_GPIO_LED_NUM 4
#endif

#ifdef AH_BOARD_ZEDBOARD
#define AH_BOARD_KNOWN
#define AH_GPIO_BTN_NUM 5
#define AH_GPIO_SWS_NUM 8
#define AH_GPIO_LED_NUM 8
#endif

#ifdef AH_BOARD_PYNQ
#define AH_BOARD_KNOWN
#define AH_GPIO_BTN_NUM 4
#define AH_GPIO_SWS_NUM 2
#define AH_GPIO_LED_NUM 4
#endif

// unknown boards, access will always fail
#ifndef AH_BOARD_KNOWN
#define AH_GPIO_BTN_NUM 0
#define AH_GPIO_SWS_NUM 0
#define AH_GPIO_LED_NUM 0
#endif


s32 ah_gpio_init(void);
u8 ah_gpio_isInit(void);

s32 ah_gpio_setup(u8 re_setup);
u8 ah_gpio_isSetup(void);

s32 ah_gpio_setup_callbackBTN(void (*fcnptr)(u32));
s32 ah_gpio_setup_callbackSWS(void (*fcnptr)(u32));

s32 ah_gpio_enable(u8 re_enable);
u8 ah_gpio_isEnabled(void);

s32 ah_gpio_setLED(u8 led_index, u8 led_value);
s32 ah_gpio_setLED_raw(u32 led_value);
s32 ah_gpio_getLED(u8 led_index, u8* led_value);
s32 ah_gpio_getSWS(u8 sws_index, u8* value);


#endif

#endif