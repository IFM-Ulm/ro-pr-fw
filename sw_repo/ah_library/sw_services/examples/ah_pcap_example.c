#include "xparameters.h"

#include "ah_pcap.h"


u32 bin_DDR_offset[4] = {0x01000000, 0x01300000, 0x01600000, 0x02000000};

u32 ddr_start_addr = XPAR_PS7_DDR_0_S_AXI_BASEADDR;

int main(){
	
	u32 addr1;
	u32 size1;
	u32 addr2;
	u32 size2;

	// load file "toplevel1.bin" at ddr address XPAR_PS7_DDR_0_S_AXI_BASEADDR + 0x01000000 before
	//if(ah_sd_transferFile("toplevel1.bin", bin_DDR_offset[0], &size1) != XST_SUCCESS){
	//	return XST_FAILURE;
	//}
	// ... (see ah_sd)
	addr1 = ddr_start_addr + bin_DDR_offset[0];

	// load file "partial1.bin" at ddr address XPAR_PS7_DDR_0_S_AXI_BASEADDR + 0x01300000 before
	// ... (see ah_sd)
	//if(ah_sd_transferFile("partial1.bin", bin_DDR_offset[1], &size2) != XST_SUCCESS){
	//	return XST_FAILURE;
	//}
	addr2 = ddr_start_addr + bin_DDR_offset[1];
	
	if(ah_pcap_init() != XST_SUCCESS){
		return XST_FAILURE;
	}
	
	// load toplevel1.bin
	if(ah_pcap_transferBitstream(addr1, size1 >> 2, PCAP_RECONFIG_FULL) != XST_SUCCESS){
		return XST_FAILURE;
	}
	
	// decouple partial area
	if(ah_pcap_decouple(1) != XST_SUCCESS){
		return XST_FAILURE;
	}
	
	// load partial1.bin
	if(ah_pcap_transferBitstream(addr2, size2 >> 2, PCAP_RECONFIG_PARTIAL) != XST_SUCCESS){
		return XST_FAILURE;
	}
	
	// couple partial area
	if(ah_pcap_decouple(0) != XST_SUCCESS){
		return XST_FAILURE;
	}
	
	while(1);
	
	return XST_SCUCCESS;
}