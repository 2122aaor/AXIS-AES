/******************************************************************************
*
* Copyright (C) 2013 - 2015 Xilinx, Inc.  All rights reserved.
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in
* all copies or substantial portions of the Software.
*
* Use of the Software is limited solely to applications:
* (a) running on a Xilinx device, or
* (b) that interact with a Xilinx device through a bus or interconnect.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
* XILINX  BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
* WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF
* OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
*
* Except as contained in this notice, the name of the Xilinx shall not be used
* in advertising or otherwise to promote the sale, use or other dealings in
* this Software without prior written authorization from Xilinx.
*
******************************************************************************/
/*****************************************************************************/
/**
*
* @file xilffs_polled_example.c
*
*
* @note This example uses file system with SD to write to and read from
* an SD card using ADMA2 in polled mode.
* To test this example File System should not be in Read Only mode.
* To test this example USE_MKFS option should be true.
*
* This example was tested using SD2.0 card and eMMC (using eMMC to SD adaptor).
*
* To test with different logical drives, drive number should be mentioned in
* both FileName and Path variables. By default, it will take drive 0 if drive
* number is not mentioned in the FileName variable.
* For example, to test logical drive 1
* FileName =  "1:/<file_name>" and Path = "1:/"
* Similarly to test logical drive N, FileName = "N:/<file_name>" and
* Path = "N:/"
*
* None.
*
* <pre>
* MODIFICATION HISTORY:
*
* Ver   Who Date     Changes
* ----- --- -------- -----------------------------------------------
* 1.00a hk  10/17/13 First release
* 2.2   hk  07/28/14 Make changes to enable use of data cache.
* 2.5   sk  07/15/15 Used File size as 8KB to test on emulation platform.
* 2.9   sk  06/09/16 Added support for mkfs.
*
*</pre>
*
******************************************************************************/

/***************************** Include Files *********************************/

#include "xparameters.h"	/* SDK generated parameters */
#include "xsdps.h"		/* SD device driver */
#include "xil_printf.h"
#include "ff.h"
#include "xil_cache.h"
#include "xplatform_info.h"
#include "xaxidma.h"
#include "xdebug.h"
#include "xtime_l.h"
#if defined(XPAR_UARTNS550_0_BASEADDR)
#include "xuartns550_l.h"       /* to use uartns550 */
#endif

#include "aes.h"
/************************** Constant Definitions *****************************/


/**************************** Type Definitions *******************************/

/***************** Macros (Inline Functions) Definitions *********************/

/************************** Function Prototypes ******************************/

int software_encrypt(void);
int hardware_encrypt(u16 DevId);
static void test_decrypt_ecb(u8 cipher_text[], u8 key[], int tsize);
static void test_encrypt_ecb_verbose(u8 plain_text[], u8 key[], int tsize);

#if (!defined(DEBUG))
extern void xil_printf(const char *format, ...);
#endif

int use_hardware(void);

/************************** Variable Definitions *****************************/
static FIL fil;		/* File object */
static FATFS fatfs;
/*
 * To test logical drive 0, FileName should be "0:/<File name>" or
 * "<file_name>". For logical drive 1, FileName should be "1:/<file_name>"
 */

static char FileName2[32] = "8192.txt";
static char KeyFile[32] = "key.txt";
static char CipherS[32] = "cipherS.txt";
static char CipherH[32] = "cipherH.txt";
static char *SD_File;
u32 Platform;

#ifdef __ICCARM__
#pragma data_alignment = 32
u8 DestinationAddress[10*1024*1024];
u8 SourceAddress[10*1024*1024];
#pragma data_alignment = 4
#else
u8 DestinationAddress[10*1024*1024] __attribute__ ((aligned(32)));
u8 SourceAddress[10*1024*1024] __attribute__ ((aligned(32)));
#endif

#define TEST 7

#define NUM_BYTES 16

#define DMA_DEV_ID		XPAR_AXIDMA_0_DEVICE_ID

