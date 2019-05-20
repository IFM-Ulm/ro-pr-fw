#include "xparameters.h"

#ifdef AH_AMP_ACTIVATED

#include "xparameters_ps.h"
#include "xil_io.h"

#include "xil_cache.h"
#include "xreg_cortexa9.h"
#include "xpseudo_asm.h"

#include "ah_scugic.h"
#include "ah_amp.h"


#ifdef USE_AMP
#if XPAR_CPU_ID == 1 && USE_AMP == 0
#error Wrong settings for USE_AMP, must be = 1 on CPU1
#endif
#else
#if XPAR_CPU_ID == 1
#error USE_AMP undefined, must be = 1 on CPU1
#endif
#endif

#define SLCR_OCM_MAP 0x00000910

#define OCM0_LOW 0x00000000
#define OCM0_HIGH 0xFFFC0000

#define OCM1_LOW 0x00010000
#define OCM1_HIGH 0xFFFD0000

#define OCM2_LOW 0x00020000
#define OCM2_HIGH 0xFFFE0000

#define OCM3_LOW 0x00030000
#define OCM3_HIGH 0xFFFF0000


#define SLCR_BOOT_MODE 0x0000025C

#define JTAG_MODE			0x00000000
#define QSPI_MODE			0x00000001
#define NOR_FLASH_MODE		0x00000002
#define NAND_FLASH_MODE		0x00000004
#define SD_MODE				0x00000005
#define MMC_MODE			0x00000006

#define CPU1_START_ADDR 0xFFFFFFF0

// ToDo this address must be a parameter in the bsp?
#define APP_CPU1_ADDR	0x08100000

#define CPU_ID (XPAR_CPU_ID+1)
#define CPU0_ID 1
#define CPU1_ID 2

#define U32_OFFSET 0x00000004
#define U8_OFFSET 0x00000001

#define SEMAPHORES_MAX_NUMBER 16
#define IPI_ID 1
#define IPI_ADDR_CPU0 16
#define IPI_ADDR_CPU1 17

static u32 ah_amp_intvar_ocm0_addr = OCM0_LOW;
static u32 ah_amp_intvar_ocm1_addr = OCM1_LOW;
static u32 ah_amp_intvar_ocm2_addr = OCM2_LOW;
static u32 ah_amp_intvar_ocm3_addr = OCM3_HIGH;
static u32 ah_amp_intvar_boot_mode = OCM3_HIGH;

static u8 ah_amp_intvar_isInit = 0;
static u8 ah_amp_intvar_isSetup = 0;
static u8 ah_amp_intvar_isEnabled = 0;

static u32 ah_amp_intvar_synchronize = 0;
static u32 ah_amp_intvar_semaphores = 0;

void (*ah_amp_intfcn_swIPI)(u8) = NULL;
void sw_interrupt_handler(void* data);

s32 ah_amp_init(void){
	
	u32 ocm_map;
	u8 mapped_low = 0;
	u8 mapped_high = 0;

	if(!ah_amp_intvar_isInit){
		
		ocm_map = Xil_In32(XPS_SYS_CTRL_BASEADDR + SLCR_OCM_MAP);
		
		if(ocm_map & 0x01){
			ah_amp_intvar_ocm0_addr = OCM0_HIGH;
			mapped_high = 1;
		}
		else{
			ah_amp_intvar_ocm0_addr = OCM0_LOW;
			mapped_low = 1;
		}
		
		if(ocm_map & 0x02){
			ah_amp_intvar_ocm1_addr = OCM1_HIGH;
			mapped_high = 1;
		}
		else{
			ah_amp_intvar_ocm1_addr = OCM1_LOW;
			mapped_low = 1;
		}
		
		if(ocm_map & 0x04){
			ah_amp_intvar_ocm2_addr = OCM2_HIGH;
			mapped_high = 1;
		}
		else{
			ah_amp_intvar_ocm2_addr = OCM2_LOW;
			mapped_low = 1;
		}
	
		if(ocm_map & 0x08){
			ah_amp_intvar_ocm3_addr = OCM3_HIGH;
			mapped_high = 1;
		}
		else{
			ah_amp_intvar_ocm3_addr = OCM3_LOW;
			mapped_low = 1;
			
			// OCM3 is expected to be mapped high as CPU1_START_ADDR is set there, fail if this mapping got screwed up
			return XST_FAILURE;
		}
	
		if(mapped_low){
			// disable cache on OCM low
			Xil_SetTlbAttributes(0x00000000,0x14de2); // S=b1 TEX=b100 AP=b11, Domain=b1111, C=b0, B=b0
		}
		
		if(mapped_high){
			// disable cache on OCM high
			Xil_SetTlbAttributes(0xFFFF0000,0x14de2); // S=b1 TEX=b100 AP=b11, Domain=b1111, C=b0, B=b0
		}
		
		ah_amp_intvar_boot_mode = Xil_In32(XPS_SYS_CTRL_BASEADDR + SLCR_BOOT_MODE);
		
		ah_amp_intvar_synchronize = ah_amp_intvar_ocm2_addr;
		Xil_Out32(ah_amp_intvar_synchronize, 0);
		Xil_Out32(ah_amp_intvar_synchronize + U32_OFFSET, 0);
		
		ah_amp_intvar_semaphores = ah_amp_intvar_ocm2_addr + 2 * U32_OFFSET;
		
		if(!ah_scugic_isInit()){
			if (ah_scugic_init() != XST_SUCCESS) {
				return XST_FAILURE;
			}
		}
	
		ah_amp_intvar_isInit = 1;
	}
	
	return XST_SUCCESS;
}

