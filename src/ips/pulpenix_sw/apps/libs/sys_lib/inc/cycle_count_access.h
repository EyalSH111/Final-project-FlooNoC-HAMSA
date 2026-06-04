// Implementation moved to util.c linked routines , otherwise optimizer does not guarantee order
// [plus need to block with asm volatile ("":::"memory");

#define ENABLE_CYCLE_COUNT asm volatile ("":::"memory");\
                           enable_cycle_count() ;\
                           asm volatile ("":::"memory");                           

#define RESET_CYCLE_COUNT  asm volatile ("":::"memory");\
                           reset_cycle_count() ;\
                           asm volatile ("":::"memory");


#define GET_CYCLE_COUNT_START(ret_var_name) \
                          asm volatile ("":::"memory"); \
                          ret_var_name = get_cycle_count()+3; \
                          asm volatile ("":::"memory");     
  
#define GET_CYCLE_COUNT_END(ret_var_name) \
                          asm volatile ("":::"memory"); \
                          ret_var_name = get_cycle_count()-2; \
                          asm volatile ("":::"memory");     
  
 