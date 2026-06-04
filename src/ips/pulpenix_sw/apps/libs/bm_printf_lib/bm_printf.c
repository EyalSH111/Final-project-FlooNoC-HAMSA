

// Based on CoreMark provied ee_printf.c


#include <stddef.h>
#include <stdarg.h>
#include <uart.h>
#include <bm_printf.h>


#define ZEROPAD  	(1<<0)	/* Pad with zero */
#define SIGN    	(1<<1)	/* Unsigned/signed long */
#define PLUS    	(1<<2)	/* Show plus */
#define SPACE   	(1<<3)	/* Spacer */
#define LEFT    	(1<<4)	/* Left justified */
#define HEX_PREP 	(1<<5)	/* 0x */
#define UPPERCASE   (1<<6)	/* 'ABCDEF' */

#define is_digit(c) ((c) >= '0' && (c) <= '9')

static char *digits = "0123456789abcdefghijklmnopqrstuvwxyz";
static char *upper_digits = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ";

static size_t strnlen(const char *s, size_t count);
static size_t strnlen(const char *s, size_t count)
{
  const char *sc;
  for (sc = s; *sc != '\0' && count--; ++sc);
  return sc - s;
}

static int skip_atoi(const char **s)
{
  int i = 0;
  while (is_digit(**s)) i = i*10 + *((*s)++) - '0';
  return i;
}

static char *number(char *str, long num, int base, int size, int precision, int type)
{
  char c, sign, tmp[66];
  char *dig = digits;
  int i;

  if (type & UPPERCASE)  dig = upper_digits;
  if (type & LEFT) type &= ~ZEROPAD;
  if (base < 2 || base > 36) return 0;
  
  c = (type & ZEROPAD) ? '0' : ' ';
  sign = 0;
  if (type & SIGN)
  {
    if (num < 0)
    {
      sign = '-';
      num = -num;
      size--;
    }
    else if (type & PLUS)
    {
      sign = '+';
      size--;
    }
    else if (type & SPACE)
    {
      sign = ' ';
      size--;
    }
  }

  if (type & HEX_PREP)
  {
    if (base == 16)
      size -= 2;
    else if (base == 8)
      size--;
  }

  i = 0;

  if (num == 0)
    tmp[i++] = '0';
  else
  {
    while (num != 0)
    {
      tmp[i++] = dig[((unsigned long) num) % (unsigned) base];
      num = ((unsigned long) num) / (unsigned) base;
    }
  }

  if (i > precision) precision = i;
  size -= precision;
  if (!(type & (ZEROPAD | LEFT))) while (size-- > 0) *str++ = ' ';
  if (sign) *str++ = sign;
  
  if (type & HEX_PREP)
  {
    if (base == 8)
      *str++ = '0';
    else if (base == 16)
    {
      *str++ = '0';
      *str++ = digits[33];
    }
  }

  if (!(type & LEFT)) while (size-- > 0) *str++ = c;
  while (i < precision--) *str++ = '0';
  while (i-- > 0) *str++ = tmp[i];
  while (size-- > 0) *str++ = ' ';

  return str;
}

static char *eaddr(char *str, unsigned char *addr, int size, int precision, int type)
{
  char tmp[24];
  char *dig = digits;
  int i, len;

  if (type & UPPERCASE)  dig = upper_digits;
  len = 0;
  for (i = 0; i < 6; i++)
  {
    if (i != 0) tmp[len++] = ':';
    tmp[len++] = dig[addr[i] >> 4];
    tmp[len++] = dig[addr[i] & 0x0F];
  }

  if (!(type & LEFT)) while (len < size--) *str++ = ' ';
  for (i = 0; i < len; ++i) *str++ = tmp[i];
  while (len < size--) *str++ = ' ';

  return str;
}

