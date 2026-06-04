
typedef enum {FALSE,TRUE} boolean;  // Define boolean type For more readable code

int  bm_printf(const char *fmt, ...);

int bm_fopen(char * file_name, char type) ;

int bm_fopen_r(char * file_name) ;

int bm_fopen_w(char * file_name) ;

int  bm_fclose(int file_idx) ;

int bm_strcmp (char *s1, char *s2) ;

int bm_strlen (const char *str) ;

void pyshell_reset() ;

char bm_gets (char * str_buf) ;

char bm_fgets (int file_id, char * str_buf) ;

char load_memh(char * cmd_str) ;

int  bm_access_file(unsigned int file_id);

int bm_fprintf(int file_id , const char *fmt, ...);

unsigned int hex_str_to_uint (char * s) ;

signed int dec_str_to_int (char * s) ;
   
int scan_str (char * str_in, int start_position, char * str_out) ;

char bm_fgetln (int file_id, char * str_buf);

unsigned int bm_fget_hex_val(int filePtr) ;

signed int bm_fget_dec_val(int filePtr);

void bm_dump_hex_file (int file_id, char * buf, int num_bytes);

void bm_set_xmem_oel_mode();

int bm_load_hex_file (int file_id, int num_bytes , unsigned char * buf);

void bm_start_soc_load_hex_file (int file_id, int num_bytes , unsigned char * buf) ;

int bm_check_soc_load_hex_file () ;

void bm_start_soc_store_hex_file (int file_id, int num_bytes , int num_bytes_per_output_line, unsigned char * buf) ;

int bm_check_soc_store_hex_file () ;

void bm_dump_ascii_file (int file_id, char * buf, int num_chars);

int bm_load_ascii_file(unsigned int file_id, char *src_text, int num_chars);

int bm_memcmp (unsigned char * mem_ptr1, unsigned char * mem_ptr2, int count) ;

void bm_sprintf(char *buf, const char *fmt, ...) ;

void * bm_memset (void *dest, char val, int len)  ;

void bm_sys_call (char * sys_call_str);

char bm_quit_app() ;

// Added to prevent CLIB printf included in code needed for calls as Illegal instructions etc.
int printf(const char *fmt, ...) ;
