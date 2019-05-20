/***************************** Include Files *******************************/
#include "xil_io.h"
#include "xparameters.h"
#include "xstatus.h"
#include "xil_types.h"

#include "ah_cpu2pl.h"

#ifdef AH_SCUGIC_ACTIVATED	
#include "ah_scugic.h"
#else
#include "xscugic.h"
#endif

/************************** Function Definitions ***************************/

#define AH_CPU2PL_mWriteReg(BaseAddress, RegOffset, Data) \
  	Xil_Out32((BaseAddress) + (RegOffset), (u32)(Data))

#define AH_CPU2PL_mReadReg(BaseAddress, RegOffset) \
    Xil_In32((BaseAddress) + (RegOffset))

/*  register adresses in the AXI interrupt interface (need to be multiplied with AH_CPU2PL_regOffset)
	0   : reg_global_intr_en
	1   : reg_intr_en
	2   : reg_intr_sts
	3   : reg_intr_ack
	4   : reg_intr_pending
*/
#define AH_CPU2PL_regOffset (4)

#ifndef AH_SCUGIC_ACTIVATED
XScuGic XScuGic_InterruptController;
#endif

extern AH_CPU2PL_Config AH_CPU2PL_ConfigTable[];
extern u32 AH_CPU2PL_connected_clock_pl[];
extern u32 AH_CPU2PL_connected_inputs[][32];
extern u32 AH_CPU2PL_connected_outputs[][32];
extern u32 AH_CPU2PL_connected_irq[];
extern u32 AH_CPU2PL_IRQid[];
extern u32 AH_CPU2PL_connected_intr_input[];
extern u32 AH_CPU2PL_connected_intr_output[];
extern u32 AH_CPU2PL_connected_intr_ack[];
extern u32 AH_CPU2PL_connected_axiwrite_wdata[];
extern u32 AH_CPU2PL_connected_axiwrite_aclk[];
extern u32 AH_CPU2PL_connected_axiwrite_aresetn[];
extern u32 AH_CPU2PL_connected_axiread_rdata[];
extern u32 AH_CPU2PL_connected_axiread_aclk[];
extern u32 AH_CPU2PL_connected_axiread_aresetn[];
extern u32 AH_CPU2PL_connected_axiintr_wdata[];
extern u32 AH_CPU2PL_connected_axiintr_rdata[];
extern u32 AH_CPU2PL_connected_axiintr_aclk[];
extern u32 AH_CPU2PL_connected_axiintr_aresetn[];
extern u32 AH_CPU2PL_connected_output_serial[];
extern u32 AH_CPU2PL_connected_input_serial[];

static AH_CPU2PL_inst ah_cpu2pl_intvar_instances[XPAR_AH_CPU2PL_NUM_INSTANCES];

static u8 ah_cpu2pl_intvar_isInit = 0;
static u8 ah_cpu2pl_intvar_isSetup = 0;
static u8 ah_cpu2pl_intvar_isSetup_initial = 0;
static u8 ah_cpu2pl_intvar_isEnabled = 0;
static u8 ah_cpu2pl_intvar_isEnabled_initial = 0;


// forward declarations
void mainHandler(void* arg);
s32 ah_cpu2pl_intfcn_enable_connector(void* data);
s32 ah_cpu2pl_intfcn_CfgInitialize(AH_CPU2PL_inst* InstancePtr, u16 DeviceId);
s32 ah_cpu2pl_intfcn_enableGlobalInterrupt(AH_CPU2PL_inst* InstancePtr);
s32 ah_cpu2pl_intfcn_disableGlobalInterrupt(AH_CPU2PL_inst* InstancePtr);
u8 ah_cpu2pl_intfcn_isPortInterruptEnabled(AH_CPU2PL_inst* InstancePtr, u8 port);

