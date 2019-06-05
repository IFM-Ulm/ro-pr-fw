#include "xparameters.h"

#ifdef AH_SD_ACTIVATED

#include "ff.h"

#include "xil_cache.h"
#include "xreg_cortexa9.h"
#include "xpseudo_asm.h"

#include "ah_sd.h"

static FATFS ah_sd_intvar_FS_instance;
static u32 ah_sd_intvar_isInit = 0;
static u32 ah_sd_intvar_mounted = 0;

static FIL files_list[256];
static u8 files_status[256];
static u8 files_counter = 0;

s32 ah_sd_init(void){
	
		if(!ah_sd_intvar_isInit){
			
			for(u32 ind = 0; ind < 256; ++ind){
				files_status[ind] = 0;
			}
			
			files_counter = 0;
			
			ah_sd_intvar_isInit = 1;
		}
		
		return XST_SUCCESS;
}

u8 ah_sd_isInit(void){
	return ah_sd_intvar_isInit;
}

s32 ah_sd_mount(void){
	
	FRESULT ff_result;
	
	if(!ah_sd_intvar_isInit){
		return XST_FAILURE;
	}
	
	if(!ah_sd_intvar_mounted){
		ff_result = f_mount(&ah_sd_intvar_FS_instance,"0:/", 1);
		if (ff_result != FR_OK) {
			return XST_FAILURE;
		}
		ah_sd_intvar_mounted = 1;
	}
	
    return XST_SUCCESS;
}

s32 ah_sd_umount(void){
	
	FRESULT ff_result;
	
	if(!ah_sd_intvar_isInit){
		return XST_FAILURE;
	}
	
	if(ah_sd_intvar_mounted){
		
		// check for open files?
		
		ff_result = f_mount(NULL,"0:/", 0);
		ah_sd_intvar_mounted = 0;
		if (ff_result != FR_OK) {
			return XST_FAILURE;
		}
	}
	
	return XST_SUCCESS;
}

s32 ah_sd_isMounted(void){
	return ah_sd_intvar_mounted;
}

u8 ah_sd_check_DCacheIsEnabled(void){

	register u32 CtrlReg;

#ifdef __GNUC__
	CtrlReg = mfcp(XREG_CP15_SYS_CONTROL);
#elif defined (__ICCARM__)
	mfcp(XREG_CP15_SYS_CONTROL, CtrlReg);
#else
	{ volatile register u32 Reg __asm(XREG_CP15_SYS_CONTROL);
	  CtrlReg = Reg; }
#endif
	if ((CtrlReg & (XREG_CP15_CONTROL_C_BIT)) != 0U) {
		return 1;
	}
	else{
		return 0;
	}
}

s32 ah_sd_loadFile(char *fileName, u32 addr, u32* fileSize){

	FIL fil;
	FILINFO finf;
	FRESULT ff_result;
	UINT br;
	
	ff_result = f_stat(fileName, &finf);
	if(ff_result != FR_OK) {
		return XST_FAILURE;
	}
	
	ff_result = f_open(&fil, fileName, FA_READ);
	if(ff_result != FR_OK) {
		return XST_FAILURE;
	}

	ff_result = f_lseek(&fil, 0);
	if(ff_result != FR_OK) {
		return XST_FAILURE;
	}

	ff_result = f_read(&fil, (void*) addr, finf.fsize, &br);
	if(ff_result != FR_OK) {
		return XST_FAILURE;
	}

	ff_result = f_close(&fil);
	if(ff_result != FR_OK) {
		return XST_FAILURE;
	}

	if(ah_sd_check_DCacheIsEnabled()){
		Xil_DCacheFlush();
	}

	if(fileSize != NULL){
		*fileSize = finf.fsize;
	}

	return XST_SUCCESS;
}

s32 ah_sd_writeFile(char* fileName, u8* data, u32 length){

	FIL file_data;
	FRESULT ff_result;
	UINT written;
	
	if(!ah_sd_intvar_mounted){
		return XST_FAILURE;
	}
	
	if(data == NULL || fileName == NULL){
		return XST_FAILURE;
	}
	
	ff_result = f_open(&file_data, fileName, FA_CREATE_ALWAYS | FA_WRITE);
	if(ff_result != FR_OK){
		return XST_FAILURE;
	}

	ff_result = f_write(&file_data, data, length, &written);
	if(ff_result != FR_OK){
		return XST_FAILURE;
	}

	ff_result = f_close(&file_data);
	if(ff_result != FR_OK){
		return XST_FAILURE;
	}

	return XST_SUCCESS;
}