static char *iaddr(char *str, unsigned char *addr, int size, int precision, int type)
{
  char tmp[24];
  int i, n, len;

  len = 0;
  for (i = 0; i < 4; i++)
  {
    if (i != 0) tmp[len++] = '.';
    n = addr[i];
    
    if (n == 0)
      tmp[len++] = digits[0];
    else
    {
      if (n >= 100) 
      {
        tmp[len++] = digits[n / 100];
        n = n % 100;
        tmp[len++] = digits[n / 10];
        n = n % 10;
      }
      else if (n >= 10) 
      {
        tmp[len++] = digits[n / 10];
        n = n % 10;
      }

      tmp[len++] = digits[n];
    }
  }

  if (!(type & LEFT)) while (len < size--) *str++ = ' ';
  for (i = 0; i < len; ++i) *str++ = tmp[i];
  while (len < size--) *str++ = ' ';

  return str;
}

#ifdef HAS_FLOAT

char *ecvtbuf(double arg, int ndigits, int *decpt, int *sign, char *buf);
char *fcvtbuf(double arg, int ndigits, int *decpt, int *sign, char *buf);
static void ee_bufcpy(char *d, char *s, int count); 
 
void ee_bufcpy(char *pd, char *ps, int count) {
	char *pe=ps+count;
	while (ps!=pe)
		*pd++=*ps++;
}

static void parse_float(double value, char *buffer, char fmt, int precision)
{
  int decpt, sign, exp, pos;
  char *digits = NULL;
  char cvtbuf[80];
  int capexp = 0;
  int magnitude;

  if (fmt == 'G' || fmt == 'E')
  {
    capexp = 1;
    fmt += 'a' - 'A';
  }

  if (fmt == 'g')
  {
    digits = ecvtbuf(value, precision, &decpt, &sign, cvtbuf);
    magnitude = decpt - 1;
    if (magnitude < -4  ||  magnitude > precision - 1)
    {
      fmt = 'e';
      precision -= 1;
    }
    else
    {
      fmt = 'f';
      precision -= decpt;
    }
  }

  if (fmt == 'e')
  {
    digits = ecvtbuf(value, precision + 1, &decpt, &sign, cvtbuf);

    if (sign) *buffer++ = '-';
    *buffer++ = *digits;
    if (precision > 0) *buffer++ = '.';
    ee_bufcpy(buffer, digits + 1, precision);
    buffer += precision;
    *buffer++ = capexp ? 'E' : 'e';

    if (decpt == 0)
    {
      if (value == 0.0)
        exp = 0;
      else
        exp = -1;
    }
    else
      exp = decpt - 1;

    if (exp < 0)
    {
      *buffer++ = '-';
      exp = -exp;
    }
    else
      *buffer++ = '+';

    buffer[2] = (exp % 10) + '0';
    exp = exp / 10;
    buffer[1] = (exp % 10) + '0';
    exp = exp / 10;
    buffer[0] = (exp % 10) + '0';
    buffer += 3;
  }
  else if (fmt == 'f')
  {
    digits = fcvtbuf(value, precision, &decpt, &sign, cvtbuf);
    if (sign) *buffer++ = '-';
    if (*digits)
    {
      if (decpt <= 0)
      {
        *buffer++ = '0';
        *buffer++ = '.';
        for (pos = 0; pos < -decpt; pos++) *buffer++ = '0';
        while (*digits) *buffer++ = *digits++;
      }
      else
      {
        pos = 0;
        while (*digits)
        {
          if (pos++ == decpt) *buffer++ = '.';
          *buffer++ = *digits++;
        }
      }
    }
    else
    {
      *buffer++ = '0';
      if (precision > 0)
      {
        *buffer++ = '.';
        for (pos = 0; pos < precision; pos++) *buffer++ = '0';
      }
    }
  }

  *buffer = '\0';
}

static void decimal_point(char *buffer)
{
  while (*buffer)
  {
    if (*buffer == '.') return;
    if (*buffer == 'e' || *buffer == 'E') break;
    buffer++;
  }

  if (*buffer)
  {
    int n = strnlen(buffer,256);
    while (n > 0) 
    {
      buffer[n + 1] = buffer[n];
      n--;
    }

    *buffer = '.';
  }
  else
  {
    *buffer++ = '.';
    *buffer = '\0';
  }
}

