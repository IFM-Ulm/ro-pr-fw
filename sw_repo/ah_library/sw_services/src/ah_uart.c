#include "xparameters.h"

#ifdef AH_UART_ACTIVATED

#include "xuartps.h"

#include "ah_scugic.h"
#include "ah_uart.h"

#define UNUSED(x) (void)(x)

static XUartPs ah_uart_intvar_instance;
static u8 ah_uart_intvar_isInit = 0;
static u8 ah_uart_intvar_isSetup = 0;
static u8 ah_uart_intvar_isEnabled = 0;

static u32 ah_uart_intvar_baudrate = 115200;

static void (*ah_uart_intvar_callbackRX)(u32, u32) = NULL;
static void (*ah_uart_intvar_callbackTX)(u32, u32) = NULL;

u8 testflag = 0;

// workarounds forward declaration
static u32 ah_uart_intfcn_wa_XUartPs_Recv(XUartPs *InstancePtr, u8 *BufferPtr, u32 NumBytes);
static u32 ah_uart_intfcn_wa_XUartPs_ReceiveBuffer(XUartPs *InstancePtr);
static void ah_uart_intfcn_wa_XUartPs_InterruptHandler(XUartPs *InstancePtr);
static void ah_uart_intfcn_wa_ReceiveDataHandler(XUartPs *InstancePtr);
static void ah_uart_intfcn_wa_SendDataHandler(XUartPs *InstancePtr, u32 IsrStatus);
static void ah_uart_intfcn_wa_ReceiveErrorHandler(XUartPs *InstancePtr, u32 IsrStatus);
static void ah_uart_intfcn_wa_ModemHandler(XUartPs *InstancePtr);
static void ah_uart_intfcn_wa_ReceiveTimeoutHandler(XUartPs *InstancePtr);
u32 ah_uart_intfcn_wa_XUartPs_SendBuffer(XUartPs *InstancePtr);
s32 ah_uart_intfcn_wa_XUartPs_SelfTest(XUartPs *InstancePtr);
u32 ah_uart_intfcn_wa_XUartPs_Send(XUartPs *InstancePtr, u8 *BufferPtr, u32 NumBytes);

void ah_uart_intfcn_callbackMain(void *CallBackRef, u32 Event, unsigned int EventData);
s32 ah_uart_intfcn_enable_connector(void* data);

s32 ah_uart_init(void){

	XUartPs_Config* XUartPs_Config_p;

	if(!ah_uart_intvar_isInit){

		if(!ah_scugic_isInit()){
			if(ah_scugic_init() != XST_SUCCESS){
				return XST_FAILURE;
			}
		}

		XUartPs_Config_p = XUartPs_LookupConfig(AH_UART_DEVICE_ID);
		if (XUartPs_Config_p == NULL) {
			return XST_FAILURE;
		}

		if(XUartPs_CfgInitialize(&ah_uart_intvar_instance, XUartPs_Config_p, XUartPs_Config_p->BaseAddress) != XST_SUCCESS){
			return XST_FAILURE;
		}

		if(XUartPs_SetBaudRate(&ah_uart_intvar_instance, ah_uart_intvar_baudrate) == XST_UART_BAUD_ERROR){
			return XST_FAILURE;
		}
		
		XUartPs_DisableUart(&ah_uart_intvar_instance);

		ah_uart_intvar_isInit = 1;
	}

	return XST_SUCCESS;
}

u8 ah_uart_isInit(void){
	return ah_uart_intvar_isInit;
}

