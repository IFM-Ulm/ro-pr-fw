#include "xparameters.h"

#ifdef AH_PCAP_ACTIVATED

#include "ah_pcap.h"

#define SLCR_LOCK (XPAR_PS7_SLCR_0_S_AXI_BASEADDR + 0x00000004)
#define SLCR_UNLOCK (XPAR_PS7_SLCR_0_S_AXI_BASEADDR + 0x00000008)
#define SLCR_LOCK_VAL 0x767B
#define SLCR_UNLOCK_VAL 0xDF0D

#define SLCR_PCAP_CLK_CTRL (XPAR_PS7_SLCR_0_S_AXI_BASEADDR + 0x00000168)
#define SLCR_PCAP_CLK_CTRL_EN_MASK 0x1

#define SLCR_LVL_SHFTR_EN (XPAR_PS7_SLCR_0_S_AXI_BASEADDR + 0x00000900)
#define SLCR_LVL_SHFTR_NONE 0x0
#define SLCR_LVL_SHFTR_PS2PL 0xA
#define SLCR_LVL_SHFTR_ALL 0xF

static XDcfg ah_pcap_intvar_XDcfg_inst;

u32 ah_pcap_intvar_initialized = 0;

s32 ah_pcap_init(void){

	int ret = 0;
	XDcfg_Config* XDcfg_conf_p;
	
	if(!ah_pcap_intvar_initialized){
		XDcfg_conf_p = XDcfg_LookupConfig(XPAR_XDCFG_0_DEVICE_ID);
		if(XDcfg_conf_p == NULL){
			return XST_DEVICE_NOT_FOUND;
		}

		ret = XDcfg_CfgInitialize(&ah_pcap_intvar_XDcfg_inst, XDcfg_conf_p, XDcfg_conf_p->BaseAddr);
		if (ret != XST_SUCCESS) {
			return XST_FAILURE;
		}

		ret = XDcfg_SelfTest(&ah_pcap_intvar_XDcfg_inst);
		if (ret != XST_SUCCESS) {
			return XST_FAILURE;
		}

		// Enable the pcap clock.
		u32 StatusReg = Xil_In32(SLCR_PCAP_CLK_CTRL);
		if (!(StatusReg & SLCR_PCAP_CLK_CTRL_EN_MASK)) {
			Xil_Out32(SLCR_UNLOCK, SLCR_UNLOCK_VAL);
			Xil_Out32(SLCR_PCAP_CLK_CTRL, (StatusReg | SLCR_PCAP_CLK_CTRL_EN_MASK));
			Xil_Out32(SLCR_UNLOCK, SLCR_LOCK_VAL);
		}

		// Select PCAP interface for partial reconfiguration
		XDcfg_EnablePCAP(&ah_pcap_intvar_XDcfg_inst);
		XDcfg_SelectPcapInterface(&ah_pcap_intvar_XDcfg_inst);
		
		ah_pcap_intvar_initialized = 1;
	}
	
    return XST_SUCCESS;
}

s32 ah_pcap_isInit(void){
	return ah_pcap_intvar_initialized;
}

s32 ah_pcap_transferBitstream(u32 addr, u32 wordLength, u32 type){

	s32 Status;
	volatile u32 IntrStsReg = 0;
	u32 start_addr;
	//u32 end_addr;
	XDcfg* Instance;
	
	if(!ah_pcap_intvar_initialized){
		return XST_FAILURE;	
	}
	
	Instance = &ah_pcap_intvar_XDcfg_inst;
	
	start_addr = addr;
	//start_addr = XPAR_PS7_DDR_0_S_AXI_BASEADDR + ddr_offset;
	//end_addr = start_addr + wordLength*4;
	
	//if(start_addr > XPAR_PS7_DDR_0_S_AXI_HIGHADDR || end_addr > XPAR_PS7_DDR_0_S_AXI_HIGHADDR)
	//	return XST_FAILURE;
	//

	if(type != PCAP_RECONFIG_FULL && type != PCAP_RECONFIG_PARTIAL){
		return XST_INVALID_PARAM;
	}

	if (type == PCAP_RECONFIG_FULL) {
		// Disable the level-shifters from PS to PL.
		Xil_Out32(SLCR_UNLOCK, SLCR_UNLOCK_VAL);
		Xil_Out32(SLCR_LVL_SHFTR_EN, SLCR_LVL_SHFTR_PS2PL);
		Xil_Out32(SLCR_LOCK, SLCR_LOCK_VAL);
		// Initiate PL reset
		XDcfg_ClearControlRegister(Instance, XDCFG_CTRL_PCFG_PROG_B_MASK); // Reset PL
		XDcfg_SetControlRegister(Instance, XDCFG_CTRL_PCFG_PROG_B_MASK); // Init PL
	}

	// Clear DMA and PCAP Done Interrupts
	XDcfg_IntrClear(Instance, (XDCFG_IXR_DMA_DONE_MASK | XDCFG_IXR_D_P_DONE_MASK));

	// Poll PCFG_INIT
	IntrStsReg = XDcfg_ReadReg(Instance->Config.BaseAddr, XDCFG_STATUS_OFFSET);
	while((IntrStsReg & XDCFG_STATUS_PCFG_INIT_MASK) == 0){
		IntrStsReg = XDcfg_ReadReg(Instance->Config.BaseAddr, XDCFG_STATUS_OFFSET);
	}

	// Transfer bitstream from DDR into fabric in non secure mode
	Status = XDcfg_Transfer(Instance, (u32 *) start_addr, wordLength, (u32 *) XDCFG_DMA_INVALID_ADDRESS, 0, XDCFG_NON_SECURE_PCAP_WRITE);

	if (Status != XST_SUCCESS){
		return Status;
	}

	IntrStsReg = XDcfg_IntrGetStatus(Instance);
	// Poll DMA Done Interrupt
	while ((IntrStsReg & XDCFG_IXR_DMA_DONE_MASK) != XDCFG_IXR_DMA_DONE_MASK){
		IntrStsReg = XDcfg_IntrGetStatus(Instance);
	}

	 if (type == PCAP_RECONFIG_PARTIAL) {
		// Poll IXR_D_P_DONE
		while ((IntrStsReg & XDCFG_IXR_D_P_DONE_MASK) != XDCFG_IXR_D_P_DONE_MASK) {
			IntrStsReg = XDcfg_IntrGetStatus(Instance);
		}
		//decouple(0);
	} else {
		// Poll IXR_PCFG_DONE
		while ((IntrStsReg & XDCFG_IXR_PCFG_DONE_MASK) != XDCFG_IXR_PCFG_DONE_MASK) {
			IntrStsReg = XDcfg_IntrGetStatus(Instance);
		}
		// Enable the level-shifters from PS to PL.
		Xil_Out32(SLCR_UNLOCK, SLCR_UNLOCK_VAL);
		Xil_Out32(SLCR_LVL_SHFTR_EN, SLCR_LVL_SHFTR_ALL);
		Xil_Out32(SLCR_LOCK, SLCR_LOCK_VAL);
	}

	return XST_SUCCESS;
}

s32 ah_pcap_decouple(u8 set){
#ifdef XPAR_PR_DECOUPLER_0_BASEADDR	
	Xil_Out32(XPAR_PR_DECOUPLER_0_BASEADDR, (u32)set);
	return XST_SUCCESS;
#else
	return XST_FAILURE;
#endif
}

#endif