static void cropzeros(char *buffer)
{
  char *stop;

  while (*buffer && *buffer != '.') buffer++;
  if (*buffer++)
  {
    while (*buffer && *buffer != 'e' && *buffer != 'E') buffer++;
    stop = buffer--;
    while (*buffer == '0') buffer--;
    if (*buffer == '.') buffer--;
    while (buffer!=stop)
		*++buffer=0;
  }
}

static char *flt(char *str, double num, int size, int precision, char fmt, int flags)
{
  char tmp[80];
  char c, sign;
  int n, i;

  // Left align means no zero padding
  if (flags & LEFT) flags &= ~ZEROPAD;

  // Determine padding and sign char
  c = (flags & ZEROPAD) ? '0' : ' ';
  sign = 0;
  if (flags & SIGN)
  {
    if (num < 0.0)
    {
      sign = '-';
      num = -num;
      size--;
    }
    else if (flags & PLUS)
    {
      sign = '+';
      size--;
    }
    else if (flags & SPACE)
    {
      sign = ' ';
      size--;
    }
  }

  // Compute the precision value
  if (precision < 0)
    precision = 6; // Default precision: 6

  // Convert floating point number to text
  parse_float(num, tmp, fmt, precision);

  if ((flags & HEX_PREP) && precision == 0) decimal_point(tmp);
  if (fmt == 'g' && !(flags & HEX_PREP)) cropzeros(tmp);

  n = strnlen(tmp,256);

  // Output number with alignment and padding
  size -= n;
  if (!(flags & (ZEROPAD | LEFT))) while (size-- > 0) *str++ = ' ';
  if (sign) *str++ = sign;
  if (!(flags & LEFT)) while (size-- > 0) *str++ = c;
  for (i = 0; i < n; i++) *str++ = tmp[i];
  while (size-- > 0) *str++ = ' ';

  return str;
}

#endif

