// Copyright 2017 ETH Zurich and University of Bologna.
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51 (the “License”); you may not use this file except in
// compliance with the License.  You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an “AS IS” BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

#include "timer.h"

void reset_timer(void) {
    set_timer(0);
}

void set_timer(uint64_t t) {
    uint32_t th = (uint32_t)(t>>32);
    uint32_t tl = (uint32_t)(t);
    TIRAH = th;
    TIRAL = tl;
}

void start_timer(void) {
  TPRA = TPRA | 0x1;
}

void stop_timer(void) {
  TPRA = TPRA & 0xfffe;
}

uint32_t get_time(void) {
  return TIRAL;
}

uint64_t get_time_long(void) {
    uint64_t ret;
    uint32_t th;
    do {
        th = TIRAH;
        ret = ((uint64_t)th) << 32;
        ret |= TIRAL;
    } while (TIRAH != th);
    return ret;
}

void timer_set_cmp(uint64_t cmp) {
    uint32_t cmph = (uint32_t)(cmp>>32);
    TOCRAH = cmph;
    uint32_t cmpl = (uint32_t)(cmp);
    TOCRAL = cmpl;
}

void timer_set_prescaler(unsigned char p) {
    TPRA = (TPRA & 1) | (p<<8);
}
