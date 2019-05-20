#include "xparameters.h"

#ifndef AH_XADC_H
#define AH_XADC_H

#ifdef AH_XADC_ACTIVATED

#ifndef XPAR_XADCPS_0_DEVICE_ID
#error "IP XADC wizards" needs to be activated with "generic" set as driver in order to use AH_XADC
#endif

#include "xstatus.h"
#include "xil_types.h"

s32 ah_xadc_init(void);
u8 ah_xadc_isInit(void);

s32 ah_xadc_setup(u8 re_setup);
u8 ah_xadc_isSetup(void);

s32 ah_xadc_readTemperature(double* ret);
s32 ah_xadc_readVoltage_supply(double* ret);


u16 ah_xadc_readTemperature_raw(void);
u16 ah_xadc_readSupplyVoltage1V_raw(void);
double ah_xadc_convertTemperature(u16 temperatureCode);
double ah_xadc_convertVoltage(u16 voltageCode);

#endif
#endif