static int ee_vsprintf(char *buf, const char *fmt, va_list args)
{
  int len;
  unsigned long num;
  int i, base;
  char *str;
  char *s;

  int flags;            // Flags to number()

  int field_width;      // Width of output field
  int precision;        // Min. # of digits for integers; max number of chars for from string
  int qualifier;        // 'h', 'l', or 'L' for integer fields

  for (str = buf; *fmt; fmt++)
  {
    if (*fmt != '%')
    {
      *str++ = *fmt;
      continue;
    }
                  
    // Process flags
    flags = 0;
repeat:
    fmt++; // This also skips first '%'
    switch (*fmt)
    {
      case '-': flags |= LEFT; goto repeat;
      case '+': flags |= PLUS; goto repeat;
      case ' ': flags |= SPACE; goto repeat;
      case '#': flags |= HEX_PREP; goto repeat;
      case '0': flags |= ZEROPAD; goto repeat;
    }
          
    // Get field width
    field_width = -1;
    if (is_digit(*fmt))
      field_width = skip_atoi(&fmt);
    else if (*fmt == '*')
    {
      fmt++;
      field_width = va_arg(args, int);
      if (field_width < 0)
      {
        field_width = -field_width;
        flags |= LEFT;
      }
    }

    // Get the precision
    precision = -1;
    if (*fmt == '.')
    {
      ++fmt;    
      if (is_digit(*fmt))
        precision = skip_atoi(&fmt);
      else if (*fmt == '*')
      {
        ++fmt;
        precision = va_arg(args, int);
      }
      if (precision < 0) precision = 0;
    }

    // Get the conversion qualifier
    qualifier = -1;
    if (*fmt == 'l' || *fmt == 'L')
    {
      qualifier = *fmt;
      fmt++;
    }

    // Default base
    base = 10;

    switch (*fmt)
    {
      case 'c':
        if (!(flags & LEFT)) while (--field_width > 0) *str++ = ' ';
        *str++ = (unsigned char) va_arg(args, int);
        while (--field_width > 0) *str++ = ' ';
        continue;

      case 's':
        s = va_arg(args, char *);
        if (!s) s = "<NULL>";
        len = strnlen(s, precision);
        if (!(flags & LEFT)) while (len < field_width--) *str++ = ' ';
        for (i = 0; i < len; ++i) *str++ = *s++;
        while (len < field_width--) *str++ = ' ';
        continue;

      case 'p':
        if (field_width == -1)
        {
          field_width = 2 * sizeof(void *);
          flags |= ZEROPAD;
        }
        str = number(str, (unsigned long) va_arg(args, void *), 16, field_width, precision, flags);
        continue;

      case 'A':
        flags |= UPPERCASE;
        __attribute__((fallthrough));

      case 'a':
        if (qualifier == 'l')
          str = eaddr(str, va_arg(args, unsigned char *), field_width, precision, flags);
        else
          str = iaddr(str, va_arg(args, unsigned char *), field_width, precision, flags);
        continue;

      // Integer number formats - set up the flags and "break"
      case 'o':
        base = 8;
        break;

      case 'X':
        flags |= UPPERCASE;
        __attribute__((fallthrough));

      case 'x':
        base = 16;
        break;

      case 'd':
      case 'i':
        flags |= SIGN;

      case 'u':
        break;

#ifdef HAS_FLOAT

      case 'f':
        str = flt(str, va_arg(args, double), field_width, precision, *fmt, flags | SIGN);
        continue;

#endif

      default:
        if (*fmt != '%') *str++ = '%';
        if (*fmt)
          *str++ = *fmt;
        else
          --fmt;
        continue;
    }

    if (qualifier == 'l')
      num = va_arg(args, unsigned long);
    else if (flags & SIGN)
      num = va_arg(args, int);
    else
      num = va_arg(args, unsigned int);

    str = number(str, num, base, field_width, precision, flags);
  }

  *str = '\0';
  return str - buf;
}

//------------------------------------------------------------------------------------------

int uart_sendbuf(char * buf)
{
  char *p ;
  int n=0;
  p=buf;
  while (*p) {
	uart_sendchar(*p);
	n++;
	p++;
  }
  return n;
}

//------------------------------------------------------------------------------------------


int bm_printf(const char *fmt, ...)
{
  //char buf[256],*p;
  char buf[1024],*p;  // Modified by Udi 15/May/2016 Suspect causing 
                      // stack corruption in coremark debug mode while printing state of size 666
  va_list args;
  va_start(args, fmt);
  ee_vsprintf(buf, fmt, args);
  va_end(args);
  return uart_sendbuf(buf) ;
}


//============================ scan stuff =====================================

char bm_isspace(char c)
{
        return (((c>=0x09) && (c<=0x0D)) || (c==0x20));
}

//------------------------------------------------------------


char bm_gets (char * str_buf) {
	char str_on = 0 ;
	
		
	unsigned int c ; // unsigned int possibly needed to indicate verilog EOF = -1
	int si = 0 ;
	str_buf[0] = 0 ; // prevent uninitialized debug prints
		
    while ((char)(c=uart_getchar())!=((char)0xFF)) {   
        str_buf[si++] = c;
        if (c==0) return (1) ;
    }	 
    return (0) ;  
}

//-------------------------------------------------------------------------------



unsigned int hex_str_to_uint (char * s) {
    
    int i=0 ;
    char c = 0 ;
    unsigned int v = 0;
    
    while ((c=s[i++])!=0) {
		char cval = ((c>='0') && (c<='9')) ? c - '0' : (
		            ((c>='A') && (c<='F')) ? 10 + c - 'A' : (
             		((c>='a') && (c<='f')) ? 10 + c - 'a' : 'X')) ;

        if (cval=='X') {
		   bm_printf("\nERROR hex_str_to_uint reading into hex a non hex char in string: %s ; c=%d\n",s,c) ;
		   return 0 ;
		}				
					
					
		v = (v<<4) + (unsigned int) cval ;	 
	}
    return v ;
}    

