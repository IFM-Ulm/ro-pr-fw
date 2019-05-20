#include "ah_sd.h"

s32 scanLine(char* char_buf, u32* val1, u32* val2, u32* val3, u32* val4, u32* val5);

int main(){
	
	char write_buff[1000];
	char read_buff[1000];
	u32 test_buff[5];
	int len;
	u8 file_id;
	u32 read_len;
	
	if(ah_sd_init() != XST_SUCCESS){
		return XST_FAILURE;
	}
	
	if(ah_sd_mount() != XST_SUCCESS){
		return XST_FAILURE;
	}
	
	len = sprintf(write_buff, "5,3,4,1,2\n");
	if(len < 0){
		return XST_FAILURE;
	}
	
	if(ah_sd_writeFile("test.csv", (u8*)write_buff, len) != XST_SUCCESS){
		return XST_FAILURE;
	}
	
	len = sprintf(write_buff, "10,11,12,13,14\n");
	if(len < 0){
		return XST_FAILURE;
	}
	
	if(ah_sd_appendFile("test.csv", (u8*)write_buff, len) != XST_SUCCESS){
		return XST_FAILURE;
	}
	
	if(ah_sd_openFile("test.csv", AH_SD_FLAG_READ, &file_id) != XST_SUCCESS){
		return XST_FAILURE;
	}
	
	if(ah_sd_readLine(file_id, read_buff, &read_len) != XST_SUCCESS){
		return XST_FAILURE;
	}
	
	if(scanLine(read_buff, &test_buff[0], &test_buff[1], &test_buff[2], &test_buff[3], &test_buff[4]) != XST_SUCCESS){
		return XST_FAILURE;
	}
	
	if(test_buff[0] != 5 || test_buff[1] != 3 || test_buff[2] != 4 || test_buff[3] != 1 || test_buff[4] != 2){
		return XST_FAILURE;
	}
	
	if(ah_sd_readLine(file_id, read_buff, &read_len) != XST_SUCCESS){
		return XST_FAILURE;
	}
	
	if(scanLine(read_buff, &test_buff[0], &test_buff[1], &test_buff[2], &test_buff[3], &test_buff[4]) != XST_SUCCESS){
		return XST_FAILURE;
	}
	
	if(test_buff[0] != 10 || test_buff[1] != 11 || test_buff[2] != 12 || test_buff[3] != 13 || test_buff[4] != 14){
		return XST_FAILURE;
	}
	
	if(ah_sd_closeFile(file_id) != XST_SUCCESS){
		return XST_FAILURE;
	}
	
	if(ah_sd_umount() != XST_SUCCESS){
		return XST_FAILURE;
	}
	
	return XST_SUCCESS;
}


s32 scanLine(char* char_buf, u32* val1, u32* val2, u32* val3, u32* val4, u32* val5){

	if(char_buf == NULL){
		return XST_FAILURE;
	}
	
	if(sscanf(char_buf, "%lu,%lu,%lu,%lu,%lu", val1, val2, val3, val4, val5) != 5){
		return XST_FAILURE;
	}

	return XST_SUCCESS;
}