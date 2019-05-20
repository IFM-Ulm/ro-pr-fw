#ifndef AH_CPU2PL_DATATYPES_H
#define AH_CPU2PL_DATATYPES_H

typedef struct AH_CPU2PL_Config AH_CPU2PL_Config;
struct AH_CPU2PL_Config{
    u16 DeviceId;    // Unique ID of device
    u32 BaseAddress_write; // Device base address for writes
    u32 HighAddress_write; // Device high address for writes
    u32 BaseAddress_read; // Device base address for reads
    u32 HighAddress_read; // Device high address for reads
	u32 BaseAddress_irq; // Device base address for interrupts
    u32 HighAddress_irq; // Device high address for interrupts
    u32 numIn;      // Number of used Inputs
    u32 numOut;     // Number of used Outputs
	u32 irq_enabled; // 0 if interrupts were disabled in the customization gui, 1 if enabled
	u32 input_serialized;  // 0 if serialization of inputs was diasabled in the customization gui, 1 if enabled
	u32 output_serialized; // 0 if serialization of outputs was disabled in the customization gui, 1 if enabled
	u32 advanced_clocking; // 0 if advanced clocking was disabled in the customization gui, 1 if enabled
};

typedef struct AH_CPU2PL_inst AH_CPU2PL_inst; // forward declaration for self inclusion
struct AH_CPU2PL_inst {
	u16 deviceID;
    u32 BaseAddress_write; 	// Device base address for writes
    u32 HighAddress_write;	// Device high address for writes
    u32 BaseAddress_read; 	// Device base address for reads
    u32 HighAddress_read; 	// Device high address for reads
	u32 BaseAddress_irq; 	// Device base address for interrupts
    u32 HighAddress_irq; 	// Device high address for interrupts
    u32 IsReady;     		// Device is initialized and ready
    u32 numIn;      		// Number of used Inputs
    u32 numOut;     		// Number of used Outputs
	u32 irq_enabled; 		// 0 if interrupts were disabled in the customization gui, 1 if enabled
	u32 irq_ID;				// IRQ ID from xparameters.h
	u32 input_serialized;  	// 0 if serialization of inputs was diasabled in the customization gui, 1 if enabled
	u32 output_serialized;  // 0 if serialization of outputs was diasabled in the customization gui, 1 if enabled
	u32 advanced_clocking;	// 0 if serialization of outputs was diasabled in the customization gui, 1 if enabled
	
	// software defined
	u32 clock_pl_connected;			// indicator if clock for the PL is connected
	u32 irq_connected;				// indicator if the irq output is connected (to the ZYNQ PS)
	u32 irq_bitmask; 				// bitmask for enabled interrupts
	u32	inputs_connected[32];		// indicator array if specific input is connected
	u32	inputs_serial_connected;	// indicator array if serial input is connected
	u32 ignore_connection_inputs;	// indicator if the connection status of the inputs should be ignored, e.g. to generate pulses only
	u32 outputs_connected[32];		// indicator array if specific output is connected
	u32 outputs_serial_connected;	// indicator array if serial output is connected
	u32 ignore_connection_outputs;	// indicator if the connection status of the outputs should be ignored
	u32 axi_write_connected;		// indicator if all of s_axi_write_wdata, s_axi_write_aclk and s_axi_write_arestn are connected
	u32 axi_read_connected;			// indicator if all of s_axi_read_rdata, s_axi_read_aclk and s_axi_read_arestn are connected
	u32 axi_intr_connected;			// indicator if all of s_axi_intr_wdata, s_axi_intr_rdata, s_axi_intr_aclk and s_axi_intr_arestn are connected
	void (*irq_handler)(AH_CPU2PL_inst*,u32); // user callback function, receives port AXI4 reference and IRQ ID as argument
};

#endif