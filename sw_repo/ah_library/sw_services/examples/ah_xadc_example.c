#include "ah_xadc.h"

int main(void){
	
	double temperature;
	double voltage;
	double temp;
	
	if(ah_xadc_init() != XST_SUCCESS){
		return XST_FAILURE;
	}
	
	if(ah_xadc_setup() != XST_SUCCESS){
		return XST_FAILURE;
	}
	
	while(1){

		if(ah_xadc_readTemperature(&temp) != XST_SUCCESS){
			return XST_FAILURE;
		}
		temperature = temp;
		
		if(ah_xadc_readVoltage_supply(&temp) != XST_SUCCESS){
			return XST_FAILURE;
		}
		voltage = temp;
	}
	
	return 0;
}