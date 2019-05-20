#include "xparameters.h"

#ifdef AH_XADC_ACTIVATED

#include "xadcps.h"

#include "ah_xadc.h"


// example taken (and adapted) from https://github.com/ATaylorCEngFIET/MicroZed-Chronicles/blob/master/main_part8.c
// additional material:
// https://forums.xilinx.com/t5/Xcell-Daily-Blog-Archived/Getting-the-XADC-Running-on-the-MicroZed-Adam-Taylor-s-MicroZed/ba-p/380989
// https://forums.xilinx.com/t5/Xcell-Daily-Blog-Archived/MicroZed-XADC-Software-Adam-Taylor-s-MicroZed-Chronicles-Part-8/ba-p/383861

static XAdcPs ah_xadc_intvar_inst;
static u8 ah_xadc_intvar_isInit = 0;
static u8 ah_xadc_intvar_isSetup = 0;

s32 ah_xadc_init(void){

	if(!ah_xadc_intvar_isInit){

		ah_xadc_intvar_isInit = 1;
	}
	
	return XST_SUCCESS;
}

u8 ah_xadc_isInit(void){
	return ah_xadc_intvar_isInit;
}

s32 ah_xadc_setup(u8 re_setup){

	if(!ah_xadc_intvar_isSetup || re_setup){
		
		XAdcPs_Config *ConfigPtr;
		
		ConfigPtr = XAdcPs_LookupConfig(XPAR_XADCPS_0_DEVICE_ID);
		if (ConfigPtr == NULL) {
			return XST_FAILURE;
		}

		if(XAdcPs_CfgInitialize(&ah_xadc_intvar_inst, ConfigPtr, ConfigPtr->BaseAddress) != XST_SUCCESS){
			return XST_FAILURE;
		}

		if (XAdcPs_SelfTest(&ah_xadc_intvar_inst) != XST_SUCCESS) {
			return XST_FAILURE;
		}
		
		//stop sequencer
		XAdcPs_SetSequencerMode(&ah_xadc_intvar_inst, XADCPS_SEQ_MODE_SINGCHAN);
	
		 //disable alarms
	    XAdcPs_SetAlarmEnables(&ah_xadc_intvar_inst, 0x0);
		
		//configure sequencer to just sample internal on chip parameters
		XAdcPs_SetSequencerMode(&ah_xadc_intvar_inst, XADCPS_SEQ_MODE_SAFE);

		// enable gain and offset correction of ADC and Power Supply sensor
		XAdcPs_SetCalibEnables(&ah_xadc_intvar_inst, XADCPS_CFR1_CAL_ADC_GAIN_OFFSET_MASK | XADCPS_CFR1_CAL_PS_GAIN_OFFSET_MASK);

		// enable averaging over 16 samples
		XAdcPs_SetAvg(&ah_xadc_intvar_inst, XADCPS_AVG_16_SAMPLES);

		//configure the channel enables we want to monitor
		XAdcPs_SetSeqChEnables(&ah_xadc_intvar_inst, XADCPS_SEQ_CH_TEMP);

		ah_xadc_intvar_isSetup = 1;
	}
	
	return XST_SUCCESS;
}


u8 ah_xadc_isSetup(void){
	return ah_xadc_intvar_isSetup;
}

u16 ah_xadc_readTemperature_raw(void){
	return XAdcPs_GetAdcData(&ah_xadc_intvar_inst, XADCPS_CH_TEMP);
}

u16 ah_xadc_readSupplyVoltage1V_raw(void){
	return  XAdcPs_GetAdcData(&ah_xadc_intvar_inst, XADCPS_CH_VCCINT);	
}

double ah_xadc_convertTemperature(u16 temperatureCode){
	return ((((double)temperatureCode) * 503.975) / 65536.0) - 273.15;
}

double ah_xadc_convertVoltage(u16 voltageCode){
	return (3.0 * ((double)voltageCode)) / 65536.0;
}

s32 ah_xadc_readTemperature(double* ret){
	
	u16 raw_val;
	double conv_val;
	
	if(!ah_xadc_intvar_isInit){
		return XST_FAILURE;
	}
	
	if(!ah_xadc_intvar_isSetup){
		return XST_FAILURE;
	}
	
	raw_val = ah_xadc_readTemperature_raw();
	
	conv_val = ah_xadc_convertTemperature(raw_val);
	
	*ret = conv_val;
	
	return XST_SUCCESS;
}

s32 ah_xadc_readVoltage_supply(double* ret){
	
	u16 raw_val;
	double conv_val;
	
	if(!ah_xadc_intvar_isInit){
		return XST_FAILURE;
	}
	
	if(!ah_xadc_intvar_isSetup){
		return XST_FAILURE;
	}
	
	raw_val = ah_xadc_readSupplyVoltage1V_raw();
	
	conv_val = ah_xadc_convertVoltage(raw_val);
	
	*ret = conv_val;
	
	return XST_SUCCESS;
}


#endif