s32 ah_cpu2pl_init(void){
	
	u8 index;
	
	if(!ah_cpu2pl_intvar_isInit){
		
#ifdef AH_SCUGIC_ACTIVATED
		if(!ah_scugic_isInit()){
			if(ah_scugic_init() != XST_SUCCESS){
				return XST_FAILURE;
			}
		}
#else
		XScuGic_Config* XScuGic_Config_p = XScuGic_LookupConfig(XPAR_PS7_SCUGIC_0_DEVICE_ID);
		if(XScuGic_Config_p == NULL){
			return XST_FAILURE;
		}

		if(XScuGic_CfgInitialize(&XScuGic_InterruptController, XScuGic_Config_p, XScuGic_Config_p->CpuBaseAddress) != XST_SUCCESS){
			return XST_FAILURE;
		}
		Xil_ExceptionRegisterHandler(XIL_EXCEPTION_ID_INT,  (Xil_ExceptionHandler) XScuGic_InterruptHandler, &XScuGic_InterruptController);
		
		Xil_ExceptionEnable();
#endif
		
		for(index = 0; index < XPAR_AH_CPU2PL_NUM_INSTANCES; ++index){
			if(ah_cpu2pl_intfcn_CfgInitialize(&ah_cpu2pl_intvar_instances[index], index) != XST_SUCCESS){
				return XST_FAILURE;
			}
		}

		ah_cpu2pl_intvar_isInit = 1;
	}
	
	return XST_SUCCESS;
}

u8 ah_cpu2pl_isInit(void){
	return ah_cpu2pl_intvar_isInit;
}

s32 ah_cpu2pl_setup(u8 re_setup){
	
	if(!ah_cpu2pl_intvar_isInit){
		return XST_FAILURE;
	}
		
	if(!ah_cpu2pl_intvar_isSetup_initial && re_setup){
		return XST_FAILURE;
	}
	
	if(!ah_cpu2pl_intvar_isSetup || re_setup){

#ifdef AH_SCUGIC_ACTIVATED

		u8 index;
		for(index = 0; index < XPAR_AH_CPU2PL_NUM_INSTANCES; ++index){
			if(!ah_cpu2pl_intvar_isSetup_initial){
				if(ah_scugic_setup_connectEnable(ah_cpu2pl_intvar_instances[index].deviceID, ah_cpu2pl_intfcn_enable_connector, &ah_cpu2pl_intvar_instances[index]) != XST_SUCCESS){
					return XST_FAILURE;
				}
			}
			else{
				AH_CPU2PL_mWriteReg(ah_cpu2pl_intvar_instances[index].BaseAddress_irq, 1 * AH_CPU2PL_regOffset, ah_cpu2pl_intvar_instances[index].irq_bitmask);
				if(ah_cpu2pl_intvar_instances[index].irq_enabled){
					if(ah_cpu2pl_intfcn_enableGlobalInterrupt(&ah_cpu2pl_intvar_instances[index]) != XST_SUCCESS){
						return XST_FAILURE;
					}
				}
			}
		}
		
		if(!ah_cpu2pl_intvar_isSetup_initial){
			if(!ah_scugic_isSetup()){
				if(ah_scugic_setup() != XST_SUCCESS){
					return XST_FAILURE;
				}
			}
		}
#endif
		
		ah_cpu2pl_intvar_isSetup_initial = 1;
		ah_cpu2pl_intvar_isSetup = 1;
	}
	
	return XST_SUCCESS;
}

u8 ah_cpu2pl_isSetup(void){
	return ah_cpu2pl_intvar_isSetup;
}

