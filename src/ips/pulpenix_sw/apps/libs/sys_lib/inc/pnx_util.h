#ifndef PNX_UTIL
#define PNX_UTIL

#include <platform.h>

#define ALL_BYTES 0xFFFF

#define csrw(csr, value)  asm volatile ("csrw\t\t" #csr ", %0" : /* no output */ : "r" (value));
#define csrr(csr, value)  asm volatile ("csrr\t\t%0, " #csr "": "=r" (value));


void wr32(unsigned int , unsigned int);// ADDRESS, DATA
unsigned int  rd32(unsigned int);// ADDRESS, returns DATA

void reg_poll(unsigned long, unsigned long, long); // ADDRESS, DATA, MASK

void wr_bit(unsigned int ADDRESS, unsigned char BIT_INDEX, unsigned char DATA);
unsigned char rd_bit(unsigned int ADDRESS, unsigned char BIT_INDEX);
void wr_field(unsigned int ADDRESS, unsigned char FIELD_LSB, unsigned char FIELD_WIDTH, unsigned int DATA);
unsigned int rd_field(unsigned int ADDRESS, unsigned char FIELD_LSB, unsigned char FIELD_WIDTH);

inline unsigned int get_hart_id() {int res; csrr(0xF14/*mhartid*/, res); return res;}

#endif