u8 ah_amp_isInit(void){
	return ah_amp_intvar_isInit;
}


s32 ah_amp_setup(void){
	
	u8 ind = 0;
	
	if(!ah_amp_intvar_isInit){
		return XST_FAILURE;
	}
	
	if(!ah_amp_intvar_isSetup){
		
		for(ind = 0; ind < SEMAPHORES_MAX_NUMBER; ++ind){
			Xil_Out8(ah_amp_intvar_semaphores + ind * U8_OFFSET, 0);
		}
		
		if(ah_scugic_setup_connectHandler(IPI_ID, ah_amp_callbackIPI, NULL) != XST_SUCCESS){
			return XST_FAILURE;
		}
		
		if(!ah_scugic_isSetup()){
			if (ah_scugic_setup() != XST_SUCCESS) {
				return XST_FAILURE;
			}
		}
		
		ah_amp_intvar_isSetup = 1;
	}
	return XST_SUCCESS;
}

u8 ah_amp_isSetup(void){
	return ah_amp_intvar_isInit;
}

void ah_amp_callbackIPI(void* instance){
	
	u32 INT;
	u32 ipi_addr;
	u8 comdata;
	
	// read interrupt acknowledge register ICCIAR in order to clear the interrupt
	INT = Xil_In32(0xF8F0010C);
	
	if(CPU_ID == CPU0_ID){
		ipi_addr = IPI_ADDR_CPU0;
	}
	else{
		ipi_addr = IPI_ADDR_CPU1;
	}

	comdata = Xil_In8(ah_amp_intvar_ocm2_addr + 2 * U32_OFFSET + ipi_addr * U8_OFFSET);
	
	if(ah_amp_intfcn_swIPI != NULL){
		ah_amp_intfcn_swIPI(comdata);
	}
	
}

s32 ah_amp_setup_callbackIPI(void (*fcnptr)(u8)){
	ah_amp_intfcn_swIPI = fcnptr;
	return XST_SUCCESS;	
}

s32 ah_amp_enable(void){
	
	if(!ah_amp_intvar_isSetup){
		return XST_FAILURE;
	}
	
	ah_amp_intvar_isEnabled = 1;
	return XST_SUCCESS;
}

u8 ah_amp_isEnabled(void){
	return ah_amp_intvar_isEnabled;
}



s32 ah_amp_start_cpu1(u32 startAddress){
	
	// Programming by JTAG is either debug with manual start/control or run, which also starts both programs
	if(ah_amp_intvar_boot_mode != JTAG_MODE){

		//ah_amp_setDCache(0);
		Xil_Out32(CPU1_START_ADDR, startAddress);
		dmb(); //waits until write has finished
		sev();
	}
	
	return XST_SUCCESS;
}

s32 ah_amp_set_DCache(u8 enable){
	
	if(enable){
		Xil_DCacheEnable();
	}
	else{
		Xil_DCacheDisable();
	}
	
	return XST_SUCCESS;
}

s32 ah_amp_get_DCache(u8* enabled){
	
	register u32 CtrlReg;
	
	if(enabled == NULL){
		return XST_FAILURE;
	}

#ifdef __GNUC__
	CtrlReg = mfcp(XREG_CP15_SYS_CONTROL);
#elif defined (__ICCARM__)
	mfcp(XREG_CP15_SYS_CONTROL, CtrlReg);
#else
	{ volatile register u32 Reg __asm(XREG_CP15_SYS_CONTROL);
	  CtrlReg = Reg; }
#endif
	if ((CtrlReg & (XREG_CP15_CONTROL_C_BIT)) != 0U) {
		*enabled = 1;
	}
	else{
		*enabled = 0;
	}
	
	return XST_SUCCESS;
}

s32 ah_amp_set_ICache(u8 enable){
	
	if(enable){
		Xil_ICacheEnable();
	}
	else{
		Xil_ICacheDisable();
	}
	
	return XST_SUCCESS;
}

