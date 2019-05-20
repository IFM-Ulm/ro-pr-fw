#ifndef SRC_FW_SETTINGS_H_
#define SRC_FW_SETTINGS_H_

#include "fw_impl_custom.h"
#include "fw_impl_generated.h"

// settings to be adjusted per design

// static indicators, should be kept
#define READOUT_MASK_SEQ (0)
#define READOUT_MASK_PAR (1)

// data version
#define DATA_VERSION 20190329

// number of bytes per sample (32bit = 4 bytes)
#define DATA_BYTES (4)

// assuming static processor frequency of 650000000Hz, TIME_DIV gives the divisor for XTime_GetTime() outputs to calculate us
#define TIME_DIV ((u64)325)

//#define MAX(X, Y) (((X) > (Y)) ? (X) : (Y))

#endif