//--------------------------------------------------------


signed int dec_str_to_int (char * s) {
    
    int i=0 ;
    char c = 0 ;
    int val = 0;
    char is_pos = !0 ; // positive by default
    
    if (s[0]=='-') {
        is_pos = 0 ;
        i=1 ;
    }
    
    while ((c=s[i++])!=0) {
        
        char cval ;
		if  ((c>='0') && (c<='9')) 
            cval = c - '0' ;
        else {
		  bm_printf("\nERROR dec_str_to_int got a non decimal digit for string: %s\n",s) ;
		  return 0 ;
        }									
		val = (val*10) + (unsigned int) cval ;	 
	}
    return is_pos ? val : (-1)*val ;
}    




//----------------------------------------------------------------
int scan_str (char * str_in, int start_position, char * str_out) 
{
                       
    int si_pos, so_pos, capture , done ;
    char c ;
    
    si_pos = start_position;            
    capture = 0 ;
    so_pos = 0 ;
    
    while (1) { 
        c = str_in[si_pos++]  ;
        if (c == ' ') {
            if (capture) {
                str_out[so_pos] = 0 ;
                return (si_pos) ;
            }
            else continue ; // Skip leading spaces
        } else {
             str_out[so_pos++] = c ;
             capture = 1 ;                      
             if (c==0) return (0) ; // end of scan   
        } 
    }    
}

//==============================================================
// File Access
//==============================================================


void pyshell_reset() {    
    bm_printf("$pyshell reset()\n") ;  
    uart_getchar() ; // Always need to take pyshell response even if not used
}

//--------------------------------------------------------

int  bm_fopen(char * file_name, char type) {   // type is one of 'r','w'
  bm_printf("$pyshell openFile(\"%s\",\'%c\')\n",file_name,type);
  int file_id = (int)uart_getchar() ;                 
  return (file_id) ; // return the file Index
}

//--------------------------------------------------------

int bm_fopen_r(char * file_name) {return bm_fopen(file_name,'r');}
int bm_fopen_w(char * file_name) {return bm_fopen(file_name,'w');}

//--------------------------------------------------------


int  bm_fclose(int file_idx) {  
  bm_printf("$pyshell closeFile(%d)\n",file_idx);  
  uart_getchar() ; // Always need to take pyshell response even if not used
  return 1 ;
}

//--------------------------------------------------------



int  bm_access_file(unsigned int file_id) {
   bm_printf("$pyshell accessFile(%d)\n",file_id);
   uart_getchar() ;  // Always need to take pyshell response even if not used
   return(1) ;
   
}

//--------------------------------------------------------

void load_memh_trans(int mem_file_idx, int addr_offset) {
  
  char done = 0 ;
  char addr_str[20] ;
  char data_str[20] ;
  unsigned int addr,data,actual_addr;  
  
  bm_printf("Starting load File %d\n",mem_file_idx);  

  while (!done) {
      
      bm_fgets (mem_file_idx , addr_str) ; 

      if (addr_str[0]=='@') {      // Skip Empty lines   
          
         bm_fgets (mem_file_idx , data_str) ; 
               
         addr = hex_str_to_uint (&addr_str[1]) ; // skip the leading '@' char      
         data = hex_str_to_uint (data_str) ;
         
         actual_addr = addr_offset+addr ;
         
         *(volatile unsigned int*) actual_addr = data ;
            
      }     
      done = (addr_str[0]==(char)(0xFF)) ;  // EOF     
  }
  bm_printf("Memory File %d Loaded\n",mem_file_idx);  
}

//--------------------------------------------------------