s32 ah_uart_setup(void){

	if(!ah_uart_intvar_isInit){
		return XST_FAILURE;
	}

	if(!ah_uart_intvar_isSetup){

		if(ah_scugic_setup_connectHandler(AH_UART_INTR, (Xil_ExceptionHandler) ah_uart_intfcn_wa_XUartPs_InterruptHandler, (void *) &ah_uart_intvar_instance) != XST_SUCCESS){
			return XST_FAILURE;
		}

		if(ah_scugic_setup_enableHandler(AH_UART_INTR) != XST_SUCCESS){
			return XST_FAILURE;
		}

		XUartPs_SetHandler(&ah_uart_intvar_instance, (XUartPs_Handler)ah_uart_intfcn_callbackMain, &ah_uart_intvar_instance);

		// Enable the interrupt of the UART so interrupts will occur
		XUartPs_SetInterruptMask(&ah_uart_intvar_instance, XUARTPS_IXR_TOUT | XUARTPS_IXR_PARITY | XUARTPS_IXR_FRAMING | XUARTPS_IXR_OVER | XUARTPS_IXR_TXEMPTY | XUARTPS_IXR_RXFULL | XUARTPS_IXR_RXOVR);

		// Set the UART in Normal Mode
		XUartPs_SetOperMode(&ah_uart_intvar_instance, XUARTPS_OPER_MODE_NORMAL);

		if(ah_scugic_setup_connectEnable(AH_UART_DEVICE_ID, ah_uart_intfcn_enable_connector, NULL) != XST_SUCCESS){
			return XST_FAILURE;
		}

		if(!ah_scugic_isSetup()){
			if(ah_scugic_setup() != XST_SUCCESS){
				return XST_FAILURE;
			}
		}

		ah_uart_intvar_isSetup = 1;
	}

	return XST_SUCCESS;
}

u8 ah_uart_isSetup(void){
	return ah_uart_intvar_isSetup;
}

s32 ah_uart_setup_baudrate(u32 baudrate){
	ah_uart_intvar_baudrate = baudrate;

	return XST_SUCCESS;
}


s32 ah_uart_setup_callbackConnect_rx(void (*fcnptr)(u32 event, u32 data)){

	ah_uart_intvar_callbackRX = fcnptr;

	return XST_SUCCESS;
}

s32 ah_uart_setup_callbackConnect_tx(void (*fcnptr)(u32 event, u32 data)){

	ah_uart_intvar_callbackTX = fcnptr;

	return XST_SUCCESS;
}

s32 ah_uart_enable(void){

	if(!ah_uart_intvar_isInit){
		return XST_FAILURE;
	}

	if(!ah_uart_intvar_isSetup){
		return XST_FAILURE;
	}

	if(!ah_uart_intvar_isEnabled){

		if(ah_scugic_enable() != XST_SUCCESS){
			return XST_FAILURE;
		}
		ah_uart_intvar_isEnabled = 1;
	}

	return XST_SUCCESS;
}

u8 ah_uart_isEnabled(void){
	return ah_uart_intvar_isEnabled;
}



s32 ah_uart_send(u8* bufferPtr, u32 numBytes){

	while (XUartPs_IsSending(&ah_uart_intvar_instance));

	ah_uart_intfcn_wa_XUartPs_Send(&ah_uart_intvar_instance, bufferPtr, numBytes);

	return XST_SUCCESS;
}

s32 ah_uart_receive(u8* bufferPtr, u32 numBytes){

	if(numBytes <= (u8)XUARTPS_RXWM_MASK){
		XUartPs_SetFifoThreshold(&ah_uart_intvar_instance, numBytes);
	}
	else{
		XUartPs_SetFifoThreshold(&ah_uart_intvar_instance, (u8)XUARTPS_RXWM_MASK);
	}

	// bytesRead = XUartPs_Recv(&ah_uart_intvar_instance, receiveBuffer, numBytes);
	ah_uart_intfcn_wa_XUartPs_Recv(&ah_uart_intvar_instance, bufferPtr, numBytes);

	return XST_SUCCESS;
}

u8 ah_uart_checkReceived(void){
	return (u8) XUartPs_IsReceiveData((&ah_uart_intvar_instance)->Config.BaseAddress);
}


// functions not propagated

s32 ah_uart_intfcn_enable_connector(void* data){
	
	UNUSED(data);
	
	if(!ah_uart_intvar_isInit){
		return XST_FAILURE;
	}

	if(!ah_uart_intvar_isSetup){
		return XST_FAILURE;
	}

	if(!ah_uart_intvar_isEnabled){

		XUartPs_EnableUart(&ah_uart_intvar_instance);

		ah_uart_intvar_isEnabled = 1;
	}

	return XST_SUCCESS;

}