s32 ah_amp_get_ICache(u8* enabled){
	
	register u32 CtrlReg;

	if(enabled == NULL){
		return XST_FAILURE;
	}
	
	/* enable caches only if they are disabled */
#ifdef __GNUC__
	CtrlReg = mfcp(XREG_CP15_SYS_CONTROL);
#elif defined (__ICCARM__)
	mfcp(XREG_CP15_SYS_CONTROL, CtrlReg);
#else
	{ volatile register u32 Reg __asm(XREG_CP15_SYS_CONTROL);
	  CtrlReg = Reg; }
#endif
	if ((CtrlReg & (XREG_CP15_CONTROL_I_BIT)) != 0U) {
		*enabled = 1;
	}
	else{
		*enabled = 0;
	}
	
	return XST_SUCCESS;
}

u8 ah_amp_isJTAG(void){
	return ah_amp_intvar_boot_mode == JTAG_MODE;
}

u8 ah_amp_isNotJTAG(void){
	return ah_amp_intvar_boot_mode != JTAG_MODE;
}

u8 ah_amp_synchronizeCPUs(void){
	
	u32 waitValue = 0;
	
	if(CPU_ID == CPU0_ID){
		Xil_Out32(ah_amp_intvar_synchronize, CPU0_ID);
		waitValue = Xil_In32(ah_amp_intvar_synchronize + U32_OFFSET);
		while(waitValue != CPU1_ID){
			waitValue = Xil_In32(ah_amp_intvar_synchronize + U32_OFFSET);
		}
		Xil_Out32(ah_amp_intvar_synchronize, 0);
	}
	else{
		Xil_Out32(ah_amp_intvar_synchronize + U32_OFFSET, CPU1_ID);
		waitValue = Xil_In32(ah_amp_intvar_synchronize);
		while(waitValue != CPU0_ID){
			waitValue = Xil_In32(ah_amp_intvar_synchronize);
		}
		Xil_Out32(ah_amp_intvar_synchronize + U32_OFFSET, 0);
	}
		
	return XST_SUCCESS;
}

s32 ah_amp_interruptSiblingCPU(u8 value){
	
	u32 ipi_addr;
	u32 sibling_cpu_id;

	if(CPU_ID == CPU0_ID){
		sibling_cpu_id = CPU1_ID;
		ipi_addr = IPI_ADDR_CPU1;

	}
	else{
		sibling_cpu_id = CPU0_ID;
		ipi_addr = IPI_ADDR_CPU0;
		
	}
	
	Xil_Out8(ah_amp_intvar_ocm2_addr + 2 * U32_OFFSET + ipi_addr * U8_OFFSET, value);
	
	return ah_scugic_generateSoftwareIntr(IPI_ID, sibling_cpu_id);
}

s32 ah_amp_acquireSemaphore(u8 index){
	
	u8 readVal = Xil_In8(ah_amp_intvar_semaphores + (u32)index * U8_OFFSET);
	
	while(readVal != CPU_ID){
		if(readVal == 0){
			Xil_Out8(ah_amp_intvar_semaphores + (u32)index * U8_OFFSET, CPU_ID);
			dmb();
		}
		readVal = Xil_In8(ah_amp_intvar_semaphores + (u32)index * U8_OFFSET);	
	}
	
	return XST_SUCCESS;
}

s32 ah_amp_acquireSemaphore_nonblocking(u8 index){
	
	u8 readVal = Xil_In8(ah_amp_intvar_semaphores + (u32)index * U8_OFFSET);
	
	if(readVal == 0){
		Xil_Out8(ah_amp_intvar_semaphores + (u32)index * U8_OFFSET, CPU_ID);
		dmb();
		readVal = Xil_In8(ah_amp_intvar_semaphores + (u32)index * U8_OFFSET);
		if(readVal == CPU_ID){
			return XST_SUCCESS;
		}
		else{
			return XST_FAILURE;
		}
	}
	else{
		return XST_FAILURE;
	}
	
}

s32 ah_amp_releaseSemaphore(u8 index){
	
	u8 readVal = Xil_In8(ah_amp_intvar_semaphores + (u32)index * U8_OFFSET);

	if(readVal != CPU_ID){
		return XST_FAILURE;
	}
	
	Xil_Out8(ah_amp_intvar_semaphores + (u32)index * U8_OFFSET, 0);
	dmb();
	
	return XST_SUCCESS;
}

s32 ah_amp_deleteSemaphore(u8 index){
		
	Xil_Out8(ah_amp_intvar_semaphores + (u32)index * U8_OFFSET, 0);
	dmb();
	
	return XST_SUCCESS;
}

#endif