char load_memh(char * cmd_str) {
    
  char cmd_ltr_str[2] ;
  char file_name[80] ;
  char addr_str[20] ;  
  char data_str[20];

  unsigned int actual_addr, addr_offset, addr, data;
  int str_pos ;
  
  int mem_file_idx ;
  int done = 0 ;
  char retVal ;
  
  str_pos = scan_str (cmd_str,0,cmd_ltr_str) ;
  str_pos = scan_str (cmd_str,str_pos,file_name) ;  
  str_pos = scan_str (cmd_str,str_pos,addr_str) ;  

  addr_offset = hex_str_to_uint (addr_str) ;
   
  bm_printf("Loading file %s to base address , added address offset = %x (hex)\n",file_name,addr_offset);
  
  mem_file_idx = bm_fopen(file_name , 'r') ;
  
  load_memh_trans(mem_file_idx,addr_offset) ;
    
  bm_fclose(mem_file_idx) ;  
  
  return 1 ;        
}

//--------------------------------------------------------


 
int bm_fprintf(int file_id , const char *fmt, ...) {
    
    char buf[1024],*p;  // Modified by Udi 15/May/2016 Suspect causing 
                        // stack corruption in coremark debug mode while printing state of size 666
    va_list args;
    int n=0;

    va_start(args, fmt);
    ee_vsprintf(buf, fmt, args);
    va_end(args);
    p=buf;
  
    bm_access_file(file_id) ;
    while (*p) {
	  uart_sendchar(*p);
	  n++;
	  p++;
    }    
    bm_access_file(-1) ;   // return to default stdio
  
    return n ;
}   


//--------------------------------------------------------



char bm_fgets (int file_id, char * str_buf) {    
    char retVal ;
    bm_printf("$pyshell fgets(%c)\n",'0'+file_id); // avoiding %d for fast print (file id limited to 0-9
    retVal = bm_gets(str_buf) ;
    //uart_getchar() ; // Always need to take pyshell response even if not used
    return retVal ;
}


//--------------------------------------------------------

char bm_fgetln (int file_id, char * str_buf) {    
    char retVal ;
    bm_printf("$pyshell fgetln(%c)\n",'0'+file_id); // avoiding %d for fast print (file id limited to 0-9
    retVal = bm_gets (str_buf); // returned line treated as string
    //uart_getchar() ; // Always need to take pyshell response even if not used    
    return retVal ;
}

//-------------------------------------------------------

unsigned int bm_fget_hex_val(int filePtr) { // Get from from hex file next unsigned char value 

   char str_buf[10] ;
   char retVal = bm_fgets (filePtr,str_buf) ; 
   return hex_str_to_uint(str_buf) ;
}

//-------------------------------------------------------

signed int bm_fget_dec_val(int filePtr) { // Get from file next string token and  interpenetrate it as signed decimal value 

   char str_buf[10] ;
   char retVal = bm_fgets (filePtr,str_buf) ;
   return dec_str_to_int(str_buf) ;  
}

//--------------------------------------------------------

void bm_dump_hex_file (int file_id, char * buf, int num_bytes) {    

  char *p ;
  int n=0;
  char ms_hex_val, ls_hex_val ;
  char ms_hex_char, ls_hex_char ;
  
   bm_access_file(file_id) ;  
   
   p=buf;
   while (n<num_bytes) { 
    ms_hex_val = (*p)/16  ;
    ms_hex_char = ms_hex_val < 10 ? '0'+ms_hex_val : 'a'+(ms_hex_val-10) ;
	uart_sendchar(ms_hex_char);    

    ls_hex_val = (*p)%16   ; 
    ls_hex_char = ls_hex_val < 10 ? '0'+ls_hex_val : 'a'+(ls_hex_val-10) ;
	uart_sendchar(ls_hex_char);    

	uart_sendchar('\n'); 
    
	n++;
	p++;
  }
  
  bm_access_file(-1) ;   // return to default stdio  

}

//--------------------------------------------------------

// Blocking hex file load,SW fully busy while loading data