#ifdef XPAR_AXI_7SDDR_0_S_AXI_BASEADDR
#define DDR_BASE_ADDR		XPAR_AXI_7SDDR_0_S_AXI_BASEADDR
#elif XPAR_MIG7SERIES_0_BASEADDR
#define DDR_BASE_ADDR	XPAR_MIG7SERIES_0_BASEADDR
#elif XPAR_MIG_0_BASEADDR
#define DDR_BASE_ADDR	XPAR_MIG_0_BASEADDR
#elif XPAR_PSU_DDR_0_S_AXI_BASEADDR
#define DDR_BASE_ADDR	XPAR_PSU_DDR_0_S_AXI_BASEADDR
#endif

#ifndef DDR_BASE_ADDR
#warning CHECK FOR THE VALID DDR ADDRESS IN XPARAMETERS.H, \
		 DEFAULT SET TO 0x01000000
#define MEM_BASE_ADDR		0x01000000
#else
#define MEM_BASE_ADDR		(DDR_BASE_ADDR + 0x1000000)
#endif

#define TX_BUFFER_BASE		(MEM_BASE_ADDR + 0x00100000)
#define RX_BUFFER_BASE		(MEM_BASE_ADDR + 0x00300000)
#define RX_BUFFER_HIGH		(MEM_BASE_ADDR + 0x004FFFFF)

#define MAX_PKT_LEN		32

#define TEST_START_VALUE	0xC

#define NUMBER_OF_TRANSFERS	8

XAxiDma AxiDma;
/*****************************************************************************/
/**
*
* Main function to call the SD example.
*
* @param	None
*
* @return	XST_SUCCESS if successful, otherwise XST_FAILURE.
*
* @note		None
*
******************************************************************************/
int main(void)
{

	int Status;

	xil_printf("SD Polled File System Example Test \r\n");

	XTime start, end;
	//XTime_GetTime(&start);
	//test_encrypt_ecb_verbose(buffer, keyBuffer, tsize);
	//XTime_GetTime(&end);

	XTime_GetTime(&start);
	Status = software_encrypt();
	//Status = use_hardware();
	XTime_GetTime(&end);

	if (Status != XST_SUCCESS) {
		xil_printf("SD Polled File System Example Test failed \r\n");
		return XST_FAILURE;
	}

	xil_printf("Successfully ran SD Polled File System Example Test \r\n");

	printf("\r\n");
	printf("Output took %llu clock cycles.\n", 2*(end - start));
	printf("wall time: %.2f us.\n", 1.0*(end - start)/(COUNTS_PER_SECOND/1000000));
	printf("\r\n");

	return XST_SUCCESS;

}

/*****************************************************************************/