void ah_uart_intfcn_callbackMain(void *CallBackRef, u32 Event, unsigned int EventData){
	
	UNUSED(CallBackRef);
	
	// All of the data has been sent
	if (Event == XUARTPS_EVENT_SENT_DATA) {
		if(ah_uart_intvar_callbackTX != NULL){
			ah_uart_intvar_callbackTX(Event, (u32)EventData);
		}
	}

	// All of the data has been received
	if (Event == XUARTPS_EVENT_RECV_DATA) {
		if(ah_uart_intvar_callbackRX != NULL){
			ah_uart_intvar_callbackRX(Event, (u32)EventData);
		}
	}

	// Data was received, but not the expected number of bytes, a timeout just indicates the data stopped for ... character times
	if (Event == XUARTPS_EVENT_RECV_TOUT) {
		if(ah_uart_intvar_callbackRX != NULL){
			ah_uart_intvar_callbackRX(Event, (u32)EventData);
		}
	}

	// Data was received with an error, keep the data but determine what kind of errors occurred
	if (Event == XUARTPS_EVENT_RECV_ERROR) {
		if(ah_uart_intvar_callbackRX != NULL){
			ah_uart_intvar_callbackRX(Event, (u32)EventData);
		}
	}

}



/* The following functions have been copied from xuartps.c
	and have been modified to function correctly as the following bugs were fixed:
	- receiving one more byte than expected (https://forums.xilinx.com/t5/Embedded-Development-Tools/Bug-XUartPs-Recv-uartps-v3-1-Receiving-more-bytes-than-requested/td-p/782146)
	- not receiving an interrupt call when all bytes were received within one call in interrupted mode
*/

u32 ah_uart_intfcn_wa_XUartPs_Recv(XUartPs *InstancePtr, u8 *BufferPtr, u32 NumBytes){
	u32 ReceivedCount = 0;
	u32 ImrRegister;

	/* Assert validates the input arguments */
	Xil_AssertNonvoid(InstancePtr != NULL);
	Xil_AssertNonvoid(BufferPtr != NULL);
	Xil_AssertNonvoid(InstancePtr->IsReady == XIL_COMPONENT_IS_READY);

	/*
	 * Disable all the interrupts.
	 * This stops a previous operation that may be interrupt driven
	 */
	ImrRegister = XUartPs_ReadReg(InstancePtr->Config.BaseAddress, XUARTPS_IMR_OFFSET);
	XUartPs_WriteReg(InstancePtr->Config.BaseAddress, XUARTPS_IDR_OFFSET, XUARTPS_IXR_MASK);

	/* Setup the buffer parameters */
	InstancePtr->ReceiveBuffer.RequestedBytes = NumBytes;
	InstancePtr->ReceiveBuffer.RemainingBytes = NumBytes;
	InstancePtr->ReceiveBuffer.NextBytePtr = BufferPtr;

	/* Receive the data from the device */
	if(NumBytes > 0){
		ReceivedCount = ah_uart_intfcn_wa_XUartPs_ReceiveBuffer(InstancePtr);
	}

	/* Restore the interrupt state */
	XUartPs_WriteReg(InstancePtr->Config.BaseAddress, XUARTPS_IER_OFFSET, ImrRegister);

	return ReceivedCount;
}

