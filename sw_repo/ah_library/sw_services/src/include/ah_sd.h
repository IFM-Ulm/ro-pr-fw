#include "xparameters.h"

#ifndef AH_SD_H
#define AH_SD_H

/*	active usage of the SD-Card reader in the hardware:
		- open "Block Properties" of the IP "ZYNQ7 Processing System"
		- go to "MIO Configuration"
		- open "I/O Peripherials"
		- activate "SD 0" and assign "MIO 40 ... 45" (CD on "MIO 47")
*/

/*	sometimes, the SDK looses "knowing" about ff.h being activated
	in order to repair this, de-active "xilffs", regnerate sources and re-active "xilffs"

*/

#ifdef AH_SD_ACTIVATED

#include "ff.h"

#ifndef FF_DEFINED
#error library xilffs needs to be activated in order to use AH_SD
#endif

#include "xstatus.h"
#include "xil_types.h"


#define AH_SD_FLAG_OVERWRITE 	0x01
#define AH_SD_FLAG_APPEND 		0x02
#define AH_SD_FLAG_READ 		0x04

s32 ah_sd_init(void);
u8 ah_sd_isInit(void);

s32 ah_sd_mount(void);
s32 ah_sd_umount(void);
s32 ah_sd_isMounted(void);

s32 ah_sd_loadFile(char *fileName, u32 addr, u32* fileSize);
s32 ah_sd_writeFile(char* fileName, u8* data, u32 length);
s32 ah_sd_appendFile(char* fileName, u8* data, u32 length);

s32 ah_sd_openFile(char* fileName, u8 flag, u8* id);
s32 getFile(u8 id, FIL* file);
s32 ah_sd_closeFile(u8 id);

s32 ah_sd_readLine(u8 id, char* dest, u32* length);

#endif
#endif
