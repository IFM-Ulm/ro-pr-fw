#include "xparameters.h"

#ifdef AH_TCPIP_ACTIVATED

#include "xparameters_ps.h"
#include "netif/xadapter.h"

#include "ah_scugic.h"
#include "ah_timer.h"
#include "ah_tcpip.h"


#ifndef USE_SOFTETH_ON_ZYNQ
#define RESET_RX_CNTR_LIMIT	400
static int ResetRxCntr = 0;
#endif

#define UNUSED(x) (void)(x)

// private variables

static u8 ah_tcpip_intvar_isInit = 0;
static u8 ah_tcpip_intvar_isSetup = 0;
static u8 ah_tcpip_intvar_isEnabled = 0;

/* from https://lists.gnu.org/archive/html/lwip-users/2006-03/msg00032.html
	1. Create a listening pcb, server_pcb in this example, with tcp_new()
	2. Bind it to a local port
	3. Listen to the pcb with tcp_listen(). Assign the return value of 
	tcp_listen() to a new descriptor, say conn_pcb.
	*** At this point you have two allocated pcbs. The listening pcb server_pcb 
	and the newly opened connection conn_pcb. ***
	4. Accept the new connection (conn_pcb) with tcp_accept().
	5. Do stuff with the conn_pcb connection.
	6. Close conn_pcb with tcp_close()
	7. Repeat from step 3.
*/

static struct netif ah_tcpip_intvar_netif;
static struct tcp_pcb *ah_tcpip_intvar_pcb_server = NULL;
static struct tcp_pcb *ah_tcpip_intvar_pcb_connection = NULL;
static u8 ah_tcpip_intvar_server_alive = 0;
static u8 ah_tcpip_intvar_connection_alive = 0;

static unsigned char ah_tcpip_intvar_mac[6];
static struct ip4_addr ah_tcpip_intvar_ip;
static struct ip4_addr ah_tcpip_intvar_netmask;
static struct ip4_addr ah_tcpip_intvar_gateway;
static u8 ah_tcpip_intvar_port;

static u8 ah_tcpip_intvar_isset_mac = 0;
static u8 ah_tcpip_intvar_isset_ip = 0;
static u8 ah_tcpip_intvar_isset_netmask = 0;
static u8 ah_tcpip_intvar_isset_gateway = 0;
static u8 ah_tcpip_intvar_isset_port = 0;

static u16 ah_tcpip_intvar_numberconnection = 1;

static u32 ah_tcpip_intvar_timer_interval = 1;
static u32 ah_tcpip_intvar_callbackid_timer = 0;
static u32 ah_tcpip_intvar_callbackid_packet = 0;

static u8 ah_tcpip_intvar_packet_flag = 0;
static u8 ah_tcpip_intvar_packet_usecallback = 0;
static u8 ah_tcpip_intvar_packet_usecallback_unsafe = 0;

static u32 ah_tcpip_intvar_data_unacked = 0;
static u32 ah_tcpip_intvar_max_unacked = 0;
static u32 ah_tcpip_intvar_accept_data = 0;

static u8 ah_tcpip_intvar_flag_copy = 1;
static u8 ah_tcpip_intvar_flag_more = 0;
static u8 ah_tcpip_intvar_flag_total = TCP_WRITE_FLAG_COPY;


void (*ah_tcpip_intfcn_accepted)(u16) = NULL;
void (*ah_tcpip_intfcn_received)(u16, struct pbuf*, void*, u16_t) = NULL;
void (*ah_tcpip_intfcn_sent)(u16, u16) = NULL;
void (*ah_tcpip_intfcn_error)(u16, u8) = NULL;
void (*ah_tcpip_intfcn_closed)(u16) = NULL;
void (*ah_tcpip_intfcn_poll)(u16) = NULL;

// forward declaration of private functions

void lwip_init();
void tcp_tmr(void);

s32 ah_tcpip_intfcn_enable_connector(void* data);
void ah_tcpip_intfcn_callback_timer(void* instance);
void ah_tcpip_intfcn_callback_packet(void* instance);
err_t ah_tcpip_intfcn_callback_accept(void *arg, struct tcp_pcb *newpcb, err_t err);