u32 ah_uart_intfcn_wa_XUartPs_ReceiveBuffer(XUartPs *InstancePtr){

	u32 CsrRegister;
	u32 ReceivedCount = 0U;
	u32 ByteStatusValue, EventData;
	u32 Event;

	/*
	 * Read the Channel Status Register to determine if there is any data in
	 * the RX FIFO
	 */
	CsrRegister = XUartPs_ReadReg(InstancePtr->Config.BaseAddress, XUARTPS_SR_OFFSET);

	/*
	 * Loop until there is no more data in RX FIFO or the specified
	 * number of bytes has been received
	 */
	while((ReceivedCount < InstancePtr->ReceiveBuffer.RemainingBytes) && (((CsrRegister & XUARTPS_SR_RXEMPTY) == (u32)0))){

		if (InstancePtr->is_rxbs_error) {
			ByteStatusValue = XUartPs_ReadReg(InstancePtr->Config.BaseAddress, XUARTPS_RXBS_OFFSET);
			if((ByteStatusValue & XUARTPS_RXBS_MASK)!= (u32)0) {
				EventData = ByteStatusValue;
				Event = XUARTPS_EVENT_PARE_FRAME_BRKE;
				/*
				 * Call the application handler to indicate that there is a receive
				 * error or a break interrupt, if the application cares about the
				 * error it call a function to get the last errors.
				 */
				InstancePtr->Handler(InstancePtr->CallBackRef, Event, EventData);
			}
		}

		InstancePtr->ReceiveBuffer.NextBytePtr[ReceivedCount] =	XUartPs_ReadReg(InstancePtr->Config.BaseAddress, XUARTPS_FIFO_OFFSET);

		ReceivedCount++;

		CsrRegister = XUartPs_ReadReg(InstancePtr->Config.BaseAddress, XUARTPS_SR_OFFSET);
	}

	CsrRegister = XUartPs_ReadReg(InstancePtr->Config.BaseAddress, XUARTPS_SR_OFFSET);

	InstancePtr->is_rxbs_error = 0;
	/*
	 * Update the receive buffer to reflect the number of bytes just
	 * received
	 */
	if(InstancePtr->ReceiveBuffer.NextBytePtr != NULL){
		InstancePtr->ReceiveBuffer.NextBytePtr += ReceivedCount;
	}
	InstancePtr->ReceiveBuffer.RemainingBytes -= ReceivedCount;

	if(InstancePtr->ReceiveBuffer.RemainingBytes > 0){

		if(InstancePtr->ReceiveBuffer.RemainingBytes < (u8)XUARTPS_RXWM_MASK){
			XUartPs_SetFifoThreshold(&ah_uart_intvar_instance, InstancePtr->ReceiveBuffer.RemainingBytes);
		}
		else{
			XUartPs_SetFifoThreshold(&ah_uart_intvar_instance, (u8)XUARTPS_RXWM_MASK);
		}

		XUartPs_SetRecvTimeout(InstancePtr, (u32)XUARTPS_RXTOUT_MASK);
	}
	else{
		XUartPs_SetRecvTimeout(InstancePtr, 0);
	}

	return ReceivedCount;
}

void ah_uart_intfcn_wa_XUartPs_InterruptHandler(XUartPs *InstancePtr){
	u32 IsrStatus;

	Xil_AssertVoid(InstancePtr != NULL);
	Xil_AssertVoid(InstancePtr->IsReady == XIL_COMPONENT_IS_READY);

	/*
	 * Read the interrupt ID register to determine which
	 * interrupt is active
	 */
	IsrStatus = XUartPs_ReadReg(InstancePtr->Config.BaseAddress, XUARTPS_IMR_OFFSET);

	IsrStatus &= XUartPs_ReadReg(InstancePtr->Config.BaseAddress, XUARTPS_ISR_OFFSET);

	/* Dispatch an appropriate handler. */
	if((IsrStatus & ((u32)XUARTPS_IXR_RXOVR | (u32)XUARTPS_IXR_RXEMPTY | (u32)XUARTPS_IXR_RXFULL)) != (u32)0) {
		/* Received data interrupt */
		ah_uart_intfcn_wa_ReceiveDataHandler(InstancePtr);
	}

	if((IsrStatus & ((u32)XUARTPS_IXR_TXEMPTY | (u32)XUARTPS_IXR_TXFULL)) != (u32)0) {
		/* Transmit data interrupt */
		ah_uart_intfcn_wa_SendDataHandler(InstancePtr, IsrStatus);
	}

	/* XUARTPS_IXR_RBRK is applicable only for Zynq Ultrascale+ MP */
	if ((IsrStatus & ((u32)XUARTPS_IXR_OVER | (u32)XUARTPS_IXR_FRAMING | (u32)XUARTPS_IXR_PARITY | (u32)XUARTPS_IXR_RBRK)) != (u32)0) {
		/* Received Error Status interrupt */
		ah_uart_intfcn_wa_ReceiveErrorHandler(InstancePtr, IsrStatus);
	}

	if((IsrStatus & ((u32)XUARTPS_IXR_TOUT)) != (u32)0) {
		/* Received Timeout interrupt */
		ah_uart_intfcn_wa_ReceiveTimeoutHandler(InstancePtr);
	}

	if((IsrStatus & ((u32)XUARTPS_IXR_DMS)) != (u32)0) {
		/* Modem status interrupt */
		ah_uart_intfcn_wa_ModemHandler(InstancePtr);
	}

	/* Clear the interrupt status. */
	XUartPs_WriteReg(InstancePtr->Config.BaseAddress, XUARTPS_ISR_OFFSET, IsrStatus);

}

