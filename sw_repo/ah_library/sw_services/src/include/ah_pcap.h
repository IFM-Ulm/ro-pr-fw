#include "xparameters.h"

#ifndef AH_PCAP_H
#define AH_PCAP_H

/* Files loaded by ah_pcap must be in the .format
	Convert .bit files to .bin by the following (exemplary) command for the TCL command line 

	file copy [format "%s/%s.runs/impl_1/toplevel.bit" $project_path $project_name] [format "%s/t1.bit" $bitstream_path]
	write_cfgmem -format BIN -interface SMAPx32 -disablebitswap -loadbit [format "up 0x0 %s/t1.bit" $bitstream_path] [format "%s/t1.bin" $bitstream_path]


*/

#ifdef AH_PCAP_ACTIVATED

#include "xstatus.h"
#include "xil_types.h"

#include "xdevcfg.h"
#include "sleep.h"


#define PCAP_RECONFIG_PARTIAL ((u32)1)
#define PCAP_RECONFIG_FULL ((u32)0)

s32 ah_pcap_init(void);
s32 ah_pcap_transferBitstream(u32 addr, u32 wordLength, u32 type);

s32 ah_pcap_decouple(u8 set);

#endif

#endif