// public functions

s32 ah_tcpip_init(void){

	if(!ah_tcpip_intvar_isInit){

		if(!ah_timer_isInit()){
			if(ah_timer_init() != XST_SUCCESS){
				return XST_FAILURE;
			}
		}

		lwip_init();

		ah_tcpip_intvar_connection_alive = 0;
		ah_tcpip_intvar_pcb_server = NULL;
		ah_tcpip_intvar_pcb_connection = NULL;
		
		ah_tcpip_intvar_isInit = 1;
	}

	return XST_SUCCESS;
}

u8 ah_tcipip_isInit(void){
	return ah_tcpip_intvar_isInit;
}

s32 ah_tcpip_setup(void){

	if(!ah_tcpip_intvar_isInit){
		return XST_FAILURE;
	}

	if(!ah_tcpip_intvar_isSetup){

		if(ah_tcpip_intvar_isset_mac == 0 || ah_tcpip_intvar_isset_ip == 0 || ah_tcpip_intvar_isset_netmask == 0 || ah_tcpip_intvar_isset_gateway == 0){
			return XST_FAILURE;
		}

		if (!xemac_add(&ah_tcpip_intvar_netif, &ah_tcpip_intvar_ip, &ah_tcpip_intvar_netmask, &ah_tcpip_intvar_gateway, ah_tcpip_intvar_mac, XPAR_XEMACPS_0_BASEADDR)){
			return XST_FAILURE;
		}

		netif_set_default(&ah_tcpip_intvar_netif);

		if(ah_timer_setup_reloadEnable() != XST_SUCCESS){
			return XST_FAILURE;
		}

		if(ah_timer_setup_callbackConnect(ah_tcpip_intfcn_callback_timer, NULL, 250, AH_TIMER_TIMEBASE_1MS, 0, &ah_tcpip_intvar_callbackid_timer) != XST_SUCCESS){
			return XST_FAILURE;
		}

		if(ah_tcpip_intvar_packet_usecallback){
			if(ah_timer_setup_callbackConnect(ah_tcpip_intfcn_callback_packet, NULL, ah_tcpip_intvar_timer_interval, AH_TIMER_TIMEBASE_1MS, 0, &ah_tcpip_intvar_callbackid_packet) != XST_SUCCESS){
				return XST_FAILURE;
			}
		}

		if(!ah_timer_isSetup()){
			if(ah_timer_setup() != XST_SUCCESS){
				return XST_FAILURE;
			}
		}

		if(ah_scugic_setup_connectEnable(XPAR_XEMACPS_0_BASEADDR, ah_tcpip_intfcn_enable_connector, NULL) != XST_SUCCESS){
			return XST_FAILURE;
		}

		ah_tcpip_intvar_isSetup = 1;
	}

	return XST_SUCCESS;
}

u8 ah_tcpip_isSetup(void){
	return ah_tcpip_intvar_isSetup;
}