static void ah_uart_intfcn_wa_ReceiveDataHandler(XUartPs *InstancePtr){
	/*
	 * If there are bytes still to be received in the specified buffer
	 * go ahead and receive them. Removing bytes from the RX FIFO will
	 * clear the interrupt.
	 */
	 if (InstancePtr->ReceiveBuffer.RemainingBytes != (u32)0) {
		(void)ah_uart_intfcn_wa_XUartPs_ReceiveBuffer(InstancePtr);
	}

	 /* If the last byte of a message was received then call the application
	 * handler, this code should not use an else from the previous check of
	 * the number of bytes to receive because the call to receive the buffer
	 * updates the bytes ramained
	 */
	//if (InstancePtr->ReceiveBuffer.RemainingBytes == (u32)0) {
	if (InstancePtr->ReceiveBuffer.RemainingBytes == (u32)0 && InstancePtr->ReceiveBuffer.RequestedBytes > (u32)0) { // modified for correction
		InstancePtr->Handler(InstancePtr->CallBackRef, XUARTPS_EVENT_RECV_DATA, (InstancePtr->ReceiveBuffer.RequestedBytes - InstancePtr->ReceiveBuffer.RemainingBytes));
	}
	else if(InstancePtr->ReceiveBuffer.RemainingBytes > 0){
		testflag = 1;
	}

}



// additions needed

static void ah_uart_intfcn_wa_ReceiveTimeoutHandler(XUartPs *InstancePtr){
	u32 Event;

	/*
	 * If there are bytes still to be received in the specified buffer
	 * go ahead and receive them. Removing bytes from the RX FIFO will
	 * clear the interrupt.
	 */
	if (InstancePtr->ReceiveBuffer.RemainingBytes != (u32)0) {
		(void)ah_uart_intfcn_wa_XUartPs_ReceiveBuffer(InstancePtr);
	}

	/*
	 * If there are no more bytes to receive then indicate that this is
	 * not a receive timeout but the end of the buffer reached, a timeout
	 * normally occurs if # of bytes is not divisible by FIFO threshold,
	 * don't rely on previous test of remaining bytes since receive
	 * function updates it
	 */
	if (InstancePtr->ReceiveBuffer.RemainingBytes != (u32)0) {
		Event = XUARTPS_EVENT_RECV_TOUT;
	} else {
		Event = XUARTPS_EVENT_RECV_DATA;
	}

	/*
	 * Call the application handler to indicate that there is a receive
	 * timeout or data event
	 */
	InstancePtr->Handler(InstancePtr->CallBackRef, Event, InstancePtr->ReceiveBuffer.RequestedBytes - InstancePtr->ReceiveBuffer.RemainingBytes);

}


static void ah_uart_intfcn_wa_ModemHandler(XUartPs *InstancePtr){
	u32 MsrRegister;

	/*
	 * Read the modem status register so that the interrupt is acknowledged
	 * and it can be passed to the callback handler with the event
	 */
	MsrRegister = XUartPs_ReadReg(InstancePtr->Config.BaseAddress, XUARTPS_MODEMSR_OFFSET);

	/*
	 * Call the application handler to indicate the modem status changed,
	 * passing the modem status and the event data in the call
	 */
	InstancePtr->Handler(InstancePtr->CallBackRef, XUARTPS_EVENT_MODEM, MsrRegister);

}


static void ah_uart_intfcn_wa_ReceiveErrorHandler(XUartPs *InstancePtr, u32 IsrStatus){
	u32 EventData;
	u32 Event;

	InstancePtr->is_rxbs_error = 0;

	if ((InstancePtr->Platform == XPLAT_ZYNQ_ULTRA_MP) && (IsrStatus & ((u32)XUARTPS_IXR_PARITY | (u32)XUARTPS_IXR_RBRK	| (u32)XUARTPS_IXR_FRAMING))) {
		InstancePtr->is_rxbs_error = 1;
	}
	/*
	 * If there are bytes still to be received in the specified buffer
	 * go ahead and receive them. Removing bytes from the RX FIFO will
	 * clear the interrupt.
	 */

	(void)ah_uart_intfcn_wa_XUartPs_ReceiveBuffer(InstancePtr);

	if (!(InstancePtr->is_rxbs_error)) {
		Event = XUARTPS_EVENT_RECV_ERROR;
		EventData = InstancePtr->ReceiveBuffer.RequestedBytes -	InstancePtr->ReceiveBuffer.RemainingBytes;

		/*
		 * Call the application handler to indicate that there is a receive
		 * error or a break interrupt, if the application cares about the
		 * error it call a function to get the last errors.
		 */
		InstancePtr->Handler(InstancePtr->CallBackRef, Event, EventData);
	}
}