s32 ah_cpu2pl_setup_interruptFunction(u8 id, void *irq_handleFunction){
	
	AH_CPU2PL_inst* InstancePtr;
	
	if(id >= XPAR_AH_CPU2PL_NUM_INSTANCES){
		return XST_FAILURE;
	}
	
	InstancePtr = &ah_cpu2pl_intvar_instances[id];
	
	if(InstancePtr->irq_enabled == 0){
		return XST_NOT_ENABLED;
	}
	
	if(InstancePtr->axi_intr_connected == FALSE){
		return XST_NOT_ENABLED;
	}

	if(InstancePtr->irq_connected == FALSE){
		return XST_NO_FEATURE;
	}
	
	// check if the clock for the PL is connected when advanced clocking is enable, otherwise the irq generation will not work 
	if(InstancePtr->advanced_clocking == TRUE && InstancePtr->clock_pl_connected == FALSE){
		return XST_NO_FEATURE;
	}

	// InstancePtr->irq_ID = irq_ID;
	InstancePtr->irq_handler = irq_handleFunction;

#ifdef AH_SCUGIC_ACTIVATED
	if(ah_scugic_setup_connectHandler(InstancePtr->irq_ID, mainHandler, (void*)InstancePtr) != XST_SUCCESS){
		return XST_FAILURE;
	}
	
	if(ah_scugic_setup_enableHandler(InstancePtr->irq_ID) != XST_SUCCESS){
		return XST_FAILURE;
	}
#else
	XScuGic_Connect(&XScuGic_InterruptController, InstancePtr->irq_ID, (Xil_ExceptionHandler)mainHandler, (void*)InstancePtr);
#endif

	return XST_SUCCESS;
}

s32 ah_cpu2pl_setup_interruptPort(u8 id, u8 port, u8 state){
	
	AH_CPU2PL_inst* InstancePtr;
	
	if(id >= XPAR_AH_CPU2PL_NUM_INSTANCES){
		return XST_FAILURE;
	}
	
	InstancePtr = &ah_cpu2pl_intvar_instances[id];
	
	if(!InstancePtr->irq_enabled){
		return XST_NOT_ENABLED;
	}
	
	if(InstancePtr->axi_intr_connected == FALSE){
		return XST_NOT_ENABLED;
	}
	
	if(port > InstancePtr->numIn){
		return XST_NOT_ENABLED;
	}
	
	if(state){
		InstancePtr->irq_bitmask = InstancePtr->irq_bitmask | (((u32)1) << port);
	}
	else{
		InstancePtr->irq_bitmask = InstancePtr->irq_bitmask & ~(((u32)1) << port);
	}
    	
    AH_CPU2PL_mWriteReg(InstancePtr->BaseAddress_irq, 1 * AH_CPU2PL_regOffset, InstancePtr->irq_bitmask); // enable individual interrupt(s)
	
	return XST_SUCCESS;
}

s32 ah_cpu2pl_setup_connection(u8 id, u8 ignoreInputsStatus, u8 ignoreOutputsStatus){
	
	AH_CPU2PL_inst* InstancePtr;
	
	if(id >= XPAR_AH_CPU2PL_NUM_INSTANCES){
		return XST_FAILURE;
	}
	
	InstancePtr = &ah_cpu2pl_intvar_instances[id];

	InstancePtr->ignore_connection_inputs = ignoreInputsStatus ? TRUE : FALSE;

	InstancePtr->ignore_connection_outputs = ignoreOutputsStatus ? TRUE : FALSE;
	
	return XST_SUCCESS;
}

s32 ah_cpu2pl_enable(u8 re_enable){
	
	u8 index;
	
	if(!ah_cpu2pl_intvar_isSetup){
		return XST_FAILURE;
	}

	if(!ah_cpu2pl_intvar_isEnabled_initial && re_enable){
		return XST_FAILURE;
	}
	
	if(!ah_cpu2pl_intvar_isEnabled || re_enable){
		
#ifdef AH_SCUGIC_ACTIVATED
		if(!ah_cpu2pl_intvar_isEnabled_initial){
			if(ah_scugic_enable() != XST_SUCCESS){
				return XST_FAILURE;
			}
		}
		else{
			for(index = 0; index < XPAR_AH_CPU2PL_NUM_INSTANCES; ++index){
				if(ah_cpu2pl_intvar_instances[index].irq_enabled){
					if(ah_cpu2pl_intfcn_enableGlobalInterrupt(&ah_cpu2pl_intvar_instances[index]) != XST_SUCCESS){
						return XST_FAILURE;
					}
				}
			}
		}
#else
	
	for(index = 0; index < XPAR_AH_CPU2PL_NUM_INSTANCES; ++index){
		if(ah_cpu2pl_intvar_instances[index].irq_enabled){
			if(!ah_cpu2pl_intvar_isEnabled_initial){
				XScuGic_Enable(&XScuGic_InterruptController, ah_cpu2pl_intvar_instances[index].irq_ID);
			}
			if(ah_cpu2pl_intfcn_enableGlobalInterrupt(&ah_cpu2pl_intvar_instances[index]) != XST_SUCCESS){
				return XST_FAILURE;
			}
		}
	}

#endif	
		ah_cpu2pl_intvar_isEnabled_initial = 1;
		ah_cpu2pl_intvar_isEnabled = 1;
	}

	return XST_SUCCESS;
}

