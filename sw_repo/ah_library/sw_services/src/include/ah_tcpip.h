#include "xparameters.h"

#ifndef AH_TCPIP_H
#define AH_TCPIP_H

/*	activate usage of the Ethernet controller in the hardware:
		- open "Block Properties" of the IP "ZYNQ7 Processing System"
		- go to "MIO Configuration"
		- open "I/O Peripherials"
		- activate "ENET 0" and assign "MIO 16 ... 27", deactivate "MDIO"
*/

/* recommended settings for lwip:
		
	lwip_memory_options
		mem_size = 2097152 (default = 131072)
		memp_n_pbuf = 128 (default = 16)
		memp_n_tcp_pcb = 8 (default = 32)
		memp_n_tcp_pcb_listen = 2 (default = 8)
		memp_n_tcp_seg = 4096 (default = 256)
	pbuf_options
		pbuf_pool_size = 4096 (default = 256)
	tcp_options
		tcp_snd_buf = 65535 (default = 8192)
		tcp_wnd = 65535 (default = 2048)
	temac_adapter_options
		phy_link_speed CONFIG_LINKSPEED1000 (default = CONFIG_LINKSPEED_AUTODETECT)
	udp_options
		lwip_udp = false (default = true)
		
	ignore warnings
		setting tcp_snd_buf and tcp_wnd to the maximum value will lead to the following warning, which can be ignored safely:
		lwip-1.4.1/src/core/tcp.c:622:20: warning: comparison is always false due to limited range of data type [-Wtype-limits]
		
	increase heap size
		in your project, open the file lscript.ld
		increase the standard "Heap size" of 0x2000 to a larger value (ToDo: find minimum value)
		1MB: 0x100000
		
		
	additional in-depth comments / remarks / recommendations:
		
		TCP_SND_QUEUELEN = 16 * TCP_SND_BUF / TCP_MSS 
			TCP_MSS = 1460
			TCP_SND_QUEUELEN <=! 0xffff (65535)
			TCP_SND_BUF >! 2 * TCP_MSS
			TCP_SND_QUEUELEN >! 2
			TCP_SND_QUEUELEN >! 2 * (TCP_SND_BUF / TCP_MSS)
		tcp_snd_buf recommendation:  x * 1460 with x large if much data has to be sent

		memp_n_tcp_seg > TCP_SND_QUEUELEN, defines maximum number of tcp segments
		
		tcp_wnd <= 0xffff (65535)
		
		TCP_WND <! (PBUF_POOL_SIZE * (PBUF_POOL_BUFSIZE - (PBUF_LINK_HLEN + PBUF_IP_HLEN + PBUF_TRANSPORT_HLEN)))
			PBUF_POOL_SIZE = 256 (default)
			PBUF_POOL_BUFSIZE = 1700 (default)
			PBUF_LINK_HLEN = 16
			PBUF_IP_HLEN = 20
			PBUF_TRANSPORT_HLEN = 20
			default: TCP_WND <! 420864
				-> pbuf pool is really large (never runs out of memory?)
*/

#ifdef AH_TCPIP_ACTIVATED

#include "lwip/tcp.h"
#include "lwipopts.h"

#ifndef AH_TIMER_ACTIVATED
#error AH_TIMER needs to be activated in order to use AH_TCPIP
#endif

#ifndef AH_SCUGIC_ACTIVATED
#error AH_SCUGIC needs to be activated in order to use AH_TCPIP
#endif

// include to check if lwip is activated
#ifndef __LWIPOPTS_H_
#error LWIP needs to be activated in order to use AH_TCPIP
#endif

#ifdef CONFIG_LINKSPEED_AUTODETECT
#warning unrealiable option CONFIG_LINKSPEED_AUTODETECT detected, please see ah_tcpip.h for correct settings
/*
	parameter phy_link_speed = CONFIG_LINKSPEED_AUTODETECT did not working in testing
	for the Zybo, phy_link_speed = CONFIG_LINKSPEED1000 is the correct setting
*/
#endif

#if MEM_SIZE == 131072
#warning default settings of TCP_SND_BUF found, please see ah_tcpip.h for optimized settings
#endif