s32 ah_tcpip_setup_mac(u8 octet_1, u8 octet_2, u8 octet_3, u8 octet_4, u8 octet_5, u8 octet_6){

#ifdef AH_TCPIP_MAC_I2C
#error functionality not implemented, see comments
/*
	from https://reference.digilentinc.com/reference/programmable-logic/zybo/reference-manual :
	On an Ethernet network each node needs a unique MAC address. To this end, a Microchip 24AA02E48 EEPROM is provided on the ZYBO. 
	On one hand it is a read-writeable EEPROM that can be accessed via I2C. 
	On the other hand it features a read-only memory section that comes pre-programmed with a unique identifier. 
	This unique identifier can be read and used as a MAC address, avoiding a possible address conflict on the network. 
	The I2C interface connects to the PL side and can be accessed from the PS over EMIO as well. The device address of the EEPROM is 1010000b.
	
	from https://forum.digilentinc.com/topic/3113-how-to-obtain-the-mac-address-of-zybo/#comment-11181 :
	
	#include "xiicps.h"
		
	int Status;
	XIicPs Iic;
	XIicPs_Config *Iic_Config;
	s32 result = 0;

	unsigned char mac_addr[6];
	int i = 0;

	Iic_Config = XIicPs_LookupConfig(XPAR_PS7_I2C_0_DEVICE_ID);
	if(Iic_Config == NULL) {
		return XST_FAILURE;
	}

	Status = XIicPs_CfgInitialize(&Iic, Iic_Config, Iic_Config->BaseAddress);
	if(Status != XST_SUCCESS) {
		return XST_FAILURE;
	}

	result = XIicPs_SetSClk(&Iic, 200000);

	u32 ControlReg = XIicPs_ReadReg((&Iic)->Config.BaseAddress, (u32)XIICPS_CR_OFFSET);

	mac_addr[0] = 0xFA;

	result = XIicPs_MasterSendPolled(&Iic, mac_addr, 1, 0x50);
	result = XIicPs_BusIsBusy(&Iic);
	while(result){
		result = XIicPs_BusIsBusy(&Iic);
	}

	result = XIicPs_MasterRecvPolled(&Iic, mac_addr, 6, 0x50);
	result = XIicPs_BusIsBusy(&Iic);
	while(result){
		result = XIicPs_BusIsBusy(&Iic);
	}
	

*/
#else
	ah_tcpip_intvar_mac[0] = (char)octet_1;
	ah_tcpip_intvar_mac[1] = (char)octet_2;
	ah_tcpip_intvar_mac[2] = (char)octet_3;
	ah_tcpip_intvar_mac[3] = (char)octet_4;
	ah_tcpip_intvar_mac[4] = (char)octet_5;
	ah_tcpip_intvar_mac[5] = (char)octet_6;
#endif
	
	
	ah_tcpip_intvar_isset_mac = 1;

	return XST_SUCCESS;
}

s32 ah_tcpip_setup_ip(u8 octet_1, u8 octet_2, u8 octet_3, u8 octet_4){

	IP4_ADDR(&ah_tcpip_intvar_ip,  octet_1, octet_2,   octet_3, octet_4);
	ah_tcpip_intvar_isset_ip = 1;

	return XST_SUCCESS;
}

s32 ah_tcpip_setup_netmask(u8 octet_1, u8 octet_2, u8 octet_3, u8 octet_4){

	IP4_ADDR(&ah_tcpip_intvar_netmask,  octet_1, octet_2,   octet_3, octet_4);
	ah_tcpip_intvar_isset_netmask = 1;

	return XST_SUCCESS;
}

s32 ah_tcpip_setup_gateway(u8 octet_1, u8 octet_2, u8 octet_3, u8 octet_4){

	IP4_ADDR(&ah_tcpip_intvar_gateway,  octet_1, octet_2,   octet_3, octet_4);
	ah_tcpip_intvar_isset_gateway = 1;

	return XST_SUCCESS;
}

s32 ah_tcpip_setup_port(u8 port){

	ah_tcpip_intvar_port = port;
	ah_tcpip_intvar_isset_port = 1;

	return XST_SUCCESS;
}

s32 ah_tcpip_setup_timerIntervalMS(u32 interval){
	if(interval > 0){
		ah_tcpip_intvar_timer_interval = interval;
		return XST_SUCCESS;
	}
	else{
		return XST_FAILURE;
	}
}