static void ah_uart_intfcn_wa_SendDataHandler(XUartPs *InstancePtr, u32 IsrStatus){

	/*
	 * If there are not bytes to be sent from the specified buffer then disable
	 * the transmit interrupt so it will stop interrupting as it interrupts
	 * any time the FIFO is empty
	 */
	if (InstancePtr->SendBuffer.RemainingBytes == (u32)0) {
		XUartPs_WriteReg(InstancePtr->Config.BaseAddress, XUARTPS_IDR_OFFSET, ((u32)XUARTPS_IXR_TXEMPTY | (u32)XUARTPS_IXR_TXFULL));

		/* Call the application handler to indicate the sending is done */
		InstancePtr->Handler(InstancePtr->CallBackRef, XUARTPS_EVENT_SENT_DATA,	InstancePtr->SendBuffer.RequestedBytes - InstancePtr->SendBuffer.RemainingBytes);
	}

	/* If TX FIFO is empty, send more. */
	else if((IsrStatus & ((u32)XUARTPS_IXR_TXEMPTY)) != (u32)0) {
		(void)ah_uart_intfcn_wa_XUartPs_SendBuffer(InstancePtr);
	}
	else {
		/* Else with dummy entry for MISRA-C Compliance.*/
		;
	}
}

u32 ah_uart_intfcn_wa_XUartPs_SendBuffer(XUartPs *InstancePtr){
	u32 SentCount = 0U;
	u32 ImrRegister;

	/*
	 * If the TX FIFO is full, send nothing.
	 * Otherwise put bytes into the TX FIFO unil it is full, or all of the
	 * data has been put into the FIFO.
	 */
	while ((!XUartPs_IsTransmitFull(InstancePtr->Config.BaseAddress)) &&  (InstancePtr->SendBuffer.RemainingBytes > SentCount)) {

		/* Fill the FIFO from the buffer */
		XUartPs_WriteReg(InstancePtr->Config.BaseAddress, XUARTPS_FIFO_OFFSET, ((u32)InstancePtr->SendBuffer.NextBytePtr[SentCount]));

		/* Increment the send count. */
		SentCount++;
	}

	/* Update the buffer to reflect the bytes that were sent from it */
	InstancePtr->SendBuffer.NextBytePtr += SentCount;
	InstancePtr->SendBuffer.RemainingBytes -= SentCount;

	/*
	 * If interrupts are enabled as indicated by the receive interrupt, then
	 * enable the TX FIFO empty interrupt, so further action can be taken
	 * for this sending.
	 */
	ImrRegister = XUartPs_ReadReg(InstancePtr->Config.BaseAddress, XUARTPS_IMR_OFFSET);
	if (((ImrRegister & XUARTPS_IXR_RXFULL) != (u32)0) || ((ImrRegister & XUARTPS_IXR_RXEMPTY) != (u32)0)|| ((ImrRegister & XUARTPS_IXR_RXOVR) != (u32)0)) {
		XUartPs_WriteReg(InstancePtr->Config.BaseAddress, XUARTPS_IER_OFFSET, ImrRegister | (u32)XUARTPS_IXR_TXEMPTY);
	}

	return SentCount;
}