int bm_load_hex_file (int file_id, int num_bytes , unsigned char * buf) {    

    int byte_cnt = 0 ;
    char hex_str[3] ;
    char val ; 
    
    //bm_printf("Starting load hex values\n");  

    bm_printf("$pyshell fgetHexF(%d,%d)\n",file_id, num_bytes);	

    while (((char)(hex_str[0]=uart_getchar())!=((char)0xFF))&&(byte_cnt<num_bytes)) {   

      hex_str[1]=uart_getchar() ;
      hex_str[2]=0 ;  
     
      val = hex_str_to_uint (hex_str) ;
      buf[byte_cnt++] = val ;
    }
    //bm_printf("Load Completed , %d bytes loaded\n",byte_cnt); 
      
    return byte_cnt  ;
 
}

//--------------------------------------------------------

// Non-blocking hex file load,
// SW issue load, and check completion by polling using bm_check_soc_load_hex_file function

void bm_start_soc_load_hex_file (int file_id, int num_bytes , unsigned char * buf) {    

    #ifdef FPGA_EMUL
    bm_printf("$pyshell socStartFgetHexF(%d,%d,0x%x)\n",file_id, num_bytes, buf);	// For pyshell
    #else    
    bm_printf("$pyshell socStartFgetHexF(%d,%d,%x)\n",file_id, num_bytes, buf);		// For verilog TB
    #endif
	
}

//-------------------------------------------------------------------------------------

// Check if non-blocking hex file load started by bm_start_soc_load_hex_file is done

#define NUM_BYTES_MAX_HEX_DIGITS 8

int bm_check_soc_load_hex_file () { 

    int byte_cnt = 0 ;
    char hex_str[NUM_BYTES_MAX_HEX_DIGITS+1] ;  // To capture num byte count.
    int hex_str_idx = 0 ;
      
    bm_printf("$pyshell socCheckFgetHexF()\n");	
	
    // completion indication and Number of actual loaded files (if completed is returned over uart)
    while (((char)(hex_str[hex_str_idx]=uart_getchar())!=(char)0xFF)) {
        hex_str_idx++ ;
    }
    if (hex_str_idx==0) return 0 ; // Load not Completed
    else {          
      hex_str[hex_str_idx]=0 ; // terminate string         
      byte_cnt = hex_str_to_uint (hex_str) ;          
      return byte_cnt  ;
    }
}


//--------------------------------------------------------

// Switched to XBOX Memories Mode to odd-even-line 
void bm_set_xmem_oel_mode() {
   bm_printf("$pyshell setXmemMoel\n"); // Mainly to inform TB for correct pseudo load/store
   
   // Switch XBOX HW to XBOX Memories Mode to odd-even-line
   // TODO: REGS addresses to be moved to some common file.
   unsigned char * XBOX_APB_BASE_ADDR = (unsigned char * )0x1A400000 ;  // APB MAPPED accelerator address space.
   int xbox_cmn_reg_base_idx = 32 ;   
   unsigned char * XBOX_MODE_REG_ADDR = XBOX_APB_BASE_ADDR+(xbox_cmn_reg_base_idx*4) ;
   *((volatile unsigned int *)XBOX_MODE_REG_ADDR) = 1 ;
}

//--------------------------------------------------------


// Non-blocking hex file store,
// SW issue store, and check completion by polling using bm_check_soc_store_hex_file function

void bm_start_soc_store_hex_file (int file_id, int num_bytes , int num_bytes_per_output_line, unsigned char * buf) {    

    #ifdef FPGA_EMUL
    bm_printf("$pyshell socStartFputHexF(%d,%d,%d,0x%x)\n",file_id, num_bytes, num_bytes_per_output_line, buf);	// For pyshell
    #else    
    bm_printf("$pyshell socStartFputHexF(%d,%d,%d,%x)\n",file_id, num_bytes, num_bytes_per_output_line, buf);	// For verilog TB
    #endif
	
}

//-------------------------------------------------------------------------------------

// Check if non-blocking hex file store started by bm_start_soc_store_hex_file is done

#define NUM_BYTES_MAX_HEX_DIGITS 8