s32 ah_tcpip_setup_pollingmode(u8 mode){

	if(ah_tcpip_intvar_isInit == 0 || ah_tcpip_intvar_isEnabled == 1){
		return XST_FAILURE;
	}

	if(mode == 0){ // no callback, user has to call the poll function in the main loop, executes on each call
		ah_tcpip_intvar_packet_usecallback = 0;
		ah_tcpip_intvar_packet_usecallback_unsafe = 0;
	}
	else if(mode == 1){ // callback periodically called (period = ah_tcpip_intvar_timer_interval * 1ms), user has to call the poll function in the main loop, but it will only execute when flagged
		ah_tcpip_intvar_packet_usecallback = 1;
		ah_tcpip_intvar_packet_usecallback_unsafe = 0;
	}
	else if(mode == 2){ // callback periodically called (ah_tcpip_intvar_timer_interval * 1ms), user has to register their own callback function

		if(ah_tcpip_intfcn_poll == NULL){
			return XST_FAILURE;
		}

		ah_tcpip_intvar_packet_usecallback = 2;
		ah_tcpip_intvar_packet_usecallback_unsafe = 1;
	}
	else if(mode == 3){ // callback periodically called (ah_tcpip_intvar_timer_interval * 1ms), no further user action needed, automatic (but unsafe) polling
		ah_tcpip_intvar_packet_usecallback = 1;
		ah_tcpip_intvar_packet_usecallback_unsafe = 1;
	}
	else{
		return XST_FAILURE;
	}

	return XST_SUCCESS;
}

// if this function is called with a value > 0, the function ah_tcpip_checkBuffer
// will also take unacked data into account, possibly preventing memory errors
s32 ah_tcpip_setup_max_send_size(u32 valBytes){
	
	ah_tcpip_intvar_max_unacked = valBytes;

	return XST_SUCCESS;
}

s32 ah_tcpip_setup_callbackAccepted(void (*fcnptr)(u16)){

	ah_tcpip_intfcn_accepted = fcnptr;

	return XST_SUCCESS;
}

s32 ah_tcpip_setup_callbackReceived(void (*fcnptr)(u16, struct pbuf*, void*, u16)){

	ah_tcpip_intfcn_received = fcnptr;

	return XST_SUCCESS;
}

// provides the amount of bytes acknowledged
s32 ah_tcpip_setup_callbackSent(void (*fcnptr)(u16, u16)){

	ah_tcpip_intfcn_sent = fcnptr;

	return XST_SUCCESS;
}

s32 ah_tcpip_setup_callbackError(void (*fcnptr)(u16, u8)){

	ah_tcpip_intfcn_error = fcnptr;

	return XST_SUCCESS;
}

s32 ah_tcpip_setup_callbackClosed(void (*fcnptr)(u16)){

	ah_tcpip_intfcn_closed = fcnptr;

	return XST_SUCCESS;
}

s32 ah_tcpip_setup_callbackPoll(void (*fcnptr)(u16)){

	ah_tcpip_intfcn_poll = fcnptr;

	return XST_SUCCESS;
}

s32 ah_tcpip_enable(void){

	if(!ah_tcpip_intvar_isInit){
		return XST_FAILURE;
	}

	if(!ah_tcpip_intvar_isSetup){
		return XST_FAILURE;
	}

	if(!ah_tcpip_intvar_isEnabled){
		if(ah_timer_enable() != XST_SUCCESS){
			return XST_FAILURE;
		}
		ah_tcpip_intvar_isEnabled = 1;
	}

	return XST_SUCCESS;
}

u8 ah_tcpip_isEnabled(void){
	return ah_tcpip_intvar_isEnabled;
}

s32 ah_tcpip_open(void){

	struct tcp_pcb *pcb;
	err_t err;

	if(ah_tcpip_intvar_pcb_server != NULL){
		return XST_FAILURE;
	}

	if(!ah_tcpip_intvar_isEnabled || !ah_tcpip_intvar_isset_port){
		return XST_FAILURE;
	}
	
	// create new TCP PCB structure
	pcb = tcp_new();
	if (!pcb) {
		return XST_FAILURE;
	}

	// bind to specified @port
	err = tcp_bind(pcb, IP_ADDR_ANY, (u16_t)ah_tcpip_intvar_port);
	if (err != ERR_OK) {
		return XST_FAILURE;
	}

	// we do not need any arguments to callback functions
	tcp_arg(pcb, NULL);

	// listen for connections
	pcb = tcp_listen(pcb);
	if (!pcb) {
		return XST_FAILURE;
	}

	// specify callback to use for incoming connections
	tcp_accept(pcb, ah_tcpip_intfcn_callback_accept);

	ah_tcpip_intvar_pcb_server = pcb;
	
	return XST_SUCCESS;
}

