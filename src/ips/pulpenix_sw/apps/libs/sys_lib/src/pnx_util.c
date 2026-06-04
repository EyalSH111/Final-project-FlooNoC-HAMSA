

void wr32(unsigned int ADDRESS, unsigned int DATA) {
    *((volatile unsigned int *)ADDRESS) = DATA;
}

unsigned int rd32(unsigned int ADDRESS) {
    return *((volatile unsigned int *)ADDRESS);
}

void reg_poll(unsigned int ADDRESS, unsigned int DATA, int MASK) {

    unsigned int rd_data, rd_data_masked;

    //read data before comparing
    rd_data = rd32(ADDRESS);
    rd_data_masked = rd_data & MASK;

    while (rd_data_masked != DATA) {
        rd_data = rd32(ADDRESS);
        rd_data_masked = rd_data & MASK;
    }
} //reg_poll

void wr_bit(unsigned int ADDRESS, unsigned char BIT_INDEX, unsigned char DATA) {
    DATA &= 0x1;
    unsigned int r = rd32(ADDRESS);
    r &= ~(1<<BIT_INDEX);
    r |=  (DATA<<BIT_INDEX);
    wr32(ADDRESS, r);
}

unsigned char rd_bit(unsigned int ADDRESS, unsigned char BIT_INDEX) {
    unsigned int DATA = rd32(ADDRESS);
    DATA >>= BIT_INDEX;
    DATA &= 0x1;
    return DATA;
}

void wr_field(unsigned int ADDRESS, unsigned char FIELD_LSB, unsigned char FIELD_WIDTH, unsigned int DATA) {
    unsigned int MASK = 0xffffffff;
    MASK >>= (32-FIELD_WIDTH);
    DATA &= MASK;
    MASK <<= FIELD_LSB;
    DATA <<= FIELD_LSB;

    unsigned int r = rd32(ADDRESS);
    r &= ~MASK;
    r |=  DATA;

    wr32(ADDRESS, r);
}

unsigned int rd_field(unsigned int ADDRESS, unsigned char FIELD_LSB, unsigned char FIELD_WIDTH) {
    unsigned int DATA = rd32(ADDRESS);
    DATA >>= FIELD_LSB;
    unsigned int MASK = 0xffffffff;
    MASK >>= (32-FIELD_WIDTH);
    DATA &= MASK;

    return DATA;
}