u8 ah_cpu2pl_isEnabled(void){
	return ah_cpu2pl_intvar_isEnabled;
}


s32 ah_cpu2pl_get_numberInputs(u8 id, u32* value){
    
	AH_CPU2PL_inst* InstancePtr;
	
	if(id >= XPAR_AH_CPU2PL_NUM_INSTANCES){
		return XST_FAILURE;
	}
	
	InstancePtr = &ah_cpu2pl_intvar_instances[id];
	
	if(InstancePtr == NULL){
		return XST_DEVICE_NOT_FOUND;
	}

	if(InstancePtr->IsReady == 0){
		return XST_DEVICE_IS_STOPPED;
	}

	*value = InstancePtr->numIn;

	return XST_SUCCESS;
}

s32 ah_cpu2pl_get_numberOutputs(u8 id, u32* value){
    
	AH_CPU2PL_inst* InstancePtr;
	
	if(id >= XPAR_AH_CPU2PL_NUM_INSTANCES){
		return XST_FAILURE;
	}
	
	InstancePtr = &ah_cpu2pl_intvar_instances[id];
	
	if(InstancePtr == NULL){
		return XST_DEVICE_NOT_FOUND;
	}

	if(InstancePtr->IsReady == 0){
		return XST_DEVICE_IS_STOPPED;
	}

	*value = InstancePtr->numOut;
    
	return XST_SUCCESS;
}


s32 ah_cpu2pl_write(u8 id, u8 port, u32 value){
	
	AH_CPU2PL_inst* InstancePtr;
	
	if(id >= XPAR_AH_CPU2PL_NUM_INSTANCES){
		return XST_FAILURE;
	}
	
	InstancePtr = &ah_cpu2pl_intvar_instances[id];
	
    if(InstancePtr == NULL){
        return XST_DEVICE_NOT_FOUND;
	}

	if(InstancePtr->axi_write_connected == FALSE){
		return XST_NOT_ENABLED;
	}
	
    if(port > InstancePtr->numOut){
        return XST_NO_FEATURE;
	}
	

#ifndef AH_CPU2PL_IGNORE_CONNECTED_OUTPUT
	if(InstancePtr->output_serialized == 0 && InstancePtr->outputs_connected[port] == FALSE && InstancePtr->ignore_connection_outputs == FALSE){
		return XST_NO_FEATURE;
	}
	
	if(InstancePtr->output_serialized == 1 && InstancePtr->outputs_serial_connected == FALSE && InstancePtr->ignore_connection_outputs == FALSE){
		return XST_NO_FEATURE;
	}
#endif
	
	AH_CPU2PL_mWriteReg(InstancePtr->BaseAddress_write, port * AH_CPU2PL_regOffset, value);
	
	return XST_SUCCESS;
}

s32 ah_cpu2pl_read(u8 id, u8 port, u32* value){
	
	AH_CPU2PL_inst* InstancePtr;
	
	if(id >= XPAR_AH_CPU2PL_NUM_INSTANCES){
		return XST_FAILURE;
	}
	
	InstancePtr = &ah_cpu2pl_intvar_instances[id];
	
    if(InstancePtr == NULL){
		return XST_DEVICE_NOT_FOUND;
	}
        
    if(value == NULL){
		return XST_FAILURE;
	}
        
	if(InstancePtr->axi_read_connected == FALSE){
		return XST_NOT_ENABLED;
	}
		
    if(port > InstancePtr->numIn){
        return XST_NO_FEATURE;
	}
	
	
#ifndef AH_CPU2PL_IGNORE_CONNECTED_INPUT
	if(InstancePtr->input_serialized == 0 && InstancePtr->inputs_connected[port] == FALSE && InstancePtr->ignore_connection_inputs == FALSE){
		return XST_NO_FEATURE;
	}
	
	if(InstancePtr->input_serialized == 1 && InstancePtr->inputs_serial_connected == FALSE && InstancePtr->ignore_connection_inputs == FALSE){
		return XST_NO_FEATURE;
	}
#endif

	*value = AH_CPU2PL_mReadReg(InstancePtr->BaseAddress_read, port * AH_CPU2PL_regOffset);
	
	return XST_SUCCESS;
}