s32 ah_tcpip_close(u8 listen_server){

	ah_tcpip_intvar_connection_alive = 0;

	ah_tcpip_intvar_data_unacked = 0;
	
	// remove callback functions
	tcp_sent(ah_tcpip_intvar_pcb_connection, NULL);
	tcp_recv(ah_tcpip_intvar_pcb_connection, NULL);
	tcp_err(ah_tcpip_intvar_pcb_connection, NULL);

	if(tcp_close(ah_tcpip_intvar_pcb_connection) != ERR_OK){
		return XST_FAILURE;
	}
	
	if(ah_tcpip_intfcn_closed != NULL){
		ah_tcpip_intfcn_closed(*(((u16*)ah_tcpip_intvar_pcb_server->callback_arg)));
	}
	
	ah_tcpip_intvar_pcb_connection = NULL;
	
	if(listen_server){
		
		ah_tcpip_intvar_server_alive = 0;
		
		tcp_accept(ah_tcpip_intvar_pcb_server, NULL);
		
		if(tcp_close(ah_tcpip_intvar_pcb_server) != ERR_OK){
			return XST_FAILURE;
		}
		
		ah_tcpip_intvar_pcb_server = NULL;
	}
	
	return XST_SUCCESS;
}


s32 ah_tcpip_pull(u8* retVal){
	
	u8 packets_received = 0;
	
	if(ah_tcpip_intvar_packet_usecallback == 1){
		if(!ah_tcpip_intvar_packet_usecallback_unsafe){
			if(ah_tcpip_intvar_packet_flag){
				packets_received = (u8)xemacif_input(&ah_tcpip_intvar_netif);
				ah_tcpip_intvar_packet_flag = 0;
			}
		}
	}
	else{
		packets_received = (u8)xemacif_input(&ah_tcpip_intvar_netif);
	}

	if(retVal != NULL){
		*retVal = packets_received;
	}
	
	return XST_SUCCESS;
}

u8 ah_tcpip_checkBuffer(u16 len){

	u16 sndbuf_val;
	u16 sndwnd_val;

	// ToDo: should be "return XST_FAILURE;", rewrite function
	if(!ah_tcpip_intvar_connection_alive){
		return 0;
	}

	sndbuf_val = (u16)tcp_sndbuf(ah_tcpip_intvar_pcb_connection);
	if(len < sndbuf_val){
		
		sndwnd_val = ah_tcpip_intvar_pcb_connection->snd_wnd;
		// workaround: do not try to stuff packets in the send queue, if the receivers window is closing (windows size < 3 * IP MSS)
		if(sndwnd_val < 4338){
			return 0;
		}
		else{
			
			if(ah_tcpip_intvar_max_unacked > 0){
				
				if(((u32)len + ah_tcpip_intvar_data_unacked) <= ah_tcpip_intvar_max_unacked){
					
					return 1;
				}
				else{
					return 0;
				}
			}
			else{
				return 1;
			}
		}
	}
	else{
		return 0;
	}
}

u8 ah_tcpip_checkConnection(void){
	return ah_tcpip_intvar_connection_alive;
}

s32 ah_tcip_setflag_copy(u8 flag){
	
	if(flag){
		ah_tcpip_intvar_flag_copy = 1;
	}
	else{
		ah_tcpip_intvar_flag_copy = 0;
	}
	
	ah_tcpip_intvar_flag_total = 0;
	
	if(ah_tcpip_intvar_flag_copy){
		ah_tcpip_intvar_flag_total = TCP_WRITE_FLAG_COPY;
	}
	
	if(ah_tcpip_intvar_flag_more){
		ah_tcpip_intvar_flag_total |= TCP_WRITE_FLAG_MORE;
	}
	
	return XST_SUCCESS;
}

s32 ah_tcip_setflag_more(u8 flag){
	
	if(flag){
		ah_tcpip_intvar_flag_copy = 1;
	}
	else{
		ah_tcpip_intvar_flag_copy = 0;
	}
	
	ah_tcpip_intvar_flag_total = 0;
	
	if(ah_tcpip_intvar_flag_copy){
		ah_tcpip_intvar_flag_total = TCP_WRITE_FLAG_COPY;
	}
	
	if(ah_tcpip_intvar_flag_more){
		ah_tcpip_intvar_flag_total |= TCP_WRITE_FLAG_MORE;
	}
	
	return XST_SUCCESS;
}