s32 ah_uart_intfcn_wa_XUartPs_SelfTest(XUartPs *InstancePtr)
{
	s32 Status = XST_SUCCESS;
	u32 IntrRegister;
	u32 ModeRegister;
	u8 Index;
	u32 ReceiveDataResult;

	u8 TestString[32]="abcdefghABCDEFGH012345677654321";
	u8 ReturnString[32];

	/* Assert validates the input arguments */
	Xil_AssertNonvoid(InstancePtr != NULL);
	Xil_AssertNonvoid(InstancePtr->IsReady == XIL_COMPONENT_IS_READY);

	/* Disable all interrupts in the interrupt disable register */
	IntrRegister = XUartPs_ReadReg(InstancePtr->Config.BaseAddress, XUARTPS_IMR_OFFSET);
	XUartPs_WriteReg(InstancePtr->Config.BaseAddress, XUARTPS_IDR_OFFSET, XUARTPS_IXR_MASK);

	/* Setup for local loopback */
	ModeRegister = XUartPs_ReadReg(InstancePtr->Config.BaseAddress, XUARTPS_MR_OFFSET);
	XUartPs_WriteReg(InstancePtr->Config.BaseAddress, XUARTPS_MR_OFFSET, ((ModeRegister & (u32)(~XUARTPS_MR_CHMODE_MASK)) | (u32)XUARTPS_MR_CHMODE_L_LOOP));

	/* Send a number of bytes and receive them, one at a time. */
	for (Index = 0U; Index < 32; Index++) {
		/*
		 * Send out the byte and if it was not sent then the failure
		 * will be caught in the comparison at the end
		 */
		//(void)XUartPs_Send(InstancePtr, &TestString[Index], 1U);
		(void)ah_uart_intfcn_wa_XUartPs_Send(InstancePtr, &TestString[Index], 1U);


		/*
		 * Wait until the byte is received. This can hang if the HW
		 * is broken. Watch for the FIFO empty flag to be false.
		 */
		ReceiveDataResult = Xil_In32((InstancePtr->Config.BaseAddress) + XUARTPS_SR_OFFSET) & XUARTPS_SR_RXEMPTY;
		while (ReceiveDataResult == XUARTPS_SR_RXEMPTY ) {
			ReceiveDataResult = Xil_In32((InstancePtr->Config.BaseAddress) + XUARTPS_SR_OFFSET) & XUARTPS_SR_RXEMPTY;
		}

		/* Receive the byte */
		(void)ah_uart_intfcn_wa_XUartPs_Recv(InstancePtr, &ReturnString[Index], 1U);
	}

	/*
	 * Compare the bytes received to the bytes sent to verify the exact data
	 * was received
	 */
	for (Index = 0U; Index < 32; Index++) {
		if (TestString[Index] != ReturnString[Index]) {
			Status = XST_UART_TEST_FAIL;
		}
	}

	/*
	 * Restore the registers which were altered to put into polling and
	 * loopback modes so that this test is not destructive
	 */
	XUartPs_WriteReg(InstancePtr->Config.BaseAddress, XUARTPS_IER_OFFSET,
			   IntrRegister);
	XUartPs_WriteReg(InstancePtr->Config.BaseAddress, XUARTPS_MR_OFFSET,
			   ModeRegister);

	return Status;
}

u32 ah_uart_intfcn_wa_XUartPs_Send(XUartPs *InstancePtr, u8 *BufferPtr, u32 NumBytes){
	u32 BytesSent;

	/* Asserts validate the input arguments */
	Xil_AssertNonvoid(InstancePtr != NULL);
	Xil_AssertNonvoid(BufferPtr != NULL);
	Xil_AssertNonvoid(InstancePtr->IsReady == XIL_COMPONENT_IS_READY);

	/*
	 * Disable the UART transmit interrupts to allow this call to stop a
	 * previous operation that may be interrupt driven.
	 */
	XUartPs_WriteReg(InstancePtr->Config.BaseAddress, XUARTPS_IDR_OFFSET, (XUARTPS_IXR_TXEMPTY | XUARTPS_IXR_TXFULL));

	/* Setup the buffer parameters */
	InstancePtr->SendBuffer.RequestedBytes = NumBytes;
	InstancePtr->SendBuffer.RemainingBytes = NumBytes;
	InstancePtr->SendBuffer.NextBytePtr = BufferPtr;

	/*
	 * Transmit interrupts will be enabled in XUartPs_SendBuffer(), after
	 * filling the TX FIFO.
	 */
	BytesSent = ah_uart_intfcn_wa_XUartPs_SendBuffer(InstancePtr);

	return BytesSent;
}

#endif