int software_encrypt(void) {

    FRESULT Res;
	UINT NumBytesRead;
	UINT NumBytesWritten;
	u32 BuffCnt;
	u32 FileSize = (8*1024*1024);
	/*
	 * To test logical drive 0, Path should be "0:/"
	 * For logical drive 1, Path should be "1:/"
	 */
	TCHAR *Path = "0:/";

	Platform = XGetPlatform_Info();
	if (Platform == XPLAT_ZYNQ_ULTRA_MP) {
		/*
		 * Since 8MB in Emulation Platform taking long time, reduced
		 * file size to 8KB.
		 */
		FileSize = 8*1024;
	}

    Res = f_mount(&fatfs, Path, 0);

	if (Res != FR_OK) {
		return XST_FAILURE;
	}

    /*
	 * Open file with required permissions.
	 * Here - Creating new file with read/write permissions. .
	 * To open file with write permissions, file system should not
	 * be in Read Only mode.
	 */
	//Key File reading
	SD_File = (char *)KeyFile;

	Res = f_open(&fil, SD_File, FA_READ);
	if (Res) {
		return XST_FAILURE;
	}

	/*
	 * Pointer to beginning of file .
	 */
	Res = f_lseek(&fil, 0);
	if (Res) {
		return XST_FAILURE;
	}

	DWORD size = fil.fsize;
	int tsize = 0;
	if (size % NUM_BYTES == 0)
		tsize = size;
	else
		tsize = size + NUM_BYTES-(size%NUM_BYTES);

	u8 keyBuffer[tsize];

	/*
	 * Read data from file.
	 */

	Res = f_read(&fil, (void*)keyBuffer, (u32)size,
			&NumBytesRead);
	if (Res) {
		return XST_FAILURE;
	}
	//padding Not required in key. Can force read 16 bytes only.
	for (int i = size; i < tsize; i++) {
		keyBuffer[i] = 0x00;
	}

	/*
	 * Close file.
	 */
	Res = f_close(&fil);
	if (Res) {
		return XST_FAILURE;
	}

	//plain text
	SD_File = (char *)FileName2;
	Res = f_open(&fil, SD_File, FA_READ);
	if (Res) {
		return XST_FAILURE;
	}

    /*
	 * Pointer to beginning of file .
	 */
	Res = f_lseek(&fil, 0);
	if (Res) {
		return XST_FAILURE;
	}

    size = fil.fsize;

    if (size % NUM_BYTES == 0)
    	tsize = size;
    else
    	tsize = size + NUM_BYTES-(size%NUM_BYTES);

    u8 buffer[tsize];

    /*
	 * Read data from file.
	 */

	Res = f_read(&fil, (void*)buffer, (u32)size,
			&NumBytesRead);
	if (Res) {
		return XST_FAILURE;
	}

	//padding
	for (int i = size; i < tsize; i++) {
		buffer[i] = 0x00;
	}

    /*
	 * Close file.
	 */
	Res = f_close(&fil);
	if (Res) {
		return XST_FAILURE;
	}

	//XTime start, end;
	//XTime_GetTime(&start);
	test_encrypt_ecb_verbose(buffer, keyBuffer, tsize);
	//XTime_GetTime(&end);
/*
	for (int i = 0; i < tsize; i++) {
		encBuffer[i] = buffer[i];
	}

	for (int i = 0; i < tsize; i++) {
		keyEncBuffer[i] = keyBuffer[i];
	}

	for (int i = 0; i < tsize; i++) {
		printf("%.2X", encBuffer[i]);
	}
	printf("\n");
*/
	//Print encrypted text in hex form.
	int k = 0;
	for (int Index = 0; Index < tsize; Index+=4) {
		printf("%.2X%.2X%.2X%.2X ",buffer[Index],buffer[Index+1],buffer[Index+2],buffer[Index+3]);
		k++;
		if (k > 3) {
			printf("\r\n");
			k = 0;
		}
	}

	//printf("\r\n");
	//printf("Output took %llu clock cycles.\n", 2*(end - start));
	//printf("wall time: %.2f us.\n", 1.0*(end - start)/(COUNTS_PER_SECOND/1000000));
	//printf("\r\n");

	//Pass it to decryptor
	test_decrypt_ecb(buffer, keyBuffer, tsize);
	//Deciphered file management
	SD_File = (char *)CipherS;
	Res = f_open(&fil, SD_File, FA_CREATE_ALWAYS | FA_WRITE | FA_READ);
	if (Res) {
		return XST_FAILURE;
	}

	/*
	 * Pointer to beginning of file .
	 */

	Res = f_lseek(&fil, 0);
	if (Res) {
		return XST_FAILURE;
	}

	/*
	 * Write data to file.
	 */
	//write the decrypted buffer to a new file. Should match with the plaintext.
	Res = f_write(&fil, (const void*)buffer, size,	&NumBytesWritten);
	if (Res) {
		return XST_FAILURE;
	}

	Res = f_close(&fil);
	if (Res) {
		return XST_FAILURE;
	}
	return XST_SUCCESS;


}