s32 ah_tcpip_send(const void *data, u16 len, u8 force_send){

	err_t result;

	if(ah_tcpip_intvar_connection_alive == 0){
		return XST_FAILURE;
	}

	result = tcp_write(ah_tcpip_intvar_pcb_connection, data, (u16_t) len, ah_tcpip_intvar_flag_total);
	
	// testing, trying to prevent out_of_memory crashes
	if(result == ERR_MEM){
		result = tcp_output(ah_tcpip_intvar_pcb_connection);
		if(result != ERR_OK){
			return XST_FAILURE;
		}
		result = tcp_write(ah_tcpip_intvar_pcb_connection, data, (u16_t) len, ah_tcpip_intvar_flag_total);
	}
	
	if(result != ERR_OK){
		return XST_FAILURE;
	}
	
	ah_tcpip_intvar_data_unacked += (u32)len;
	
	if(force_send == 1){
		result = tcp_output(ah_tcpip_intvar_pcb_connection);
		if(result != ERR_OK){
			return XST_FAILURE;
		}
	}	

	return XST_SUCCESS;
}

s32 ah_tcpip_send_blocking(const void *data, u16 len, u8 force_send){

	err_t result;

	if(ah_tcpip_intvar_connection_alive == 0){
		return XST_FAILURE;
	}

	// ToDo: include useage of TCP_WRITE_FLAG_MORE ? prevents setting PSH flag to indicate that more data is on its way
	result = tcp_write(ah_tcpip_intvar_pcb_connection, data, (u16_t) len, ah_tcpip_intvar_flag_total);
	
	// testing, trying to prevent out_of_memory crashes
	while(result != ERR_OK){
		result = tcp_output(ah_tcpip_intvar_pcb_connection);
		if(result == ERR_OK){
			result = tcp_write(ah_tcpip_intvar_pcb_connection, data, (u16_t) len, ah_tcpip_intvar_flag_total);
		}
	}
	
	ah_tcpip_intvar_data_unacked += (u32)len;
	
	if(force_send == 1){
		result = tcp_output(ah_tcpip_intvar_pcb_connection);
		if(result != ERR_OK){
			return XST_FAILURE;
		}
	}	

	return XST_SUCCESS;
}

s32 ah_tcpip_send_output(void){
	
	err_t result;
	
	u8 received = 1;
	u8 received_counter = 0;
	
	result = tcp_output(ah_tcpip_intvar_pcb_connection);
	if(result != ERR_OK){
		return XST_FAILURE;
	}
	
	if(ah_tcpip_intvar_packet_usecallback == 0 || (ah_tcpip_intvar_packet_usecallback == 1 && ah_tcpip_intvar_packet_usecallback_unsafe == 0)){
		while(received > 0){
			if(ah_tcpip_pull(&received) != XST_SUCCESS){
				return XST_FAILURE;
			}
			received_counter += received;
			if(received_counter >= 64){
				break;
			}
		}
	}
	
	return XST_SUCCESS;
}

s32 ah_tcpip_refuse_data(void){
	ah_tcpip_intvar_accept_data = 0;
	return XST_SUCCESS;
}

s32 ah_tcpip_accept_data(void){
	ah_tcpip_intvar_accept_data = 1;
	return XST_SUCCESS;
}

u8 ah_tcpip_status_data(void){
	return ah_tcpip_intvar_accept_data;
}

/*
s32 ah_tcpip_setPriority(u8 priority){

	// method intentionally errorness, todo: switch to "register enable" and enable all at once
	// setPriority for each library, this one has to pass it to the timers priority
	// rework uart library as "ah_uart"
	// there was one part with polling 1 byte and then proceeding, can this be changed to a timer based whatever?

	if(ah_tcpip_intvar_isInit == 0){

		if(!ah_xscutimer_getInitialized()){

		}
	}

	return ah_xscugic_interrupts_setPriority(u32 XPS_INT_ID, priority)

}
*/