// internal functions not propagated

void mainHandler(void* arg){

	u32 counter;
	u32 pending;
	
	AH_CPU2PL_inst* InstancePtr = (AH_CPU2PL_inst *) arg;
	
	ah_cpu2pl_intfcn_disableGlobalInterrupt(InstancePtr);
	
	pending = AH_CPU2PL_mReadReg(InstancePtr->BaseAddress_irq, 4 * AH_CPU2PL_regOffset);

	for(counter = 0; counter < InstancePtr->numIn; counter++){
		if(pending & (((u32)0x00000001UL) << counter)){
			if(ah_cpu2pl_intfcn_isPortInterruptEnabled(InstancePtr, counter)){
				InstancePtr->irq_handler(InstancePtr, counter);
			}
		}
	}

	AH_CPU2PL_mWriteReg(InstancePtr->BaseAddress_irq, 3 * AH_CPU2PL_regOffset, pending);

	ah_cpu2pl_intfcn_enableGlobalInterrupt(InstancePtr);

}

#ifdef AH_SCUGIC_ACTIVATED	
s32 ah_cpu2pl_intfcn_enable_connector(void* data){
	
	if(!ah_cpu2pl_intvar_isSetup){
		return XST_FAILURE;
	}
	
	AH_CPU2PL_inst* InstancePtr = (AH_CPU2PL_inst*)data;
	
	if(InstancePtr->irq_enabled){
		if(ah_cpu2pl_intfcn_enableGlobalInterrupt(InstancePtr) != XST_SUCCESS){
			return XST_FAILURE;
		}
	}
	
	ah_cpu2pl_intvar_isEnabled_initial = 1;
	ah_cpu2pl_intvar_isEnabled = 1;
	
	return XST_SUCCESS;
}
#endif

