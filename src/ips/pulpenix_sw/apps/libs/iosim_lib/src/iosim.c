#include <iosim.h>
#include <bm_printf.h>
	
//---------------------------------------------------------

void sim_finish () { 
     bm_printf("$sim_finish");
}
//---------------------------------------------------------

void sim_stop () { 
     bm_printf("$sim_stop");
}

void sim_error () { 
     bm_printf("$error");
}