// functions not propagated

void ah_tcpip_intfcn_callback_packet(void* instance){

	UNUSED(instance);

	if(ah_tcpip_intvar_packet_usecallback == 1){
		if(!ah_tcpip_intvar_packet_usecallback_unsafe){
			ah_tcpip_intvar_packet_flag = 1;
		}
		else{
			// ToDo: do we need to stop receiving packets, when we want to throttle?
			//if(ah_tcpip_intvar_accept_data)xemacif_input(&ah_tcpip_intvar_netif);
			xemacif_input(&ah_tcpip_intvar_netif);
		}
	}
	else if(ah_tcpip_intvar_packet_usecallback == 2){
		ah_tcpip_intfcn_poll(ah_tcpip_intvar_numberconnection);
	}

}

void ah_tcpip_intfcn_callback_timer(void* instance){
	
	UNUSED(instance);
	
	// probably outdated, see https://lwip.fandom.com/wiki/LwIP_with_or_without_an_operating_system
	tcp_tmr();

	// possible inclusion of the following checks of the ah_tcpip_intvar_numberconnection but they always return true
	// netif_is_link_up(&ah_tcpip_intvar_netif)
	// netif_is_up(&ah_tcpip_intvar_netif)

#ifndef USE_SOFTETH_ON_ZYNQ
	ResetRxCntr++;
#endif

#ifndef USE_SOFTETH_ON_ZYNQ
	if (ResetRxCntr >= RESET_RX_CNTR_LIMIT) {
		xemacpsif_resetrx_on_no_rxdata(&ah_tcpip_intvar_netif);
		ResetRxCntr = 0;
	}
#endif

}

s32 ah_tcpip_intfcn_enable_connector(void* data){
	
	UNUSED(data);
	
	if(!ah_tcpip_intvar_isInit){
		return XST_FAILURE;
	}

	if(!ah_tcpip_intvar_isSetup){
		return XST_FAILURE;
	}

	if(!ah_tcpip_intvar_isEnabled){

		if(ah_timer_setup_callbackEnable(ah_tcpip_intvar_callbackid_timer) != XST_SUCCESS){
			return XST_FAILURE;
		}

		if(ah_tcpip_intvar_packet_usecallback){
			if(ah_timer_setup_callbackEnable(ah_tcpip_intvar_callbackid_packet) != XST_SUCCESS){
				return XST_FAILURE;
			}
		}

		netif_set_up(&ah_tcpip_intvar_netif);

		ah_tcpip_intvar_accept_data = 1;
		
		ah_tcpip_intvar_isEnabled = 1;
	}

	return XST_SUCCESS;
}

err_t ah_tcpip_intfcn_callback_sent(void *arg, struct tcp_pcb *tpcb, u16_t len){
	
	UNUSED(tpcb);
	
	if((u32)len > ah_tcpip_intvar_data_unacked){
		ah_tcpip_intvar_data_unacked = 0;
	}
	else{
		ah_tcpip_intvar_data_unacked -= (u32)len;
	}
	
	if(ah_tcpip_intfcn_sent != NULL){
		ah_tcpip_intfcn_sent(*((u16*)arg), (u16)len);
	}

	return ERR_OK;
}