s32 ah_cpu2pl_intfcn_CfgInitialize(AH_CPU2PL_inst* InstancePtr, u16 DeviceId){

    AH_CPU2PL_Config *ConfigPtr = NULL;
    u8 index;
	u8 counter;
    
    if(InstancePtr == NULL){
		return XST_FAILURE;
    }
	
    /* Lookup configuration data in the device configuration table.
    * Use this configuration info down below when initializing this
    * driver. */
    for (index = 0; index < XPAR_AH_CPU2PL_NUM_INSTANCES; index++){
        if (AH_CPU2PL_ConfigTable[index].DeviceId == DeviceId){
            ConfigPtr = &AH_CPU2PL_ConfigTable[index];
            break;
        }
    }
    if (ConfigPtr == NULL){
        InstancePtr->IsReady = 0;
        return XST_DEVICE_NOT_FOUND;
    }
    
    // Initialize the driver
	InstancePtr->deviceID = DeviceId;
    InstancePtr->BaseAddress_write = ConfigPtr->BaseAddress_write;
    InstancePtr->HighAddress_write = ConfigPtr->HighAddress_write;
    InstancePtr->BaseAddress_read = ConfigPtr->BaseAddress_read;
    InstancePtr->HighAddress_read = ConfigPtr->HighAddress_read;
	InstancePtr->BaseAddress_irq = ConfigPtr->BaseAddress_irq;
    InstancePtr->HighAddress_irq = ConfigPtr->HighAddress_irq;
    InstancePtr->irq_enabled = ConfigPtr->irq_enabled;
    InstancePtr->numIn = ConfigPtr->numIn;
    InstancePtr->numOut = ConfigPtr->numOut;
	InstancePtr->input_serialized = ConfigPtr->input_serialized;
	InstancePtr->output_serialized = ConfigPtr->output_serialized;
	InstancePtr->advanced_clocking = ConfigPtr->advanced_clocking;
	
	InstancePtr->clock_pl_connected = AH_CPU2PL_connected_clock_pl[DeviceId];
	
	InstancePtr->irq_connected = AH_CPU2PL_connected_irq[DeviceId];
	InstancePtr->irq_ID = AH_CPU2PL_IRQid[DeviceId];
	InstancePtr->irq_bitmask = 0;
	InstancePtr->irq_handler = NULL;
	
	
	
	for(counter = 0; counter < 32; counter++){
		InstancePtr->inputs_connected[counter] = AH_CPU2PL_connected_inputs[DeviceId][counter];
		InstancePtr->outputs_connected[counter] = AH_CPU2PL_connected_outputs[DeviceId][counter];	
	}
	InstancePtr->inputs_serial_connected = AH_CPU2PL_connected_input_serial[DeviceId];	
	InstancePtr->outputs_serial_connected = AH_CPU2PL_connected_output_serial[DeviceId];	
	InstancePtr->ignore_connection_inputs = FALSE;
	InstancePtr->ignore_connection_outputs = FALSE;
	
	if(AH_CPU2PL_connected_axiwrite_wdata[DeviceId] == TRUE && AH_CPU2PL_connected_axiwrite_aclk[DeviceId] == TRUE && AH_CPU2PL_connected_axiwrite_aresetn[DeviceId] == TRUE){
		InstancePtr->axi_write_connected = TRUE;
	}
	else{
		InstancePtr->axi_write_connected = FALSE;
	}
	
	if(AH_CPU2PL_connected_axiread_rdata[DeviceId] == TRUE && AH_CPU2PL_connected_axiread_aclk[DeviceId] == TRUE && AH_CPU2PL_connected_axiread_aresetn[DeviceId] == TRUE){
		InstancePtr->axi_read_connected = TRUE;
	}
	else{
		InstancePtr->axi_read_connected = FALSE;
	}
	
	if(AH_CPU2PL_connected_axiintr_wdata[DeviceId] == TRUE && AH_CPU2PL_connected_axiintr_rdata[DeviceId] == TRUE && AH_CPU2PL_connected_axiintr_aclk[DeviceId] == TRUE && AH_CPU2PL_connected_axiintr_aresetn[DeviceId] == TRUE){
		InstancePtr->axi_intr_connected = TRUE;
	}
	else{
		InstancePtr->axi_intr_connected = FALSE;
	}

    
    // Indicate the instance is now ready to use, initialized without error
    InstancePtr->IsReady = XIL_COMPONENT_IS_READY;

    return XST_SUCCESS;
}

s32 ah_cpu2pl_intfcn_enableGlobalInterrupt(AH_CPU2PL_inst* InstancePtr){
	
	if(InstancePtr->irq_enabled == 0){
		return XST_NOT_ENABLED;
	}

	AH_CPU2PL_mWriteReg(InstancePtr->BaseAddress_irq, 0 * AH_CPU2PL_regOffset, 0x00000001UL); // global interrupt

	return XST_SUCCESS;
}

s32 ah_cpu2pl_intfcn_disableGlobalInterrupt(AH_CPU2PL_inst* InstancePtr){
	
	if(InstancePtr->irq_enabled == 0){
		return XST_NOT_ENABLED;
	}
	
	AH_CPU2PL_mWriteReg(InstancePtr->BaseAddress_irq, 0 * AH_CPU2PL_regOffset, 0x0UL); // global interrupt

	return XST_SUCCESS;
}

u8 ah_cpu2pl_intfcn_isPortInterruptEnabled(AH_CPU2PL_inst* InstancePtr, u8 port){
	
	if(InstancePtr->irq_bitmask | (((u32)1) << port)){
		return 1;
	}
	else{
		return 0;
	}
}