int bm_check_soc_store_hex_file () { 

    int byte_cnt = 0 ;
    char hex_str[NUM_BYTES_MAX_HEX_DIGITS+1] ;  // To capture num byte count.
    int hex_str_idx = 0 ;
      
    bm_printf("$pyshell socCheckFputHexF()\n");	
	
    // completion indication and Number of actual stored files (if completed is returned over uart)
    while (((char)(hex_str[hex_str_idx]=uart_getchar())!=(char)0xFF)) hex_str_idx++ ;

    if (hex_str_idx==0) return 0 ; // store not Completed
    else {          
      hex_str[hex_str_idx]=0 ; // terminate string    
      byte_cnt = hex_str_to_uint (hex_str) ;          
      return byte_cnt  ;
    }
}

//----------------------------------------------------------------------------

void bm_dump_ascii_file (int file_id, char * buf, int num_chars) {    

  char *p ;
  int n=0;
   
   bm_access_file(file_id) ;  
   
   p=buf;
   while (n<num_chars) { 
	if ((*p)!=0xFF) uart_sendchar(*p);  // Do not dump the EOF , Verilog close file takes care of it
	n++;
	p++;
  }
   
  bm_access_file(-1) ;   // return to default stdio  
  
}

//--------------------------------------------------------


int bm_load_ascii_file(unsigned int file_id, char *src_text, int num_chars) {
    
  // Notice that calling this function multiple times currently works only at line granularity.

  char str[200] ;
  int src_text_idx = 0 ;
  int str_char_idx = 0;
  int line_cnt=0 ;
  boolean done=FALSE ;
  boolean is_eof=FALSE ;
  
  bm_printf("Starting load source text file\n");  

  while (!done) {
       is_eof = !bm_fgetln(file_id , str) ; 
     
       str_char_idx = 0;       
       while ((str[str_char_idx]!=0)&&(src_text_idx<num_chars))  {
           src_text[src_text_idx++] = str[str_char_idx++] ;            
       }           
       done = is_eof || (src_text_idx==num_chars) ; 
       line_cnt++ ;  
  }


  bm_printf("Loaded total %d characters from %d lines of source text\n",src_text_idx,line_cnt);  
  return src_text_idx ;
    
}    

//-------------------------------------------------------------------------------------

int bm_memcmp (unsigned char * mem_ptr1, unsigned char * mem_ptr2, int count) {
  while ((count--) > 0) {
      if (*mem_ptr1++ != *mem_ptr2++) {
        return mem_ptr1[-1] < mem_ptr2[-1] ? -1 : 1;
      }
  }
  return 0;
}

//----------------------------------------------------------------------------------------

int bm_strcmp (char *s1, char *s2) {
  unsigned char c1, c2;
  do {
      c1 = (unsigned char) *s1++;
      c2 = (unsigned char) *s2++;
  } while ((c1==c2) && (c1!=0) && (c2!=0)) ;
  return (c1==c2);
}

//----------------------------------------------------------------------------------------

int bm_strlen (const char *str)
{
  char *s = (char *)str;
  int len = 0;

  if (s == NULL)
    return 0;

  while (*s++ != '\0')
    ++len;
  return len;
}

//-----------------------------------------------------------------------------------------

void bm_sprintf(char *buf, const char *fmt, ...) {

    va_list args;
    va_start(args, fmt);
    ee_vsprintf(buf, fmt, args);
    va_end(args);
    
    ee_vsprintf(buf, fmt, args);
}

//----------------------------------------------------------------------------------------

void * bm_memset (void *dest, char val, int len) {
  unsigned char *ptr = dest;
  while (len-- > 0) *ptr++ = val;
  return dest;
}

//---------------------------------------------------------------------------------------

// General Purpose System call

void bm_sys_call (char * sys_call_str) {    

    bm_printf("$pyshell sysCall(\"%s\")\n",sys_call_str);	
}

//--------------------------------------------------------

char bm_quit_app() {   
  bm_printf("$pyshell quitApp()\n") ;
  return (char)(uart_getchar()) ; // get the file Index
}

//--------------------------------------------------------