s32 ah_sd_appendFile(char* fileName, u8* data, u32 length){

	FIL file_data;
	FILINFO finf;
	FRESULT ff_result;
	UINT written;
	
	if(!ah_sd_intvar_mounted){
		return XST_FAILURE;
	}
	
	if(data == NULL || fileName == NULL){
		return XST_FAILURE;
	}
	
	ff_result = f_stat(fileName, &finf);
	if(ff_result != FR_OK) {
		return XST_FAILURE;
	}
	
	ff_result = f_open(&file_data, fileName, FA_CREATE_NEW | FA_WRITE);
	if(ff_result != FR_OK){
		return XST_FAILURE;
	}
	
	ff_result = f_lseek(&file_data, finf.fsize);
	if(ff_result != FR_OK){
		return XST_FAILURE;
	}
	
	ff_result = f_write(&file_data, data, length, &written);
	if(ff_result != FR_OK){
		return XST_FAILURE;
	}
	
	if(written != length){
		return XST_FAILURE;
	}

	ff_result = f_close(&file_data);
	if(ff_result != FR_OK){
		return XST_FAILURE;
	}

	return XST_SUCCESS;
}

s32 ah_sd_openFile(char* fileName, u8 flag, u8* id){
	
	FIL* file_target = NULL;
	FRESULT ff_result;
	FILINFO finf;
	u32 ind;
		
	if(!ah_sd_intvar_mounted){
		return XST_FAILURE;
	}
	
	if(files_counter == 255){
		return XST_FAILURE;
	}
	
	if(id == NULL || fileName == NULL){
		return XST_FAILURE;
	}
	
	for(ind = 0; ind < 256; ++ind){
		if(files_status[ind] == 0){
			file_target = &files_list[ind];
			files_status[ind] = 1;
			++files_counter;
			*id = ind;
			break;
		}
	}
	
	if(file_target == NULL){
		return XST_FAILURE;
	}
	
	ff_result = f_stat(fileName, &finf);
	if(ff_result != FR_OK) {
		return XST_FAILURE;
	}
	
	if(flag == AH_SD_FLAG_READ){
		ff_result = f_open(file_target, fileName, FA_READ);
		files_status[ind] = 2;
	}
	else if(flag == AH_SD_FLAG_APPEND){
		ff_result = f_open(file_target, fileName, FA_CREATE_NEW | FA_WRITE);
		files_status[ind] = 3;
	}
	else if(flag == AH_SD_FLAG_OVERWRITE){
		ff_result = f_open(file_target, fileName, FA_CREATE_ALWAYS | FA_WRITE);
		files_status[ind] = 4;
	}
	else{
		return XST_FAILURE;
	}
	if (ff_result != FR_OK) {
		files_status[ind] = 1;
		return XST_FAILURE;
	}

	if(flag == AH_SD_FLAG_APPEND){
		ff_result = f_lseek (file_target, finf.fsize);
		if (ff_result != FR_OK) {
			files_status[ind] = 1;
			return XST_FAILURE;
		}
	}

	return XST_SUCCESS;	
}

s32 getFile(u8 id, FIL* file){
	
	if(!ah_sd_intvar_mounted){
		return XST_FAILURE;
	}
	
	if(files_status[id] == 0){
		return XST_FAILURE;
	}

	if(file == NULL){
		return XST_FAILURE;
	}
	
	file = &files_list[id];
	
	return XST_SUCCESS;
}

s32 ah_sd_closeFile(u8 id){
	
	FIL* file_target = NULL;
	FRESULT ff_result;
	
	if(!ah_sd_intvar_mounted){
		return XST_FAILURE;
	}
	
	if(files_status[id] < 2){
		return XST_FAILURE;
	}
	
	file_target = &files_list[id];
	
	ff_result = f_close(file_target);
	if(ff_result != FR_OK){
		files_status[id] = 1;
		return XST_FAILURE;
	}
	
	files_status[id] = 0;
	
	--files_counter;
	
	return XST_SUCCESS;
}
	

s32 ah_sd_readLine(u8 id, char* dest, u32* length){

	u32 counter = 0;
	char byte_buffer = 0;
	UINT bytes_read = 0;
	FIL* file_target = NULL;
	FRESULT ff_result;

	if(files_status[id] != 2){
		return XST_FAILURE;
	}
	
	if(dest == NULL){
		return XST_FAILURE;
	}
	
	file_target = &files_list[id];
	
	ff_result = f_read(file_target, (void*) &byte_buffer, 1, &bytes_read);
	if(ff_result != FR_OK){
		return XST_FAILURE;
	}

	if(bytes_read == 0){
		dest[0] = '\0';
		if(length != NULL){
			*length = 0;
		}
		return XST_SUCCESS;
	}

	if(byte_buffer == '\n'){
		dest[0] = '\0';
		if(length != NULL){
			*length = 0;
		}
		return XST_SUCCESS;
	}

	while(byte_buffer != '\n'){
		
		if(bytes_read > 0){
			
			if(byte_buffer != '\r'){
				dest[counter++] = byte_buffer;
			}

			ff_result = f_read(file_target, (void*) &byte_buffer, 1, &bytes_read);
			if(ff_result != FR_OK){
				return XST_FAILURE;
			}
		}
		else{
			break; // new line with no content
		}
	}

	dest[counter] = '\0';
	if(length != NULL){
		*length = counter;
	}
	
	return XST_SUCCESS;
}

#endif