err_t ah_tcpip_intfcn_callback_receive(void *arg, struct tcp_pcb *tpcb, struct pbuf *p, err_t err){
	
	UNUSED(err);
	
	// do not read the packet if we are not in ESTABLISHED state
	if (!p) { // also called when receiving a closing packet

		ah_tcpip_intvar_connection_alive = 0;

		ah_tcpip_intvar_data_unacked = 0;
		
		// remove callback functions
		tcp_sent(tpcb, NULL);
		tcp_recv(tpcb, NULL);
		//tcp_poll(tpcb, NULL, poll_interval);
		tcp_err(tpcb, NULL);
		tcp_accept(tpcb, NULL);

		if(ah_tcpip_intfcn_closed != NULL){
			ah_tcpip_intfcn_closed(*((u16*)arg));
		}

		// close ah_tcpip_intvar_numberconnection
		tcp_close(tpcb);

		return ERR_OK;
	}

	if(ah_tcpip_intvar_accept_data){
		
		if(ah_tcpip_intfcn_received != NULL){
			ah_tcpip_intfcn_received(*((u16*)arg), p, p->payload, p->len);
		}

		// indicate that the packet has been received */
		tcp_recved(tpcb, p->len);

#ifndef AH_TCPIP_MANUAL_MEMORY
		// free the received pbuf
		pbuf_free(p);
#endif
		
		return ERR_OK;
	}
	else{
		return ERR_MEM;
	}
		
}

/*
err_t poll_callback(void *arg, struct tcp_pcb *tpcb){

	static u32 count = 0;

	if(ah_tcpip_intfcn_poll != NULL){
		(*ah_tcpip_intfcn_poll)(*((u16*)arg), count);
	}

	++count;

	return ERR_OK;
}
*/

void ah_tcpip_intfcn_callback_error(void *arg, err_t err){
	
	// ERR_ABRT: aborted through tcp_abort or by a TCP timer
	// ERR_RST: the ah_tcpip_intvar_numberconnection was reset by the remote host
	// ERR_CLSD: tx connection closed by own application
	// ERR_CONN: not connected
	
	if(err == ERR_ABRT){
		ah_tcpip_intvar_connection_alive = 0;
		ah_tcpip_intvar_pcb_connection = NULL;
	}
	else if(err == ERR_RST){
		ah_tcpip_intvar_connection_alive = 0;
		ah_tcpip_intvar_pcb_connection = NULL;
	}
	else{
		ah_tcpip_intvar_connection_alive = 0;
		ah_tcpip_intvar_pcb_connection = NULL;
	}
	
	ah_tcpip_intvar_data_unacked = 0;
	
	if(ah_tcpip_intfcn_error != NULL){
		if(err == ERR_ABRT){
			ah_tcpip_intfcn_error(*((u16*)arg),  1);
		}
		else if(err == ERR_RST){
			ah_tcpip_intfcn_error(*((u16*)arg),  2);
		}
		else{
			ah_tcpip_intfcn_error(*((u16*)arg),  0);
		}
	}

	return;
}

err_t ah_tcpip_intfcn_callback_accept(void *arg, struct tcp_pcb *newpcb, err_t err){
	
	UNUSED(arg);
	UNUSED(err);
	
	// ToDo: what to do if connection is already open?
	if(ah_tcpip_intvar_connection_alive){
		return ERR_ABRT;
	}
	
	ah_tcpip_intvar_connection_alive = 1;

	ah_tcpip_intvar_pcb_connection = newpcb;

	ah_tcpip_intvar_data_unacked = 0;
	
	if(ah_tcpip_intfcn_accepted != NULL){
		ah_tcpip_intfcn_accepted(ah_tcpip_intvar_numberconnection);
	}

	// just use an integer number indicating the ah_tcpip_intvar_numberconnection id as the callback argument
	//tcp_arg(newpcb, (void*)(UINTPTR)ah_tcpip_intvar_numberconnection);
	tcp_arg(newpcb, (void*)(&ah_tcpip_intvar_numberconnection));

	// set the sent callback for this ah_tcpip_intvar_numberconnection
	tcp_sent(newpcb, ah_tcpip_intfcn_callback_sent);

	// set the receive callback for this ah_tcpip_intvar_numberconnection
	tcp_recv(newpcb, ah_tcpip_intfcn_callback_receive);

	// set the poll callback for this ah_tcpip_intvar_numberconnection, default interval 2 == once per second
	// tcp_poll(newpcb, poll_callback, poll_interval);

	// set the error callback for this ah_tcpip_intvar_numberconnection
	tcp_err(newpcb, ah_tcpip_intfcn_callback_error);

	// increment for subsequent accepted connections
	++ah_tcpip_intvar_numberconnection;

	return ERR_OK;
}

#endif