int use_hardware()
{
	int Status;

	/* Run the poll example for simple transfer */
	Status = hardware_encrypt(DMA_DEV_ID);

	if (Status != XST_SUCCESS) {
		xil_printf("XAxiDma_SimplePoll Example Failed\r\n");
		return XST_FAILURE;
	}

	return XST_SUCCESS;

}

int hardware_encrypt(u16 DeviceId) {

    FRESULT Res;
	UINT NumBytesRead;
	UINT NumBytesWritten;
	u32 BuffCnt;
	u32 FileSize = (8*1024*1024);

	Xil_DCacheDisable();
	Xil_ICacheDisable();
	XAxiDma_Config *CfgPtr;
	int Status;
	int Tries = NUMBER_OF_TRANSFERS;
	int Index;
	u8 *TxBufferPtr;
	u8 *RxBufferPtr;
	u8 Value;
	//XTime start, end;
	TxBufferPtr = (u8 *)TX_BUFFER_BASE ;
	RxBufferPtr = (u8 *)RX_BUFFER_BASE;

	/* Initialize the XAxiDma device.
	 */
	CfgPtr = XAxiDma_LookupConfig(DeviceId);
	if (!CfgPtr) {
		xil_printf("No config found for %d\r\n", DeviceId);
		return XST_FAILURE;
	}

	Status = XAxiDma_CfgInitialize(&AxiDma, CfgPtr);
	if (Status != XST_SUCCESS) {
		xil_printf("Initialization failed %d\r\n", Status);
		return XST_FAILURE;
	}

	if(XAxiDma_HasSg(&AxiDma)){
		xil_printf("Device configured as SG mode \r\n");
		return XST_FAILURE;
	}
	/*
	 * To test logical drive 0, Path should be "0:/"
	 * For logical drive 1, Path should be "1:/"
	 */
	TCHAR *Path = "0:/";

	Platform = XGetPlatform_Info();
	if (Platform == XPLAT_ZYNQ_ULTRA_MP) {
		/*
		 * Since 8MB in Emulation Platform taking long time, reduced
		 * file size to 8KB.
		 */
		FileSize = 8*1024;
	}

    Res = f_mount(&fatfs, Path, 0);

	if (Res != FR_OK) {
		return XST_FAILURE;
	}

    /*
	 * Open file with required permissions.
	 * Here - Creating new file with read/write permissions. .
	 * To open file with write permissions, file system should not
	 * be in Read Only mode.
	 */
	//Key stuff
	SD_File = (char *)KeyFile;

	Res = f_open(&fil, SD_File, FA_READ);
	if (Res) {
		return XST_FAILURE;
	}

	/*
	 * Pointer to beginning of file .
	 */
	Res = f_lseek(&fil, 0);
	if (Res) {
		return XST_FAILURE;
	}

	DWORD size = fil.fsize;
	int tsize = 0;
	if (size % NUM_BYTES == 0)
		tsize = size;
	else
		tsize = size + NUM_BYTES-(size%NUM_BYTES);

	/*
	 * Read data from file.
	 */

	Res = f_read(&fil, (void*)TxBufferPtr, (u32)size,
			&NumBytesRead);
	if (Res) {
		return XST_FAILURE;
	}
	//padding
	for (int i = size; i < tsize; i++) {
		TxBufferPtr[i] = 0x00;
	}

	/*
	 * Close file.
	 */
	Res = f_close(&fil);
	if (Res) {
		return XST_FAILURE;
	}

	//plain text
	SD_File = (char *)FileName2;
	Res = f_open(&fil, SD_File, FA_READ);
	if (Res) {
		return XST_FAILURE;
	}

    /*
	 * Pointer to beginning of file .
	 */
	Res = f_lseek(&fil, 0);
	if (Res) {
		return XST_FAILURE;
	}

    size = fil.fsize;

    if (size % NUM_BYTES == 0)
    	tsize = size;
    else
    	tsize = size + NUM_BYTES-(size%NUM_BYTES);

    /*
	 * Read data from file.
	 */
    //Store text from 16 indices onwards
	Res = f_read(&fil, (void*)TxBufferPtr+16, (u32)size,
			&NumBytesRead);
	if (Res) {
		return XST_FAILURE;
	}

	Res = f_close(&fil);
	if (Res) {
		return XST_FAILURE;
	}
	//padding
	for (int i = size+16; i < tsize+16; i++) {
		TxBufferPtr[i] = 0x00;
	}

	//XTime_GetTime(&start);

	//Transfer
	Status = XAxiDma_SimpleTransfer(&AxiDma,(UINTPTR) TxBufferPtr,
				tsize+16, XAXIDMA_DMA_TO_DEVICE);

	if (Status != XST_SUCCESS) {
		return XST_FAILURE;
	}

	Status = XAxiDma_SimpleTransfer(&AxiDma,(UINTPTR) RxBufferPtr,
				tsize, XAXIDMA_DEVICE_TO_DMA);

	if (Status != XST_SUCCESS) {
		return XST_FAILURE;
	}

	while ((XAxiDma_Busy(&AxiDma,XAXIDMA_DEVICE_TO_DMA)) ||
		(XAxiDma_Busy(&AxiDma,XAXIDMA_DMA_TO_DEVICE))) {
			/* Wait */
	}
	//XTime_GetTime(&end);

	int k = 0;
	for (int Index = 0; Index < tsize; Index+=4) {
		printf("%.2X%.2X%.2X%.2X ",RxBufferPtr[Index],RxBufferPtr[Index+1],RxBufferPtr[Index+2],RxBufferPtr[Index+3]);
		k++;
		if (k > 3) {
			printf("\r\n");
			k = 0;
		}
	}

	//printf("\r\n");
	//printf("Output took %llu clock cycles.\n", 2*(end - start));
	//printf("wall time: %.2f us.\n", 1.0*(end - start)/(COUNTS_PER_SECOND/1000000));
	//printf("\r\n");

	//Array copying for decryption.
	u8 keyBuffer[16];
	u8 textBuffer[tsize];
	for (int i = 0; i < 16; i++) {
		keyBuffer[i] = TxBufferPtr[i];
	}

	for (int i = 0; i < tsize; i++) {
		textBuffer[i] = RxBufferPtr[i];
	}


	test_decrypt_ecb(textBuffer, keyBuffer, tsize);
	//Decipher file management
	SD_File = (char *)CipherH;
	Res = f_open(&fil, SD_File, FA_CREATE_ALWAYS | FA_WRITE | FA_READ);
	if (Res) {
		return XST_FAILURE;
	}

	/*
	 * Pointer to beginning of file .
	 */
	Res = f_lseek(&fil, 0);
	if (Res) {
		return XST_FAILURE;
	}
	/*
	 * Write data to file.
	 */
	Res = f_write(&fil, (const void*)textBuffer, size, &NumBytesWritten);
	//Res = f_write(&fil, (const void*)RxBufferPtr, size, &NumBytesWritten);
	if (Res) {
		return XST_FAILURE;
	}

	Res = f_close(&fil);
	if (Res) {
		return XST_FAILURE;
	}
	return XST_SUCCESS;


}

static void test_encrypt_ecb_verbose(u8 plain_text[], u8 key[], int tsize)
{

    struct AES_ctx ctx;
    AES_init_ctx(&ctx, key);
    for (int i = 0; i < tsize/16; ++i)
    {
      AES_ECB_encrypt(&ctx, plain_text + (i * 16));
    }

}

static void test_decrypt_ecb(u8 cipher_text[], u8 key[], int tsize)
{

    struct AES_ctx ctx;
    AES_init_ctx(&ctx, key);
    for (int i = 0; i < tsize/16; ++i)
    {
	  AES_ECB_decrypt(&ctx, cipher_text + (i * 16));
    }


}

