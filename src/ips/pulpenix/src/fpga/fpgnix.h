#ifndef __FPGNIX_H__
#define __FPGNIX_H__

#include <fpgnix_address_map.h>

typedef enum {
    PNX_CARP = 0x11110000,
    MMSPI_CARP = 0x22220000,
    HAMSA_CORE_CARP = 0x33330000,
    L2_CARP = 0x44440000
} sansa_carp;

#endif