#if MEMP_NUM_TCP_SEG == 256
#warning default settings of MEMP_NUM_TCP_SEG found, please see ah_tcpip.h for optimized settings
#endif

#if TCP_SND_BUF == 8192
#warning default settings of TCP_SND_BUF found, please see ah_tcpip.h for optimized settings
#endif

#if TCP_WND == 2048
#warning default settings of TCP_SND_BUF found, please see ah_tcpip.h for optimized settings
#endif


#ifdef AH_TCPIP_MAC_I2C
#ifndef XPAR_XIICPS_0_DEVICE_ID
#error XPAR_XIICPS_0_DEVICE_ID needs to be presnet in order to use AH_TCPIP_MAC_I2C
#endif
#endif


#include "xstatus.h"
#include "xil_types.h"

// forwarded type declarations
//typedef signed     char    s8_t; // copied from from arch/cc.h to prevent inclusion
//typedef s8_t err_t;
//struct pbuf;

s32 ah_tcpip_init(void);
u8 ah_tcipip_isInit(void);

s32 ah_tcpip_setup(void);
u8 ah_tcpip_isSetup(void);

s32 ah_tcpip_setup_mac(u8 octet_1, u8 octet_2, u8 octet_3, u8 octet_4, u8 octet_5, u8 octet_6);
s32 ah_tcpip_setup_ip(u8 octet_1, u8 octet_2, u8 octet_3, u8 octet_4);
s32 ah_tcpip_setup_netmask(u8 octet_1, u8 octet_2, u8 octet_3, u8 octet_4);
s32 ah_tcpip_setup_gateway(u8 octet_1, u8 octet_2, u8 octet_3, u8 octet_4);
s32 ah_tcpip_setup_port(u8 port);

s32 ah_tcpip_setup_timerIntervalMS(u32 interval);
s32 ah_tcpip_setup_pollingmode(u8 mode);
s32 ah_tcpip_setup_max_send_size(u32 valBytes);

s32 ah_tcpip_setup_callbackAccepted(void (*fcnptr)(u16));
s32 ah_tcpip_setup_callbackReceived(void (*fcnptr)(u16, struct pbuf*, void*, u16));
s32 ah_tcpip_setup_callbackSent(void (*fcnptr)(u16, u16));
s32 ah_tcpip_setup_callbackError(void (*fcnptr)(u16, u8));
s32 ah_tcpip_setup_callbackClosed(void (*fcnptr)(u16));
s32 ah_tcpip_setup_callbackPoll(void (*fcnptr)(u16));

s32 ah_tcpip_enable(void);
u8 ah_tcpip_isEnabled(void);

s32 ah_tcpip_open(void);
s32 ah_tcpip_close(u8 listen_server);

u8 ah_tcpip_checkBuffer(u16 len);
u8 ah_tcpip_checkConnection(void);

/* use this flag functions to indicate wether data should be flagged:
	- to be copied (if data to be send is not guaranteed to remain available)
	- to be indicated that more data follows (use with caution)
*/
s32 ah_tcip_setflag_copy(u8 flag);
s32 ah_tcip_setflag_more(u8 flag);

/* Comment on sending datatypes different to single bytes (u8), e.g. u16 or u32:
	Byte-order will be inverted as the data pointer will be interpreted as a byte vector,
	i.e. each value with a datatype larger than u8 will be received as lowest bytes first.
	E.g. sending an u16 = 0x1F2D will be received as 2 bytes, first 0x2D followed by 0x1F.
	E.g. sending an u32 = 0x1F2DA06D will be received as 4 bytes: first 0x6D, then 0xA0, then 0x2D and finally 0x1F.
*/
s32 ah_tcpip_send(const void *data, u16 len, u8 force_send);
s32 ah_tcpip_send_blocking(const void *data, u16 len, u8 force_send);
s32 ah_tcpip_send_output(void);

s32 ah_tcpip_refuse_data(void);
u8 ah_tcpip_status_data(void);
s32 ah_tcpip_accept_data(void);

s32 ah_tcpip_pull(u8* retVal);

#endif

#endif
